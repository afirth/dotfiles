.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
SHELL = /bin/bash
.SUFFIXES:

dotfiles = .ackrc \
           .bash_profile \
           .config/autostart/inputplug.desktop \
           .local/bin/on-new-kbd.sh \
           .vim/scripts/partial_accept.vim \
           .gitconfig \
           .gitignore \
           .oh-my-zsh/custom/themes/afirth.zsh-theme \
           .tmux.conf \
           .vimrc \
           .zshrc
links := $(patsubst %,$(HOME)/%,$(dotfiles))

apt := /usr/bin/apt-fast
asdf := ~/.asdf
aws := /usr/local/bin/aws
cmake := /usr/bin/cmake
copyq := /usr/bin/copyq
curl := /usr/bin/curl
docker := /usr/bin/docker
eksctl := $(HOME)/.local/bin/eksctl
gh := /usr/bin/gh
gh-apt-repo := /etc/apt/sources.list.d/github-cli.list
git-creds := /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
gnome-tweaks := /usr/bin/gnome-tweaks
golang := /usr/local/bin/go
krew := $(HOME)/.asdf/shims/kubectl-krew
krew_version = 0.4.3
kubectl := $(HOME)/.asdf/shims/kubectl
kubectl_version = 1.21.14
kustomize := $(HOME)/.asdf/shims/kustomize
kustomize_version = v1.21.14
nodejs := $(HOME)/.asdf/shims/nodejs
nodejs_version := 17.9.1
nvim := /usr/bin/vim #TODO
oh-my-zsh := $(HOME)/.oh-my-zsh/oh-my-zsh.sh
tmux := /usr/bin/tmux
solarized := $(HOME)/.themes/NumixSolarizedDarkBlue
skaffold_version = 1.39.3
skaffold := $(HOME)/.asdf/shims/skaffold
python := $(HOME)/.asdf/shims/python
vim := /usr/bin/vim
xinitrc := $(HOME)/.xinitrc
zsh := /usr/bin/zsh
zsh-auto := $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

.PHONY: all
all: $(oh-my-zsh) $(zsh-auto) $(links) $(cmake) $(solarized) $(gh) $(golang) $(git-creds) $(vim) $(tmux) $(curl) $(docker) $(apt) $(asdf) $(aws) $(gnome-tweaks) $(copyq) gnome-desktop capslock $(python) $(nodejs) $(kubectl) $(kustomize) $(skaffold)

.PHONY: run-once
run-once: apt-utils gcloud chrome zoom kustomize sops gnome-extensions

## Not idempotent targets
.PHONY: apt-utils
apt-utils:
	apt-fast install -y tree ack jq p7zip pavucontrol xclip

.PHONY: gnome-extensions
gnome-extensions: gtile hidetopbar

.PHONY: gcloud
gcloud: $(curl)
	sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y'
	$(warning run gcloud init)

.PHONY: chrome
chrome:
	wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/Downloads/chrome.deb
	sudo apt install ~/Downloads/chrome.deb

.PHONY: zoom
zoom:
	wget https://zoom.us/client/latest/zoom_amd64.deb -O ~/Downloads/zoom.deb
	sudo apt install ~/Downloads/zoom.deb --yes

.PHONY: sops
SOPS_URL=$(shell curl -s "https://api.github.com/repos/mozilla/sops/releases/latest" | grep -o "http.*sops_.*_amd64\.deb")
sops: $(curl)
	wget $(SOPS_URL) -O ~/Downloads/sops.deb
	sudo apt install ~/Downloads/sops.deb

## Idempotent targets

# so you can use the keyboard
# set with `dconf watch /` and then gnome-tweaks for whatever settings you like, then `gsettings list-recursively| grep xkb`
.PHONY: capslock
capslock:
	$(apt) -y install inputplug
	inputplug -d -c ~/.local/bin/on-new-kbd.sh &

.PHONY: cmake
cmake: $(cmake)
$(cmake): $(apt)
	$(apt) -y install cmake

.PHONY: gnome-tweaks
gnome-tweaks: $(gnome-tweaks)
$(gnome-tweaks): $(apt)
	$(apt) -y install gnome-tweaks

# github cli
.PHONY: gh
gh: $(gh)
$(gh): $(apt) $(gh-apt-repo)
	$(apt) -y install gh
	mkdir -p $(HOME)/.oh-my-zsh/completions/
	gh completion -s zsh > $(HOME)/.oh-my-zsh/completions/_gh

