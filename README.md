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
