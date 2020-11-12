# afirth's dotfiles

Modified from geerlinguy. This stuff is just here for me to set up my boxes. If you find it useful, fork away.

## quickstart

# Ubuntu 18.x
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

## Description

My configuration. OSX centric

[edit 2019 - not anymore! I've joined #linuxmasterrace on most of my boxes]

## License

MIT / BSD
