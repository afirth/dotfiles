.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
SHELL = /bin/bash
.SUFFIXES:
# APT/dpkg and asdf global configuration cannot be updated concurrently.
.NOTPARALLEL:

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

apt ?= bash "$(CURDIR)/scripts/apt-fast.sh"
asdf := $(HOME)/.asdf
asdf-init := $(asdf)/asdf.sh
aws := /usr/local/bin/aws
awsume := $(HOME)/.local/bin/awsume
cmake := /usr/bin/cmake
copyq := /usr/bin/copyq
curl := /usr/bin/curl
docker := /usr/bin/docker
eksctl := $(HOME)/.local/bin/eksctl
gh := /usr/bin/gh
gcloud-key := /usr/share/keyrings/cloud.google.gpg
gcloud-repo := /etc/apt/sources.list.d/google-cloud-sdk.list
git-creds := /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
gnome-tweaks := /usr/bin/gnome-tweaks
golang_version = 1.20
golang := $(HOME)/.asdf/shims/go
krew := $(HOME)/.asdf/shims/kubectl-krew
krew_version = 0.4.3
kubectl := $(HOME)/.asdf/shims/kubectl
kubectl_version = 1.21.14
kustomize := $(HOME)/.asdf/shims/kustomize
kustomize_version = 4.5.7
nodejs := $(HOME)/.asdf/shims/node
nodejs_version := 17.9.1
nvim := /usr/bin/nvim
oh-my-zsh := $(HOME)/.oh-my-zsh/oh-my-zsh.sh
tmux := /usr/bin/tmux
tpm := $(HOME)/.tmux/plugins/tpm/tpm
solarized := $(HOME)/.themes/NumixSolarizedDarkBlue
solarized_url := https://github.com/Ferdi265/numix-solarized-gtk-theme/releases/download/20230408/NumixSolarized-20230408.tar.gz
skaffold_version = 1.39.3
skaffold := $(HOME)/.asdf/shims/skaffold
pipx := /usr/bin/pipx
python := $(HOME)/.asdf/shims/python
vim := /usr/bin/vim
zsh := /usr/bin/zsh
zsh-auto := $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

.PHONY: all
all: $(oh-my-zsh) $(zsh-auto) dotfiles $(cmake) $(solarized) gh $(golang) $(git-creds) $(vim) $(nvim) $(tmux) $(tpm) $(curl) $(docker) $(asdf-init) $(aws) $(awsume) $(gnome-tweaks) $(copyq) gnome-desktop $(python) $(nodejs) $(kubectl) $(kustomize) $(skaffold)

.PHONY: run-once
run-once: apt-utils chrome zoom gnome-extensions

## Not idempotent targets
.PHONY: apt-utils
apt-utils:
	$(apt) install -y tree ack jq p7zip pavucontrol xclip

.PHONY: gnome-extensions
gnome-extensions: gtile hidetopbar

.PHONY: gcloud
gcloud: | $(curl)
	$(apt) install -y ca-certificates gnupg
	key="$$(mktemp)"; \
	trap 'rm -f "$$key"' EXIT; \
	curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor > "$$key"; \
	sudo install -m 0644 "$$key" "$(gcloud-key)"
	echo 'deb [signed-by=$(gcloud-key)] https://packages.cloud.google.com/apt cloud-sdk main' | \
		sudo tee "$(gcloud-repo)" > /dev/null
	$(apt) update
	$(apt) install -y google-cloud-cli
	@echo 'Run gcloud init to authenticate.'

.PHONY: chrome
chrome: | $(curl)
	mkdir -p $(HOME)/Downloads
	curl -fL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o $(HOME)/Downloads/chrome.deb
	$(apt) install -y $(HOME)/Downloads/chrome.deb

.PHONY: zoom
zoom: | $(curl)
	mkdir -p $(HOME)/Downloads
	curl -fL https://zoom.us/client/latest/zoom_amd64.deb -o $(HOME)/Downloads/zoom.deb
	$(apt) install -y $(HOME)/Downloads/zoom.deb

.PHONY: sops
sops: | $(curl)
	$(apt) install -y jq
	mkdir -p $(HOME)/Downloads
	url="$$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | \
		jq -er --arg arch "$$(dpkg --print-architecture)" '.assets[] | select(.name | endswith("_" + $$arch + ".deb")) | .browser_download_url')"; \
	curl -fL "$$url" -o "$(HOME)/Downloads/sops.deb"
	$(apt) install -y $(HOME)/Downloads/sops.deb

## Idempotent targets

.PHONY: cmake
cmake: $(cmake)
$(cmake):
	$(apt) -y install cmake

.PHONY: gnome-tweaks
gnome-tweaks: $(gnome-tweaks)
$(gnome-tweaks):
	$(apt) -y install gnome-tweaks