$(gh-apt-repo):
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(shell dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	$(apt) update

.PHONY: copyq
copyq: $(copyq)
$(copyq): $(apt)
	$(apt) -y install copyq copyq-plugins copyq-doc

#https://asdf-vm.com/#/core-manage-asdf-vm
.PHONY: asdf
asdf: $(asdf)
$(asdf): $(apt)
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

.PHONY: python
python: $(python)
$(python): $(asdf) $(apt)
	afiy libssl-dev
	-asdf plugin-add python
	asdf install python latest
	asdf global python latest

#https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install
.PHONY: aws
aws: $(aws)
$(aws): $(curl)
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
	unzip /tmp/awscliv2.zip -d /tmp/
	sudo /tmp/aws/install

.PHONY: gnome-desktop
gnome-desktop:
	gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
	gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
	gsettings set org.gnome.desktop.background show-desktop-icons false

.PHONY: nodejs
nodejs: $(nodejs)
$(nodejs): $(asdf)
	-asdf plugin-add nodejs
	asdf install nodejs $(nodejs_version)
	asdf global nodejs $(nodejs_version)

.PHONY: kubectl
kubectl: $(kubectl)
$(kubectl): $(asdf)
	-asdf plugin-add kubectl
	asdf install kubectl $(kubectl_version)
	asdf global kubectl $(kubectl_version)

# it l
.PHONY: krew
krew: $(krew)
$(krew): $(asdf)
	-asdf plugin-add krew
	asdf install krew $(krew_version)
	asdf global krew $(krew_version)

.PHONY: kustomize
kustomize: $(kustomize)
$(kustomize): $(asdf)
	-asdf plugin-add kustomize
	asdf install kustomize $(kustomize_version)
	asdf global kustomize $(kustomize_version)

.PHONY: skaffold
skaffold: $(skaffold)
$(skaffold): $(asdf)
	-asdf plugin-add skaffold
	asdf install skaffold $(skaffold_version)
	asdf global skaffold $(skaffold_version)

.PHONY: eksctl
UNAMES=$(shell uname -s)
eksctl: $(eksctl)
$(eksctl): $(curl)
	UNAME="$$(uname -s)" && \
	curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(UNAMES)_amd64.tar.gz" | tar xz -C ~/.local/bin/
	mkdir -p ~/.zsh/completion/
	eksctl completion zsh > ~/.zsh/completion/_eksctl

$(docker):
	$(apt) install -y docker.io
	sudo usermod -aG docker $(USER)
	sudo systemctl enable --now docker

## GOLANG
## mostly use asdf go shim now
GO_VERSION := 1.14
$(golang): /usr/local/go
	sudo ln -fs /usr/local/go/bin/go /usr/local/bin

/usr/local/go: | $(curl)
	curl -fsSL https://dl.google.com/go/go$(GO_VERSION).linux-amd64.tar.gz | sudo tar -C /usr/local -xvz

# install vim-gtk3
# it's already aliased to vi in zshrc
$(vim):
	which vim || $(apt) -y install vim-gtk3

$(tmux):
	which tmux || $(apt) -y install tmux
	git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm
	@echo you may want to install tmux>=3.3 with asdf. requires bison, ncurses-dev, and flex

## dotfile links
# depends on zsh because otherwise zsh install breaks
.PHONY: dotfiles
dotfiles: $(links) | $(zsh)

$(links): $(HOME)/%: %
	@mkdir -p $(@D)
	ln -fsr $< $@

$(git-creds): | $(apt)
	$(apt) install -y libsecret-1-0 libsecret-1-dev build-essential
	sudo $(MAKE) -C /usr/share/doc/git/contrib/credential/libsecret

## ZSH
### oh-my-zsh
$(oh-my-zsh): | $(zsh) $(curl)
	curl -Lo /tmp/install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
	-sh /tmp/install.sh --unattended
	rm /tmp/install.sh
	# will be replaced by link
	rm $(HOME)/.zshrc

### zsh-auto-suggestions
$(zsh-auto): $(oh-my-zsh)
	git clone https://github.com/zsh-users/zsh-autosuggestions $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

### zsh itself
$(zsh): | $(apt)
	$(apt) install -y zsh
	chsh -s /usr/bin/zsh
	@echo Logout and back in to use zsh

## curl
$(curl): | $(apt)
	$(apt) install -y curl

## Apt-fast
$(apt):
	sudo add-apt-repository -y ppa:apt-fast/stable
	sudo apt-get update
	sudo apt-get -y install apt-fast

## numix solarized theme
$(solarized): | $(apt)
	mkdir -p $(@D) && \
	cd $(@D) && \
	wget -nc -O $(HOME)/Downloads/NumixSolarized-20210831.tar.gz --no-check-certificate https://github.com/Ferdi265/numix-solarized-gtk-theme/releases/download/20210831/NumixSolarized-20210831.tar.gz || echo already downloaded theme && \
	tar --strip-components=1 -xvzf $(HOME)/Downloads/NumixSolarized-20210831.tar.gz && \
	gsettings set org.gnome.desktop.interface gtk-theme $(@F)

hidetopbar:
	./install-gnome-extensions.sh --enable 545
	dconf load /org/gnome/shell/extensions/$@/ < ./$@.dconf

gtile:
	./install-gnome-extensions.sh --enable 28
	dconf load /org/gnome/shell/extensions/$@/ < ./$@.dconf
