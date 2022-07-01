# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# local bin
export PATH=~/.local/bin:$PATH

# Golang
which go > /dev/null && \
  export GOPATH=$(go env GOPATH) && \
  export PATH=$GOPATH/bin:$PATH
  export PATH=/usr/local/go/bin:$PATH #for ubuntu go install

# # Linkerd
# export PATH=$PATH:$HOME/.linkerd2/bin
# which linkerd > /dev/null && \
#   # linkerd completion zsh > "${fpath[1]}/_linkerd"
#   source <(linkerd completion zsh)
#   echo TODO fix linkerd completion

# Krew
export PATH=$PATH:$HOME/.krew/bin

# Kubebuilder
export PATH=$PATH:/usr/local/kubebuilder/bin


# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="afirth"

## zsh options
# always start in tmux
export ZSH_TMUX_AUTOSTART=true
# change autosuggest color for solarized dark
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=60'


# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  asdf
  aws
  common-aliases
  docker
  gcloud
  git
  golang
  kube-ps1
  kubectl
  tmux
  vi-mode
  z # fast dir switching
  zsh-autosuggestions # fish style autocomplete
)

DISABLE_MAGIC_FUNCTIONS=true #BUG https://stackoverflow.com/questions/25614613/how-to-disable-zsh-substitution-autocomplete-with-url-and-backslashes
source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
   export EDITOR='nvim'
 fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# bindings for pgup/pgdown during autocomplete
bindkey "^[[5~" history-beginning-search-backward
bindkey "^[[6~" history-beginning-search-forward

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

alias zzz="systemctl suspend -i"
alias ll='ls -laht'
#preserve aliases in watch commands. can't pass args though
alias wat='watch '

alias afiy='apt-fast install -y'
alias pkzs='pkill zoom; pkill slack'

alias history='omz_history -i'

alias dispsw='~/git/dotfiles/toggle-display.sh'

## theme switching
light_theme='NumixSolarizedLightBlue'
dark_theme='NumixSolarizedDarkBlue'
function switch_gtk_theme() {
  # get current theme
  current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme \
    | sed 's/[^a-zA-Z0-9]//g')
  case $current_theme in
    $light_theme)
      gsettings set org.gnome.desktop.interface gtk-theme $dark_theme
      ;;
    $dark_theme)
      gsettings set org.gnome.desktop.interface gtk-theme $light_theme
      ;;
  esac
}
alias bgt='switch_gtk_theme'


# git branch creation
unalias gcb
function gcb {
  git checkout -b `date +%F`-"$1"
}

alias vi='nvim'
alias drsh='docker run --rm -it --entrypoint=sh'

#kube stuff
alias kns='kubectl config set-context --current --namespace'

#git overrides
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gcm='git commit -m'

# Gcloud
# stream last build logs
alias gblog='gcloud beta builds list --limit=1 --format=value\(extract\(id\)\) | xargs gcloud beta builds log --stream'
# apt-get default path
if [ -f '/usr/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/share/google-cloud-sdk/completion.zsh.inc'; fi

# skaffold
which skaffold > /dev/null && \
  source <(skaffold completion zsh)

# JenkinsX
export PATH=$PATH:$HOME/.jx/bin
which jx > /dev/null && \
  source <(jx completion zsh)


## HISTORY
# unsetopt share_history
## prepend lines with space to keep them from being recorded
setopt hist_ignore_space
export HISTSIZE=100000
export SAVEHIST=HISTSIZE

## don't complete long lines
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
## and be faster
export ZSH_AUTOSUGGEST_USE_ASYNC=true

# The next line updates PATH for the Google Cloud SDK.
## INSTALL curl https://sdk.cloud.google.com | bash
gc_path=$HOME/google-cloud-sdk/
if [ -d $gc_path ]; then
  for file in $gc_path/*.zsh.inc; do
    source "$file"
  done
fi

## magical regex globs
setopt extendedglob

## prompt
# add kubectx info to prompt
NEWLINE=$'\n'
KUBE_PS1_SYMBOL_ENABLE=true
#shorten cluster name
# PROMPT=$PROMPT'$(echo -n "$AWS_PROFILE ")''$(kube_ps1 | sed "s/gke.*_/gke_/")'${NEWLINE}'$ '
PROMPT=$PROMPT'$(kube_ps1 | sed "s/gke.*_/gke_/")$(aws_prompt_info)'${NEWLINE}'$ '

# term prefs -> profiles -> show bold text in bright colors
zle_highlight=(default:bold)
# if [ ! "$TMUX" = "" ]; then export TERM=xterm-256color; fi #https://github.com/zsh-users/zsh-autosuggestions/issues/229


fpath=($fpath ~/.zsh/completion)
autoload -U compinit
compinit

PATH="/home/afirth/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/afirth/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/afirth/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/afirth/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/afirth/perl5"; export PERL_MM_OPT;
