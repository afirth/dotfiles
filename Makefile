.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
SHELL = /bin/bash
.SUFFIXES:

dotfiles = .ackrc \
           .bash_profile \
           .gitconfig \
           .oh-my-zsh/custom/themes/afirth.zsh-theme \
           .tmux.conf \
           .vimrc \
           .zshrc
links := $(patsubst %,$(HOME)/%,$(dotfiles))

apt := /usr/bin/apt-fast
asdf := ~/.asdf
aws := /usr/local/bin/aws
curl := /usr/bin/curl
docker := /usr/bin/docker
git-creds := /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
golang := /usr/local/bin/go
gnome-tweaks := /usr/bin/gnome-tweaks
hub := /snap/bin/hub
krew := $(HOME)/.krew/bin/kubectl-krew
kustomize := $(HOME)/.local/bin/kustomize
kubectl := $(HOME)/.local/bin/kubectl
kubectl_version = v1.15.12
oh-my-zsh := $(HOME)/.oh-my-zsh/oh-my-zsh.sh
tmux := /usr/bin/tmux
vim := /usr/bin/vim
xinitrc := $(HOME)/.xinitrc
zsh := /usr/bin/zsh
zsh-auto := $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

.PHONY: all
all: $(oh-my-zsh) $(zsh-auto) $(links) $(hub) $(golang) $(git-creds) $(vim) $(tmux) $(curl) $(docker) $(apt) $(asdf) $(aws) $(gnome-tweaks) gnome-desktop capslock

.PHONY: run-once
run-once: apt-utils gcloud chrome zoom kustomize sops

## Not idempotent targets
.PHONY: apt-utils
apt-utils:
	apt-fast install -y tree ack jq p7zip pavucontrol xclip

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
	sudo apt install ~/Downloads/zoom.deb

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
	gsettings set org.gnome.desktop.input-sources xkb-options "['lv3:ralt_switch_multikey', 'eurosign:5', 'caps:escape_shifted_capslock']"

.PHONY: gnome-tweaks
gnome-tweaks: $(gnome-tweaks)
$(gnome-tweaks): $(apt)
	$(apt) -y install gnome-tweak-tool

#https://asdf-vm.com/#/core-manage-asdf-vm
.PHONY: asdf
asdf: $(asdf)
$(asdf): $(apt)
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0-rc1

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

.PHONY: krew
krew: $(krew)
$(krew): $(curl)
	( set -x; cd "$$(mktemp -d)" && \
	curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}" && \
	tar zxvf krew.tar.gz && \
	KREW=./krew-"$$(uname | tr '[:upper:]' '[:lower:]')_amd64" && \
	"$$KREW" install --manifest=krew.yaml --archive=krew.tar.gz && \
	"$$KREW" update \
	)


#not installed by default, may come with provider CLI

.PHONY: kubectl
kubectl: $(kubectl)
$(kubectl): $(curl)
	curl -L https://storage.googleapis.com/kubernetes-release/release/$(kubectl_version)/bin/linux/amd64/kubectl -o /tmp/kubectl
	mv /tmp/kubectl $(kubectl)
	chmod +x $(kubectl)

.PHONY: kustomize
kustomize: $(kustomize)
$(kustomize): $(curl)
	mkdir -p $(dir $(kustomize))
	(cd $(dir $(kustomize)) \
		&& curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" \
		| bash )


$(docker):
	$(apt) install -y docker.io
	sudo usermod -aG docker $(USER)
	sudo systemctl enable --now docker

$(hub):
	sudo snap install hub --classic

## GOLANG
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
