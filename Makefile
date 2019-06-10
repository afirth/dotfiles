.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
SHELL = /bin/bash
.SUFFIXES:

.PHONY: all
all: $(golang) $(links) $(zsh)

dotfiles = .bash_profile \
        .gitconfig \
        .oh-my-zsh/custom/themes/afirth.zsh-theme \
        .vimrc \
        .zshrc
links := $(patsubst %,$(HOME)/%,$(dotfiles))

golang := /usr/local/bin/go
git-creds := /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
apt := /usr/sbin/apt-fast
zsh := /usr/bin/zsh
oh-my-zsh := $(HOME)/.oh-my-zsh/oh-my-zsh.sh
zsh-auto := $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

## GOLANG
GO_VERSION := 1.12.5
$(golang): /usr/local/go
	ln -fs /usr/local/go/bin/go /usr/local/bin

/usr/local/go:
	curl -fsSL https://dl.google.com/go/go$(GO_VERSION).linux-amd64.tar.gz | tar -C /usr/local -xvz


## dotfile links
# depends on zsh because otherwise zsh install breaks
.PHONY: dotfiles
dotfiles: $(links) $(zsh)

$(links): $(HOME)/%: %
	    ln -fsr $< $@

$(git-creds): $(apt-fast)
	apt-fast install -y libsecret-1-0 libsecret-1-dev
	$(MAKE) -C /usr/share/doc/git/contrib/credential/libsecret

## ZSH
### oh-my-zsh
$(oh-my-zsh): $(zsh-pkg)
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
	sh /tmp/install.sh --unattended
	rm /tmp/install.sh

### zsh-auto-suggestions
$(zsh-auto): $(oh-my-zsh)
	git clone https://github.com/zsh-users/zsh-autosuggestions $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

### zsh itself
	$(zsh): $(apt-fast)
	apt-fast install -y zsh
	chsh -s /usr/bin/zsh

## Apt-fast
$(apt):
	add-apt-repository -y ppa:apt-fast/stable
	apt-get update
	apt-get -y install apt-fast
