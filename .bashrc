#!/usr/bin/env bash
# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ====================
# BASIC SETTINGS
# ====================

export VISUAL=nvim
export EDITOR=nvim 
export BROWSER=firefox
export TERMINAL=kitty
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8


# ====================
# SHELL BEHAVIOUR
# ====================

shopt -s histappend     # Prevent history from being overwritten on close
HISTCONTROL=ignoredups:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
export HISTTIMEFORMAT="%F %T "

# Prevents accidentally overwriting files with redirection
# To force overwrite, you use >! or >|
# echo "data" > existing.txt Fails with noclobber on
# echo "data" >| existing.txt Overwrites
set -o noclobber        
#set -o vi


# ====================
# ALIASES
# ====================
alias ~='cd $HOME'	# navigate to home dir
alias home='~'		# navigate to home dir
alias ..='cd ..'	# navigate to previous dir
alias ...='cd ../,,'	# navigate 2 directories back
alias config='cd $HOME/.config'     # navigate to the .config folder
alias www='cd $HOME/Documents/www'	# navigate to perosnal web projects dir
alias notes='cd $HOME/Documents/notes'	# navigate ot the notes dir
alias clear='clear && fastfetch'    # clear the terminal and run fastfetch
alias c='clear'	# clear the terminal and run fastfetch
bind '"\C-l":"clear\n"'     # When CTRL + L presses -> execute command c (alias above)
alias snano='sudo nano'		# super user nano 
alias svim='sudo nvim'		# super user neovim
alias ebrc='edit_bashrc'	# open $HOME/.bashrc with default editor
alias sbrc='source $HOME/.bashrc'   # source the .bashrc config file
alias dotfiles='/usr/bin/git --git-dir=$HOME/Documents/dotfiles/ --work-tree=$HOME'	# git bare repo
alias la='ls -Alh'	# for detailed listing
alias ls='ls -aFh --color=always'	# for colorful and detailed ls
alias linutil='echo "$(date): Running christitus linux script" >> ~/.linutil.log && curl -fsSL https://christitus.com/linux | sh'	# run christitustech linux toolbox stable branch
alias grep='grep --color=auto'

# ====================
# FUNCTIONS
# ====================
edit_bashrc() {
	local bashrc_file="$HOME/.bashrc"

	if [ ! -f "$bashrc_file" ]; then
		echo "Error: $bashrc_file not found." >&2
		return 1
	fi

	if command -v nvim >/dev/null 2>&1; then
		nvim "$bashrc_file"
	elif command -v nano >/dev/null 2>&1; then
		nano "$bashrc_file"
	elif command -v vi >/dev/null 2>&1; then
		vi "$bashrc_file"
	elif command -v less >/dev/null 2>&1; then
		echo "No preferred editors found. Opening in read-only mode with less."
		less "$bashrc_file"
	else
		echo "Error: No suitable editor (nvim, nano, vi, less) found in PATH." >&2
		return 2
	fi
}

# ====================
# Customization
# ====================
eval "$(starship init bash)"
fastfetch

# ====================
# Tool/Program Specific Configs
# ====================
. "$HOME/.cargo/env"
