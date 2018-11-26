#mostly for perl
source ~/.bashrc

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi 

#show git branch in prompt
parse_git_branch() {
  git symbolic-ref HEAD 2>/dev/null | sed -e "s/^refs\/heads\///"
}

## Longer history
export HISTSIZE=5000
export HISTFILE="$HOME/.bash_long_history"

##AWS CLI
#brew install remind101/formulae/assume-role
function makeme { env ASSUMED_ROLE=$1 $(which assume-role) $1 $SHELL -l; }
function pretendme { env ASSUMED_ROLE=$1 $SHELL -l; }
function whoamiaws { aws sts get-caller-identity; }

#show aws profile if exported
#workaround https://github.com/serverless/serverless/issues/3833
if [ ! -z ${ASSUMED_ROLE} ]; then aws=" ${ASSUMED_ROLE}"; fi
export PS1="\u@mbp \[$(tput sgr0)\]\[\033[38;5;10m\]\W\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;29m\]\$(parse_git_branch)\[$(tput sgr0)\]\[\033[38;5;15m\]${aws} \$ \[$(tput sgr0)\]"

# Setting PATH for Python 3.6
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH

#no more pyc
export PYTHONDONTWRITEBYTECODE=1

#fix editor exiting 1
export EDITOR=/usr/bin/vim

#GOLANG
export PATH=$PATH:/usr/local/opt/go/libexec/bin
export PATH=$PATH:/Users/afirth/go/bin

#AWS-VAULT
#export PATH=/Users/afirth/.aws/bin:$PATH

#keybase aliases
#use standalone keybase only
alias keybase='keybase --standalone'

#Git aliases
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

# Find files with trailing whitespace
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

#get aws creds
alias creds='source /Users/afirth/git/scripts/prod_creds.sh'

# added by Anaconda3 installer
export PATH="/Users/afirth/anaconda3/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/afirth/gcloud/path.bash.inc' ]; then source '/Users/afirth/gcloud/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/afirth/gcloud/completion.bash.inc' ]; then source '/Users/afirth/gcloud/completion.bash.inc'; fi
eval $(thefuck --alias)
# By default non-brewed cpan modules are installed to the Cellar. If you wish
# for your modules to persist across updates we recommend using `local::lib
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH="/usr/local/sbin:$PATH"
