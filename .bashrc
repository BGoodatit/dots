#!/usr/bin/env bash
# set -x
# shellcheck disable=all
# ~/.bashrc
#
export BASHRC_LOADED=1
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# --- Detect Architecture and Set Homebrew Path ---
ARCH=$(uname -m)

if [[ "$ARCH" == "arm64" && -d /opt/homebrew ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
elif [[ "$ARCH" == "x86_64" && -d /usr/local ]]; then
    HOMEBREW_PREFIX="/usr/local"
elif command -v brew &>/dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
fi

# Load Homebrew environment
if [[ -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
fi

# --- Ensure System Paths Are in PATH ---
for p in /usr/bin /bin /usr/sbin /sbin; do
    [[ ":$PATH:" != *":$p:"* ]] && PATH="$PATH:$p"
done

# --- Add Custom Paths ---
PATH+=":$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin"
PATH+=":$HOME/httrack_install/bin:$HOME/.npm-global/bin:$HOME/usr/bin:/usr/local/sbin"
PATH+=":$HOMEBREW_PREFIX/opt/openjdk/bin:$HOMEBREW_PREFIX/opt/ruby/bin"
PATH+=":$HOMEBREW_PREFIX/opt/asdf/bin:$HOMEBREW_PREFIX/opt/ccache/libexec"
PATH+=":$HOMEBREW_PREFIX/opt/icu4c@77/bin:$HOMEBREW_PREFIX/opt/icu4c@77/sbin"
export PATH

# --- Enable Bash Completion ---
if [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]]; then
    source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [[ -r "$HOMEBREW_PREFIX/etc/bash_completion" ]]; then
    source "$HOMEBREW_PREFIX/etc/bash_completion"
fi

# Functions
function lsPretty() {
    echo ""
    eza -a -l --header --icons --hyperlink --time-style relative "$1"
    echo ""
}

# Check for updates:
# On macOS, use softwareupdate to detect if system updates are available.
# On other systems, use brew outdated as before.
# function checkUpdates() {
#     if [[ "$(uname)" == "Darwin" ]]; then
#         update_output=$(softwareupdate -l 2>&1)
#         if echo "$update_output" | grep -q "No new software available"; then
#             updates_available=false
#         else
#             updates_available=true
#         fi
#     else
#         updates=$(brew outdated | wc -l)
#         if [ $updates -gt 1 ]; then
#             updates_available=true
#         else
#             updates_available=false
#         fi
#     fi

#     if $updates_available; then
#         sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\" \"/" ~/.bash_profile
#     else
#         sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
#     fi
# }

# 󰘳sudo visudo → **G** then **O**→ add rule: your_username ALL=(ALL) NOPASSWD: /usr/local/bin/brew, /opt/homebrew/bin/brew, /usr/sbin/softwareupdate, /usr/sbin/installer → Esc 󰘳:wq
function checkUpdates() {
    screen -S brew -d -m #sudo softwareupdate -i -a
    # wait for brew to finish
    while [ $(screen -ls | grep -c brew) -gt 0 ]; do
        sleep 1
    done
    updates=$(brew outdated 2>/dev/null | wc -l)
    if [ $updates -gt 1 ]; then
        sed -i ''"s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\" \"/" ~/.bash_profile
    else
        sed -i ''"s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    fi
}

# Check for updates in dotfiles
function checkDotfilesUpdate() {
    cd ~/.files ||
        git fetch --quiet --progress 2>/dev/null
    updates=$(git status | grep -q "behind" && echo "true" || echo "false")
    if $updates; then
        sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"󱈗 \"/" ~/.bash_profile
    else
        sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    fi
}
# Update software:
# On macOS, list and install updates via softwareupdate then run brew upgrade.
# On non-macOS systems, run apt update/upgrade then brew upgrade.
function updateSoftware() {
    brew upgrade
    sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    . ~/.bash_profile
}
# Pull in latest dotfile updates and run setup
function updateDotfiles() {
    currentDir=$(pwd)
    cd ~/.files ||
        git stash
    git pull
    git stash pop
    ./setup.sh
    cd "$currentDir" ||
        sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
    . "$HOME/.bash_profile"

}
# Environment variables
. ~/.bash_profile

# Aliases
alias cd='z'
alias cdi='zi'
alias cat='bat'
alias updot='updateDotfiles'
alias sup='updateSoftware'
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

fastfetch -l ~/ascii.txt #~/.config/fastfetch/logos/ascii.txt

PROMPT_COMMAND='source ~/.bash_profile;'$PROMPT_COMMAND

# export DOTFILES_UPDATE_AVAILABLE="󱓎 "
# export SOFTWARE_UPDATE_AVAILABLE=" "
#export SOFTWARE_UPDATE_AVAILABLE=" "

# # # /usr/bin/env bash
# # set -x
# #
# # ~/.bashrc
# #
# export BASHRC_LOADED=1

# # If not running interactively, don't do anything
# [[ $- != *i* ]] && return

# # Setup Homebrew shell environment (Intel or Apple Silicon)
# if [[ -d /opt/homebrew ]]; then
# 	eval "$(/opt/homebrew/bin/brew shellenv)"
# elif [[ -d /usr/local/Homebrew ]]; then
# 	eval "$(/usr/local/bin/brew shellenv)"
# fi

# # Functions
# # 󰘳sudo visudo → **G** then **O** → add rule: your_username ALL=(ALL) NOPASSWD: /usr/local/bin/brew, /opt/homebrew/bin/brew, /usr/sbin/softwareupdate, /usr/sbin/installer → Esc 󰘳:wq
# # Check for updates with Homebrew
# #
# # ~/.bashrc
# #

# # start tmux
# if command -v tmux &>/dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
# 	exec tmux
# fi

# export BASHRC_LOADED=1
# # If not running interactively, don't do anything
# [[ $- != *i* ]] && return

# # Functions

# # Check for updates with homebrew
# function checkUpdates() {
# 	updates=$(brew outdated | wc -l)
# 	if [ "$updates" -gt 1 ]; then
# 		sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\ \"/" ~/.bash_profile
# 	else
# 		sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
# 	fi
# }

# # Check for updates in dotfiles
# function checkDotfilesUpdate() {
# cd ~/.files || return
# 	git fetch --quiet --progress 2>/dev/null
# 	updates=$(git status | grep -q "behind" && echo "true" || echo "false")
# 	if "$updates"; then
# 		sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"󱓎 \"/" ~/.bash_profile
# 	else
# 		sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
# 	fi
# }

# # Update software using homebrew
# function updateSoftware() {
# 	brew update >/dev/null && brew upgrade --quiet
# 	sed -i '' "s/SOFTWARE_UPDATE_AVAILABLE=.*/SOFTWARE_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
# 	 ~/.bash_profile
# }

# # Pull in latest dotfile updates and run setup
# function updateDotfiles() {
# 	currentDir=$(pwd)
# cd ~/.files || return
# 	git stash
# 	git pull
# 	git stash pop
# 	./setup.sh
# 	cd "$currentDir" || return
# 	sed -i '' "s/DOTFILES_UPDATE_AVAILABLE=.*/DOTFILES_UPDATE_AVAILABLE=\"\"/" ~/.bash_profile
# 	 ~/.bash_profile
# }

# # Environment variables
#  ~/.bash_profile

# # Aliases
# alias cat='bat'
# alias up='updateDotfiles'
# alias sup='updateSoftware'
# alias ls=lsPretty

# # Setup prompt
# eval "$(starship init bash)"

# (checkUpdates &)
# (checkDotfilesUpdate &)

# PROMPT_COMMAND='source ~/.bash_profile;'$PROMPT_COMMAND

# alias fastfetch="~/.scripts/split_layout.sh"

# eval "$(thefuck --alias)"
# # Load bash completion if available
# if [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
#   source "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
# fi
alias check-git-remote="~/.scripts/check-git-remote.sh"
