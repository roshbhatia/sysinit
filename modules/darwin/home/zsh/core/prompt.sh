#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/prompt.sh (begin)
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

# Function to move cursor to top of terminal before showing prompt
function prompt_at_top() {
	tput cup 0 0
	tput el
}

# Add our function to precmd hooks (runs before each prompt)
autoload -U add-zsh-hook
add-zsh-hook precmd prompt_at_top

# modules/darwin/home/zsh/core/prompt.sh (end)

