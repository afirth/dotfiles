# afirth's dotfiles

Modified from geerlinguy. This stuff is just here for me to set up my boxes. If you find it useful, fork away.

## quickstart

# Ubuntu 22.04
```
sudo apt-get update
sudo apt-get install -y git make
mkdir ~/git
cd ~/git && git clone https://github.com/afirth/dotfiles
cd dotfiles
make
```

# OSX
```
cd mac-dev-playbook && ansible-playbook main.yml -i inventory -K --tags "dotfiles"
```

## Makefile development

Package recipes use `sudo apt-fast` by default. If apt-fast is missing, the
helper installs it from `ppa:apt-fast/stable` using APT, then forwards the package
operation to apt-fast. Override `apt` to use another privileged package manager,
for example `make apt="sudo apt-get"`.
Installations run serially even with `make -j`, because APT and asdf share mutable
state. After installing Zsh, change your login shell explicitly with
`chsh -s /usr/bin/zsh` if desired.

Run the Makefile regression checks without installing packages or changing your
home directory:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

These checks execute Make and Bash with stubbed package managers, network clients
and desktop commands. They cover dependency ordering, repeat runs and failures;
a full desktop installation still needs validation on Ubuntu 22.04.

## Description

My configuration. OSX centric

[edit 2019 - not anymore! I've joined #linuxmasterrace on most of my boxes]

## License

MIT / BSD

## Cloudflare WARP

Install the Linux client separately from the default desktop setup:

```sh
make cloudflare-warp
```

This opt-in target uses Cloudflare's [official APT repository](https://pkg.cloudflareclient.com/)
for the machine's Ubuntu or Debian codename and amd64/arm64 architecture. Ubuntu
22.04 uses `jammy`. The release must be available in Cloudflare's repository.
The target installs the repository signing key with a scoped `signed-by` keyring,
then installs `cloudflare-warp`. An installed package is left unchanged on repeat
runs; use apt-fast to upgrade it. Package operations use `sudo apt-fast`; the
helper installs apt-fast from its Ubuntu PPA through APT if it is missing.
On Debian, install apt-fast before running this target.

Registration and connection are explicit steps, following Cloudflare's
[Linux client instructions](https://developers.cloudflare.com/warp-client/get-started/linux/):

```sh
warp-cli registration new
warp-cli connect
warp-cli status
curl https://www.cloudflare.com/cdn-cgi/trace  # expect warp=on
```

The Make target does not register an account, accept terms on your behalf, or
connect the tunnel. Use `warp-cli disconnect` to disconnect.

Run the installation orchestration tests without root, network access, or a
running WARP service (requires Python 3, GNU Make, Bash and GnuPG):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```
