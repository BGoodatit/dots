#
# ~/.bashrc
#

export BASHRC_LOADED=1
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Functions
function lsPretty() {
    echo ""
    eza -a -l --header --icons --hyperlink --time-style relative $1
    echo ""
}

# Check for updates with brew
function checkUpdates() {
    updates=$(brew outdated | wc -l)
    if [ $updates -gt 1 ]; then
        sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\ \"/" ~/.bash_profile
    else
        sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    fi
}

# Check for updates in dotfiles
function checkDotfilesUpdate() {
    cd ~/git/dots
    git fetch >/dev/null
    updates=$(git status | grep -q "behind" && echo "true" || echo "false")
    if $updates; then
        sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"󱈗\"/" ~/.bash_profile
    else
        sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    fi
}

# Update software using brew
function updateSoftware() {
    #sudo softwareupdate -i -a
    brew upgrade
    sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    . ~/.bash_profile
}

# Pull in latest dotfile updates and run setup
function updateDotfiles() {
    currentDir=$(pwd)
    cd ~/git/dots
    git stash
    git pull
    git stash pop
    ./setup.sh
    cd $currentDir
    sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    . ~/.bash_profile
}

# Environment variables
. ~/.bash_profile

# Aliases
alias cd='z'
alias cdi='zi'
alias cat='bat'
alias up='updateDotfiles'
alias us='updateSoftware'
alias ls=lsPretty

# Enable bash completion in interactive shells
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Setup prompt
eval "$(starship init bash)"
eval "$(zoxide init bash)"

(checkUpdates &)
(checkDotfilesUpdate &)

fastfetch -l ~/.config/fastfetch/logos/ascii.txt

PROMPT_COMMAND='source ~/.bash_profile;'$PROMPT_COMMAND

if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
elif [ -d /usr/local ]; then
  eval "$(/usr/local/bin/brew shellenv)"     # Intel
fi
