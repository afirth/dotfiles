#!/usr/bin/env bash

# TODO this should probably be a makefile instead. one day

# @afirth 2019
# sets up my ubuntu 18 terminal, more or less

GO_VERSION=1.12.5

set -eux -o pipefail

# install go
test -d /usr/local/go || install_golang

# install zsh and oh-my-zsh
set +x
which zsh || sudo apt-get update && sudo apt-get -y install zsh
test -f $HOME/.oh-my-zsh/oh-my-zsh.sh || instal_oh_my_zsh
set -x
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions


# setup git cred helper
sudo apt-get install -y libsecret-1-0 libsecret-1-dev
sudo make -C /usr/share/doc/git/contrib/credential/libsecret
# it's already in .gitconfig

# install vim-gtk3
# it's already aliased to vi in zshrc
which vim || sudo apt-get -y install vim-gtk3

#link selected files from this repo for ubuntu
FILES=".bash_profile
.gitconfig
.oh-my-zsh/custom
.vimrc
.zshrc"

set +e
for f in $FILES
do
	ln -fsr $PWD/$f $HOME/$f
done
set -e

chsh -s /usr/bin/zsh

set +x
echo Log out and log back in for chsh to take effect

install_oh_my_zsh () {
  curl -Lo install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
  sh install.sh --unattended
  rm install.sh
}

install_golang () {
  curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | sudo tar -C /usr/local -xz
  sudo ln -fs /usr/local/go/bin/go /usr/local/bin
}
