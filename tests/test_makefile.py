"""Exercise Make recipes without changing the host or installing packages."""
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

# Only external side effects are replaced. GNU Make, Bash, ln and tar are real.
FAKE_TOOL = r'''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
home = pathlib.Path(os.environ['TEST_HOME'])
with open(os.environ['TEST_LOG'], 'a') as log:
    log.write(json.dumps([name] + args) + '\n')
if name == 'sudo':
    os.execvp(args[0], args)
if name == 'apt-get':
    if 'install' in args:
        for package in args:
            if package in ('zsh', 'tmux', 'gh', 'pipx', 'neovim'):
                path = pathlib.Path(os.environ['TEST_BIN']) / ('nvim' if package == 'neovim' else package)
                path.write_text('#!/bin/sh\nexit 0\n')
                path.chmod(0o755)
elif name == 'git':
    assert args[0] == 'clone', args
    url, dest = args[1:3]
    dest = pathlib.Path(dest)
    if dest.exists() and any(dest.iterdir()):
        sys.exit('clone destination is not empty')
    dest.mkdir(parents=True, exist_ok=True)
    if 'ohmyzsh' in url:
        (dest / 'oh-my-zsh.sh').touch()
    elif 'asdf-vm' in url:
        shutil.copyfile(os.environ['TEST_ASDF'], dest / 'asdf.sh')
    elif 'tmux-plugins' in url:
        (dest / 'tpm').touch()
elif name == 'curl':
    if os.environ.get('FAIL_DOWNLOAD'):
        sys.exit(22)
    if '-o' in args:
        dest = pathlib.Path(args[args.index('-o') + 1])
        shutil.copyfile(os.environ['TEST_ARCHIVE'], dest)
    else:
        print('{}')
elif name == 'gsettings':
    if args[0] == 'list-keys':
        print('picture-uri')  # Ubuntu 22.04 has no show-desktop-icons key.
    if os.environ.get('FAIL_SETTINGS'):
        sys.exit(1)
elif name == 'gh':
    print('# completion')
'''

ASDF = r'''
asdf() {
    printf 'asdf %s\n' "$*" >> "$TEST_LOG"
    case "$1" in
        plugin)
            case "$2" in
                list) test ! -f "$HOME/.asdf/plugins-list" || cat "$HOME/.asdf/plugins-list" ;;
                add)
                    if [ "${FAIL_PLUGIN:-}" = "$3" ]; then return 23; fi
                    echo "$3" >> "$HOME/.asdf/plugins-list"
                    ;;
            esac ;;
        latest) echo 3.12.9 ;;
        install)
            mkdir -p "$HOME/.asdf/shims"
            shim="$2"
            case "$shim" in golang) shim=go ;; nodejs) shim=node ;; krew) shim=kubectl-krew ;; esac
            touch "$HOME/.asdf/shims/$shim"
            ;;
        global) : ;;
        *) return 1 ;;
    esac
}
'''


class MakefileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.home = self.base / 'home'
        self.bin = self.base / 'bin'
        self.home.mkdir()
        self.bin.mkdir()
        self.log = self.base / 'commands.log'
        self.log.touch()
        asdf = self.base / 'asdf.sh'
        asdf.write_text(ASDF)
        archive = self.base / 'theme.tar.gz'
        with tarfile.open(archive, 'w:gz') as out:
            data = b'theme fixture'
            member = tarfile.TarInfo('theme/gtk-3.0/gtk.css')
            member.size = len(data)
            out.addfile(member, io.BytesIO(data))
        self.archive = archive
        for tool in ('sudo', 'apt-get', 'git', 'curl', 'gsettings', 'gh'):
            path = self.bin / tool
            path.write_text(FAKE_TOOL)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}',
                        TEST_HOME=str(self.home), TEST_BIN=str(self.bin),
                        TEST_LOG=str(self.log), TEST_ASDF=str(asdf),
                        TEST_ARCHIVE=str(archive))

    def make(self, *targets, ok=True, **variables):
        args = ['make', '--no-print-directory', '-f', str(ROOT / 'Makefile'),
                f'HOME={self.home}', f'zsh={self.bin / "zsh"}',
                f'tmux={self.bin / "tmux"}', f'gh={self.bin / "gh"}']
        args += [f'{key}={value}' for key, value in variables.items()]
        result = subprocess.run(args + list(targets), cwd=ROOT, env=self.env,
                                text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def calls(self, tool):
        return [json.loads(line)[1:] for line in self.log.read_text().splitlines()
                if line.startswith('[') and json.loads(line)[0] == tool]

    def test_dotfiles_bootstrap_order_and_repeatability(self):
        self.make('-j8', 'dotfiles')
        links = [p for p in self.home.rglob('*') if p.is_symlink()]
        self.assertEqual(len(links), 11)
        for link in links:
            self.assertEqual(link.resolve(), ROOT / link.relative_to(self.home))
        before = self.log.read_text()
        self.make('-j8', 'dotfiles')
        self.assertEqual(before, self.log.read_text())
        self.assertEqual(self.calls('apt-get'), [['install', '-y', 'zsh']])
        self.assertEqual(len(self.calls('git')), 1)

    def test_oh_my_zsh_does_not_delete_existing_zshrc(self):
        rc = self.home / '.zshrc'
        rc.write_text('existing user configuration')
        self.make(str(self.home / '.oh-my-zsh/oh-my-zsh.sh'))
        self.assertEqual(rc.read_text(), 'existing user configuration')

    def test_asdf_tools_initialize_in_noninteractive_shell_and_use_real_shims(self):
        tools = ('golang', 'nodejs', 'python', 'kubectl', 'krew', 'kustomize', 'skaffold')
        self.make('-j8', *tools)
        for shim in ('go', 'node', 'python', 'kubectl', 'kubectl-krew', 'kustomize', 'skaffold'):
            self.assertTrue((self.home / '.asdf/shims' / shim).exists(), shim)
        log = self.log.read_text()
        self.assertEqual(log.count('asdf latest python'), 1)
        self.assertIn('asdf install python 3.12.9', log)
        self.assertIn('asdf global python 3.12.9', log)
        # Updating the initializer must not trigger reinstallation of every runtime.
        os.utime(self.home / '.asdf/asdf.sh', None)
        self.make(*tools)
        self.assertEqual(log, self.log.read_text())

    def test_asdf_plugin_failure_stops_installation(self):
        self.env['FAIL_PLUGIN'] = 'nodejs'
        self.make('nodejs', ok=False)
        self.assertNotIn('asdf install nodejs', self.log.read_text())
        self.assertFalse((self.home / '.asdf/shims/node').exists())

    def test_existing_plugin_is_not_added_again(self):
        self.make('asdf')
        (self.home / '.asdf/plugins-list').write_text('nodejs\n')
        self.make('nodejs')
        self.assertNotIn('asdf plugin add nodejs', self.log.read_text())

    def test_theme_extracts_into_target_and_skips_repeat_download(self):
        theme = self.home / '.themes/NumixSolarizedDarkBlue'
        self.make(str(theme))
        self.assertEqual((theme / 'gtk-3.0/gtk.css').read_text(), 'theme fixture')
        before = self.log.read_text()
        self.make(str(theme))
        self.assertEqual(before, self.log.read_text())
        args = self.calls('curl')[0]
        self.assertIn('-fL', args)
        self.assertNotIn('--no-check-certificate', args)

    def test_failed_theme_download_can_be_retried(self):
        theme = self.home / '.themes/NumixSolarizedDarkBlue'
        self.env['FAIL_DOWNLOAD'] = '1'
        self.make(str(theme), ok=False)
        self.assertFalse(theme.exists())
        self.assertEqual(self.calls('gsettings'), [])
        del self.env['FAIL_DOWNLOAD']
        self.make(str(theme))
        self.assertTrue((theme / 'gtk-3.0/gtk.css').exists())
        self.assertEqual(list(theme.parent.glob('.solarized.*')), [])

    def test_invalid_archive_does_not_mark_theme_installed(self):
        self.archive.write_bytes(b'not an archive')
        theme = self.home / '.themes/NumixSolarizedDarkBlue'
        self.make(str(theme), ok=False)
        self.assertFalse(theme.exists())
        self.assertEqual(self.calls('gsettings'), [])

    def test_failed_settings_do_not_mark_theme_installed(self):
        self.env['FAIL_SETTINGS'] = '1'
        theme = self.home / '.themes/NumixSolarizedDarkBlue'
        self.make(str(theme), ok=False)
        self.assertFalse(theme.exists())

    def test_tpm_installs_even_when_tmux_is_already_present(self):
        (self.bin / 'tmux').touch()
        tpm = self.home / '.tmux/plugins/tpm/tpm'
        self.make(str(tpm))
        self.make(str(tpm))
        self.assertTrue(tpm.exists())
        self.assertEqual(len(self.calls('git')), 1)
        self.assertEqual(self.calls('apt-get'), [])

    def test_gh_completion_with_existing_gh_does_not_change_apt_sources(self):
        self.make('gh')
        self.assertTrue((self.home / '.oh-my-zsh/completions/_gh').exists())
        # Only Zsh was absent; no GitHub repository or gh package was needed.
        self.assertEqual(self.calls('apt-get'), [['install', '-y', 'zsh']])

    def test_apt_utils_uses_privileged_package_manager(self):
        self.make('apt-utils')
        self.assertEqual(self.calls('sudo')[0][:3], ['apt-get', 'install', '-y'])
        self.assertIn('xclip', self.calls('apt-get')[0])

    def test_modern_gnome_without_legacy_key(self):
        self.make('gnome-desktop')
        self.assertEqual(len([a for a in self.calls('gsettings') if a[0] == 'set']), 3)
        self.assertFalse(any('show-desktop-icons' in a for a in self.calls('gsettings')))

    def test_download_failure_never_runs_package_install(self):
        self.env['FAIL_DOWNLOAD'] = '1'
        for target in ('chrome', 'zoom', 'aws', 'eksctl'):
            with self.subTest(target=target):
                self.log.write_text('')
                self.make(target, ok=False, aws=self.home / 'bin/aws')
                self.assertFalse(any(any(a.endswith('.deb') for a in args)
                                     for args in self.calls('apt-get')))
                self.assertFalse(any(any(a.endswith('/aws/install') for a in args)
                                     for args in self.calls('sudo')))


if __name__ == '__main__':
    unittest.main()
