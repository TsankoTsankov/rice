#!/usr/bin/env bash
# Set the default editor
fastfetch

if command -v nvim &> /dev/null; then
	export EDITOR=nvim
	export VISUAL=nvim
	alias vim='nvim'
	alias vi='nvim'
	alias svim='sudo nvim'
else
	export EDITOR=vim
	export VISUAL=vim
fi
alias snano='sudo nano'


###################
# ALIASES
###################
alias ~='cd $HOME'


alias y='yazi'
alias c='clear && fastfetch'
# yazi navigation to frequently used directories

alias web='cd ~/Documents/www/ && y .'
alias dots='cd ~/.config && y .'

alias notes='cd ~/Documents/notes/ && y .'
#create new note
nnote() {
    cd ~/Documents/notes/ || return
    nvim "$1.md"
}

#edit existing note
enote() {
    local file="$1"
    [[ -z "$file" ]] && echo "Usage: enote <filename>" && return 1
    nvim "$HOME/Documents/notes/${file%.md}.md"
}
_enote_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local notes_dir=~/Documents/notes
    COMPREPLY=( $(compgen -W "$(basename -a "$notes_dir"/*.md 2>/dev/null | sed 's/\.md$//')" -- "$cur") )
}

complete -F _enote_complete enote



alias ebrc='nvim ~/.bashrc'
alias cp='cp -i'
alias mv='mv -i'

#change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'

#remove a directory and all files
alias rmd='/bin/rm --recursive --force --verbose '


#aliases for directory listing
alias la='ls -Alh'
alias ls='ls -aFh --color=always'

#search command line history
alias h='history | grep '


### UTILITIE & TOOL ALIASES ###
alias linutil='curl -fsSL https://christitus.com/linux | sh'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
alias config='/usr/bin/git --git-dir=/home/aizen/.cfg/ --work-tree=/home/aizen'