# Ubuntu 22.04 provides gh; avoid changing APT repositories on an existing install.
.PHONY: gh
gh: $(gh) $(HOME)/.oh-my-zsh/completions/_gh
$(gh):
	$(apt) -y install gh

$(HOME)/.oh-my-zsh/completions/_gh: | $(gh) $(oh-my-zsh)
	mkdir -p "$(@D)"
	$(gh) completion -s zsh > "$@"

.PHONY: copyq
copyq: $(copyq)
$(copyq):
	$(apt) -y install copyq copyq-plugins copyq-doc

#https://asdf-vm.com/#/core-manage-asdf-vm
.PHONY: asdf
asdf: $(asdf-init)
$(asdf-init):
	git clone https://github.com/asdf-vm/asdf.git "$(asdf)" --branch v0.10.2

# Initialize the pinned asdf release in each noninteractive recipe shell.
# Do not hide plugin-install failures or resolve "latest" twice.
define install-asdf-tool
. "$(asdf-init)"; \
asdf plugin list | grep -Fxq '$(1)' || asdf plugin add '$(1)'; \
version='$(2)'; \
if [ "$$version" = latest ]; then version="$$(asdf latest '$(1)')"; fi; \
asdf install '$(1)' "$$version"; \
asdf global '$(1)' "$$version"
endef

.PHONY: python
python: $(python)
$(python): | $(asdf-init) $(curl)
	$(apt) install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libffi-dev liblzma-dev tk-dev
	$(call install-asdf-tool,python,latest)

#https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install
.PHONY: aws
aws: $(aws)
$(aws): | $(curl)
	$(apt) install -y unzip
	stage="$$(mktemp -d)"; \
	trap 'rm -rf "$$stage"' EXIT; \
	curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$$stage/awscliv2.zip"; \
	unzip -q "$$stage/awscliv2.zip" -d "$$stage"; \
	sudo "$$stage/aws/install"

.PHONY: awsume
awsume: $(awsume)
$(awsume): | $(pipx)
	$(pipx) install awsume

.PHONY: pipx
pipx: $(pipx)
$(pipx):
	$(apt) install -y pipx

.PHONY: gnome-desktop
gnome-desktop:
	gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
	gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
	gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
	if gsettings list-keys org.gnome.desktop.background | grep -Fxq show-desktop-icons; then \
		gsettings set org.gnome.desktop.background show-desktop-icons false; \
	fi

.PHONY: nodejs
nodejs: $(nodejs)
$(nodejs): | $(asdf-init) $(curl)
	$(call install-asdf-tool,nodejs,$(nodejs_version))

.PHONY: kubectl
kubectl: $(kubectl)
$(kubectl): | $(asdf-init) $(curl)
	$(call install-asdf-tool,kubectl,$(kubectl_version))

.PHONY: krew
krew: $(krew)
$(krew): | $(asdf-init) $(curl)
	$(call install-asdf-tool,krew,$(krew_version))

.PHONY: kustomize
kustomize: $(kustomize)
$(kustomize): | $(asdf-init) $(curl)
	$(call install-asdf-tool,kustomize,$(kustomize_version))

.PHONY: skaffold
skaffold: $(skaffold)
$(skaffold): | $(asdf-init) $(curl)
	$(call install-asdf-tool,skaffold,$(skaffold_version))

.PHONY: eksctl
UNAMES=$(shell uname -s)
eksctl: $(eksctl)
$(eksctl): | $(curl)
	mkdir -p $(HOME)/.local/bin/
	curl --fail --silent --show-error --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(UNAMES)_amd64.tar.gz" | tar xz -C "$(HOME)/.local/bin/"
	mkdir -p "$(HOME)/.zsh/completion/"
	"$(eksctl)" completion zsh > "$(HOME)/.zsh/completion/_eksctl"

.PHONY: docker
docker: $(docker)
$(docker):
	$(apt) install -y docker.io
	sudo usermod -aG docker $(USER)
	sudo systemctl enable --now docker

.PHONY: golang
golang: $(golang)
$(golang): | $(asdf-init) $(curl)
	$(call install-asdf-tool,golang,$(golang_version))

# install vim-gtk3
# Neovim is the editor used by the vi alias in .zshrc.
.PHONY: vim nvim tmux
vim: $(vim)
nvim: $(nvim)
tmux: $(tmux) $(tpm)
$(vim):
	which vim || $(apt) -y install vim-gtk3

$(nvim):
	$(apt) -y install neovim

$(tmux):
	$(apt) -y install tmux

$(tpm): | $(tmux)
	git clone https://github.com/tmux-plugins/tpm $(HOME)/.tmux/plugins/tpm
	@echo 'You may want tmux >= 3.3 via asdf; requires bison, ncurses-dev, and flex.'

