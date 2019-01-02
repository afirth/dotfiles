# Functions
# sourcef tests file exists, then sources to avoid throwing errors
function sourcef { 
  if [ -f "$1" ]
  then
    source $1
  fi
}

# Bash
# use homebrew bash as login shell
shell_path=/usr/local/bin/bash
if [[ -f ${shell_path} && $BASH_VERSION == "3."* ]]; then
  chsh -s ${shell_path} && echo Login shell updated to $(${shell_path} --version), relaunch.
fi
sourcef ${HOME}/.bashrc
# bash-completion (bash 3.x)
sourcef $(brew --prefix)/etc/bash_completion
# bash-completion@2 (bash 4.x)
sourcef $(brew --prefix)/share/bash-completion/bash_completion
## Longer history
export HISTSIZE=500
# aliases
alias duh="du -ahc"
alias ll="ls -laht"
alias vi="vim"
# options
set -o vi
# profile
sourcef .prompt_command

# Grep
export GREP_COLORS=auto

# FZF
sourcef ~/.fzf.bash

# Iterm2
sourcef ${HOME}/.iterm2_shell_integration.bash

# AWS CLI
#brew install remind101/formulae/assume-role
function makeme { env ASSUMED_ROLE=$1 $(which assume-role) $1 $SHELL -l; }
function pretendme { env ASSUMED_ROLE=$1 $SHELL -l; }
function whoamiaws { aws sts get-caller-identity; }

# ViM
#fix editor exiting 1
export EDITOR=/usr/bin/vim

# Gcloud
# stream last build logs
alias gblog='gcloud beta builds list --limit=1 --format=value\(extract\(id\)\) | xargs gcloud beta builds log --stream'

# Keybase
#use standalone keybase only
alias keybase='keybase --standalone'

# Git
alias gst='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gc='git commit'
alias gcam='git commit -am '
alias gcm='git commit -m '
alias gca='git commit -a '
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gm='git merge'
alias gp='git pull'
# fixws find files in the git repowith trailing whitespace. it's not perfect and might find things in commits which have already been fixed
fixws() {
  # Initial commit: diff against an empty tree object
  against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
  # for FILE in `exec git diff-index --check --cached $against -- \
  for FILE in `exec git diff --check $against -- \
    | sed '/^[+-]/d' \
    | sed -E 's/:[0-9]+:.*//' \
    | uniq` ; do
     # Fix them!
     sed -i '' -E 's/[[:space:]]*$//' "$FILE"
     echo "Fixed ws errors in $FILE"
  done
}

# Perl
# By default non-brewed cpan modules are installed to the Cellar. Persist them across updates with local::lib
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

# Python
#no more .pyc files
export PYTHONDONTWRITEBYTECODE=1

# Gcloud SDK
sourcef /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc 
sourcef /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc 

# icu4c unicode support library
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"

# sbin
export PATH="/usr/local/sbin:$PATH"

#GOLANG
export PATH=$PATH:/usr/local/opt/go/libexec/bin
export PATH=$PATH:$HOME/go/bin

#AWS-VAULT
#export PATH=$HOME/.aws/bin:$PATH
