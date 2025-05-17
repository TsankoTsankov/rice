#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# function to open .bashrc with available editor
# prefered editr = nvim
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

### SYSTEM & CONFIG ALIASES ###
alias ebrc='edit_bashrc'	# open $HOME/.bashrc with default editor
alias dotfiles='/usr/bin/git --git-dir=$HOME/Documents/dotfiles/ --work-tree=$HOME'	# git bare repo


### TOOLS & SCRIPTS ALIASES ###
alias linutil='echo "$(date): Running christitus linux script" >> ~/.linutil.log && curl -fsSL https://christitus.com/linux | sh'	# run christitustech linux toolbox stable branch


alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='[\u@\h \W]\$ '