## dotfile links
# depends on zsh because otherwise zsh install breaks
.PHONY: dotfiles
dotfiles: $(links)

$(links): $(HOME)/%: % | $(zsh)
	@mkdir -p $(@D)
	ln -fsr $< $@

# Clone oh-my-zsh before creating its custom-theme directory, including under -j.
$(HOME)/.oh-my-zsh/custom/themes/afirth.zsh-theme: | $(oh-my-zsh)

$(git-creds):
	$(apt) install -y libsecret-1-0 libsecret-1-dev build-essential
	sudo $(MAKE) -C /usr/share/doc/git/contrib/credential/libsecret

## ZSH
### oh-my-zsh
$(oh-my-zsh): | $(zsh)
	git clone https://github.com/ohmyzsh/ohmyzsh.git "$(HOME)/.oh-my-zsh"

### zsh-auto-suggestions
$(zsh-auto): | $(oh-my-zsh)
	git clone https://github.com/zsh-users/zsh-autosuggestions $(HOME)/.oh-my-zsh/custom/plugins/zsh-autosuggestions

### zsh itself
$(zsh):
	$(apt) install -y zsh
	@echo 'To change your login shell, run: chsh -s /usr/bin/zsh'

## curl
.PHONY: curl
curl: $(curl)
$(curl):
	$(apt) install -y curl

## numix solarized theme
$(solarized): | $(curl)
	@mkdir -p "$(@D)"
	stage="$$(mktemp -d "$(@D)/.solarized.XXXXXX")"; \
	trap 'rm -rf "$$stage"' EXIT; \
	curl -fL "$(solarized_url)" -o "$$stage/theme.tar.gz"; \
	mkdir "$$stage/theme"; \
	tar --strip-components=1 -xzf "$$stage/theme.tar.gz" -C "$$stage/theme"; \
	gsettings set org.gnome.desktop.interface gtk-theme "$(@F)"; \
	mv "$$stage/theme" "$@"

.PHONY: hidetopbar gtile
hidetopbar:
	./install-gnome-extensions.sh --enable 545
	dconf load /org/gnome/shell/extensions/$@/ < ./$@.dconf

gtile:
	./install-gnome-extensions.sh --enable 28
	dconf load /org/gnome/shell/extensions/$@/ < ./$@.dconf

## Cloudflare WARP (opt-in; registration and connection are separate)
warp-apt ?= bash "$(CURDIR)/scripts/apt-fast.sh"
warp-os-release := /etc/os-release
warp-keyring := /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
warp-repo := /etc/apt/sources.list.d/cloudflare-client.list

.PHONY: cloudflare-warp
cloudflare-warp:
	@test "$$(uname -s)" = Linux || { echo 'cloudflare-warp requires Linux.' >&2; exit 1; }; \
	. "$(warp-os-release)"; \
	case "$${ID:-}" in ubuntu|debian) ;; \
		*) echo 'cloudflare-warp requires Ubuntu or Debian.' >&2; exit 1 ;; esac; \
	codename="$${VERSION_CODENAME:-}"; \
	case "$$codename" in ''|*[!a-z0-9-]*) echo 'Missing or invalid distro codename.' >&2; exit 1 ;; esac; \
	arch="$$(dpkg --print-architecture)"; \
	case "$$arch" in amd64|arm64) ;; \
		*) echo "Unsupported WARP architecture: $$arch" >&2; exit 1 ;; esac; \
	if dpkg-query -W -f='$${Status}\n' cloudflare-warp 2>/dev/null | grep -Fxq 'install ok installed'; then \
		echo 'cloudflare-warp is already installed.'; exit 0; \
	fi; \
	$(warp-apt) update; \
	$(warp-apt) install -y ca-certificates curl gnupg; \
	stage="$$(mktemp -d)"; \
	trap 'rm -rf "$$stage"' EXIT; \
	curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg -o "$$stage/pubkey.gpg"; \
	gpg --batch --yes --dearmor --output "$$stage/keyring.gpg" "$$stage/pubkey.gpg"; \
	printf 'deb [arch=%s signed-by=%s] https://pkg.cloudflareclient.com/ %s main\n' \
		"$$arch" "$(warp-keyring)" "$$codename" > "$$stage/cloudflare-client.list"; \
	sudo install -d -m 0755 "$(dir $(warp-keyring))" "$(dir $(warp-repo))"; \
	sudo install -m 0644 "$$stage/keyring.gpg" "$(warp-keyring)"; \
	sudo install -m 0644 "$$stage/cloudflare-client.list" "$(warp-repo)"; \
	$(warp-apt) update; \
	$(warp-apt) install -y cloudflare-warp
	@echo 'When ready, register with: warp-cli registration new'
	@echo 'Then connect with: warp-cli connect'
