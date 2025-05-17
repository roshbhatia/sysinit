#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/prompt.sh (begin)
# Function to move cursor to top of terminal
function prompt_at_top() {
	# Move to top left of screen
	tput cup 0 0
	# Clear the line
	tput el
}

# Add our function to precmd hooks (runs before each prompt)
autoload -U add-zsh-hook
add-zsh-hook precmd prompt_at_top

# Function to toggle the always-on-top behavior
function toggle_top_prompt() {
	if [[ -n "$ZSH_TOP_PROMPT" ]]; then
		# Turn it off
		add-zsh-hook -d precmd prompt_at_top
		unset ZSH_TOP_PROMPT
		echo "Top prompt OFF"
	else
		# Turn it on
		add-zsh-hook precmd prompt_at_top
		export ZSH_TOP_PROMPT=1
		echo "Top prompt ON"
	fi
}

# Initialize - turn it on by default
export ZSH_TOP_PROMPT=1
clear

if [ "$WEZTERM_PANE" = "0" ]; then
	if [ -n "$MACCHINA_THEME" ]; then
		macchina --theme "$MACCHINA_THEME"
	else
		macchina --theme rosh
	fi
fi

if [ -n "$FLOATERM" ]; then
	eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/zash.omp.json)"
else
	_evalcache oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json
fi
# modules/darwin/home/zsh/core/prompt.sh (end)
