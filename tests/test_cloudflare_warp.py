"""Test WARP installation with real Make, Bash, GPG and filesystem operations."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

FAKE_TOOL = r'''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
logpath = pathlib.Path(os.environ['TEST_LOG'])
with logpath.open('a') as log:
    log.write(json.dumps([name] + args) + '\n')
if name == 'sudo':
    os.execvp(args[0], args)
elif name == 'uname':
    print(os.environ.get('TEST_OS', 'Linux'))
elif name == 'dpkg':
    assert args == ['--print-architecture'], args
    print(os.environ.get('TEST_ARCH', 'amd64'))
elif name == 'dpkg-query':
    assert args == ['-W', '-f=${Status}\\n', 'cloudflare-warp'], args
    if pathlib.Path(os.environ['TEST_INSTALLED']).exists():
        print('install ok installed')
    else:
        sys.exit(1)
elif name == 'add-apt-repository':
    assert args == ['--yes', 'ppa:apt-fast/stable'], args
elif name == 'apt-get':
    assert args in (['update'], ['install', '-y', 'software-properties-common'],
                    ['install', '-y', 'apt-fast']), args
    if args == ['install', '-y', 'apt-fast']:
        dest = pathlib.Path(sys.argv[0]).with_name('apt-fast')
        shutil.copyfile(sys.argv[0], dest)
        dest.chmod(0o755)
elif name == 'apt-fast':
    calls = [json.loads(line) for line in logpath.read_text().splitlines()]
    updates = sum(call == ['apt-fast', 'update'] for call in calls)
    if args == ['update'] and updates == int(os.environ.get('FAIL_UPDATE', '0')):
        sys.exit(100)
    if args == ['install', '-y', 'cloudflare-warp']:
        if os.environ.get('FAIL_INSTALL'):
            sys.exit(100)
        pathlib.Path(os.environ['TEST_INSTALLED']).touch()
    else:
        assert args in (['update'], ['install', '-y', 'ca-certificates', 'curl', 'gnupg']), args
elif name == 'curl':
    assert args[:2] == ['-fsSL', 'https://pkg.cloudflareclient.com/pubkey.gpg'], args
    dest = pathlib.Path(args[args.index('-o') + 1])
    if os.environ.get('FAIL_DOWNLOAD'):
        dest.write_bytes(b'partial response')
        sys.exit(22)
    shutil.copyfile(os.environ['TEST_KEY'], dest)
elif name in ('install', 'gpg'):
    os.execv(os.environ['TEST_REAL_' + name.upper()], [name] + args)
else:
    sys.exit('unexpected external command: ' + name)
'''


class CloudflareWarpTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.log = self.base / 'commands.log'
        self.log.touch()
        self.installed = self.base / 'installed'
        self.os_release = self.base / 'os-release'
        self.os_release.write_text('ID=ubuntu\nVERSION_CODENAME=jammy\n')
        self.keyring = self.base / 'keyrings/cloudflare-warp.gpg'
        self.repo = self.base / 'sources/cloudflare-client.list'
        self.gpg_home = self.base / 'gnupg'
        self.gpg_home.mkdir(mode=0o700)
        self.stage = self.base / 'tmp'
        self.stage.mkdir()
        self.env = dict(os.environ, PATH=f'{self.bin}:{os.environ["PATH"]}',
                        TEST_LOG=str(self.log), TEST_INSTALLED=str(self.installed),
                        TEST_KEY=str(ROOT / 'tests/fixtures/warp-test-key.asc'),
                        TEST_REAL_GPG=shutil.which('gpg'),
                        TEST_REAL_INSTALL=shutil.which('install'),
                        GNUPGHOME=str(self.gpg_home), TMPDIR=str(self.stage))
        for tool in ('sudo', 'apt-get', 'apt-fast', 'add-apt-repository', 'dpkg', 'dpkg-query', 'uname', 'curl', 'gpg', 'install'):
            path = self.bin / tool
            path.write_text(FAKE_TOOL)
            path.chmod(0o755)

    def make(self, ok=True):
        result = subprocess.run(['make', '--no-print-directory', 'cloudflare-warp',
                                 f'warp-os-release={self.os_release}',
                                 f'warp-keyring={self.keyring}', f'warp-repo={self.repo}'],
                                cwd=ROOT, env=self.env, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(list(self.stage.iterdir()), [], 'temporary files leaked')
        return result

    def calls(self, tool):
        return [json.loads(line)[1:] for line in self.log.read_text().splitlines()
                if json.loads(line)[0] == tool]

    def test_jammy_installs_signed_repository_and_package(self):
        result = self.make()
        self.assertEqual(self.repo.read_text(),
                         f'deb [arch=amd64 signed-by={self.keyring}] '
                         'https://pkg.cloudflareclient.com/ jammy main\n')
        subprocess.run([self.env['TEST_REAL_GPG'], '--batch', '--show-keys', str(self.keyring)],
                       env=self.env, check=True, capture_output=True)
        self.assertEqual(self.keyring.stat().st_mode & 0o777, 0o644)
        self.assertEqual(self.repo.stat().st_mode & 0o777, 0o644)
        self.assertEqual(self.calls('apt-fast'), [
            ['update'], ['install', '-y', 'ca-certificates', 'curl', 'gnupg'],
            ['update'], ['install', '-y', 'cloudflare-warp']])
        self.assertTrue(self.installed.exists())
        self.assertIn('warp-cli registration new', result.stdout)
        self.assertIn('warp-cli connect', result.stdout)
        # warp-cli/systemctl are never invoked: a tunnel is not connected by Make.
        self.assertFalse(any('warp-cli' in arg for args in self.calls('sudo') for arg in args))

    def test_repeat_installation_leaves_repository_and_network_untouched(self):
        self.make()
        before = (self.repo.read_bytes(), self.keyring.read_bytes())
        self.log.write_text('')
        self.make()
        self.assertEqual(self.calls('sudo'), [])
        self.assertEqual(self.calls('curl'), [])
        self.assertEqual(before, (self.repo.read_bytes(), self.keyring.read_bytes()))

    def test_missing_apt_fast_is_bootstrapped_before_installing_warp(self):
        (self.bin / 'apt-fast').unlink()
        self.make()
        self.assertEqual(self.calls('apt-get'), [
            ['update'], ['install', '-y', 'software-properties-common'],
            ['update'], ['install', '-y', 'apt-fast']])
        self.assertEqual(self.calls('add-apt-repository'), [['--yes', 'ppa:apt-fast/stable']])
        self.assertIn(['install', '-y', 'cloudflare-warp'], self.calls('apt-fast'))
        self.assertTrue(self.installed.exists())

    def test_arm64_uses_native_architecture(self):
        self.env['TEST_ARCH'] = 'arm64'
        self.make()
        self.assertIn('arch=arm64', self.repo.read_text())

    def test_debian_uses_its_own_codename(self):
        self.os_release.write_text('ID=debian\nVERSION_CODENAME=bookworm\n')
        self.make()
        self.assertIn(' bookworm main', self.repo.read_text())

    def test_unsupported_platforms_fail_before_privileged_changes(self):
        for system, distro, arch in (('Darwin', 'ubuntu', 'amd64'),
                                    ('Linux', 'fedora', 'amd64'),
                                    ('Linux', 'ubuntu', 'i386')):
            with self.subTest(system=system, distro=distro, arch=arch):
                self.log.write_text('')
                self.env.update(TEST_OS=system, TEST_ARCH=arch)
                self.os_release.write_text(f'ID={distro}\nVERSION_CODENAME=jammy\n')
                self.make(ok=False)
                self.assertEqual(self.calls('sudo'), [])

    def test_missing_or_invalid_codename_fails_before_privileged_changes(self):
        for codename in ('', 'jammy extra', 'jammy/other'):
            with self.subTest(codename=codename):
                self.os_release.write_text(f'ID=ubuntu\nVERSION_CODENAME="{codename}"\n')
                self.make(ok=False)
                self.assertEqual(self.calls('sudo'), [])

    def test_failed_key_download_preserves_existing_configuration(self):
        self.keyring.parent.mkdir()
        self.repo.parent.mkdir()
        self.keyring.write_bytes(b'previous keyring')
        self.repo.write_bytes(b'previous source')
        self.env['FAIL_DOWNLOAD'] = '1'
        self.make(ok=False)
        self.assertEqual(self.keyring.read_bytes(), b'previous keyring')
        self.assertEqual(self.repo.read_bytes(), b'previous source')
        self.assertFalse(self.installed.exists())
        self.assertEqual(self.calls('gpg'), [])

    def test_invalid_key_does_not_write_repository_configuration(self):
        bad_key = self.base / 'invalid-key'
        bad_key.write_text('not a PGP key')
        self.env['TEST_KEY'] = str(bad_key)
        self.make(ok=False)
        self.assertFalse(self.repo.exists())
        self.assertFalse(self.keyring.exists())
        self.assertFalse(self.installed.exists())

    def test_package_index_failures_stop_installation(self):
        for update in ('1', '2'):
            with self.subTest(update=update):
                self.log.write_text('')
                self.env['FAIL_UPDATE'] = update
                self.make(ok=False)
                self.assertNotIn(['install', '-y', 'cloudflare-warp'], self.calls('apt-fast'))
                self.assertFalse(self.installed.exists())

    def test_failed_package_installation_can_be_retried(self):
        self.env['FAIL_INSTALL'] = '1'
        self.make(ok=False)
        self.assertFalse(self.installed.exists())
        del self.env['FAIL_INSTALL']
        self.make()
        self.assertTrue(self.installed.exists())
        self.assertEqual(self.repo.read_text().count('deb ['), 1)


if __name__ == '__main__':
    unittest.main()
