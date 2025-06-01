#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/prompt.sh (begin)
if [ "$WEZTERM_PANE" = "0" ] && [ -z "$NVIM" ]; then
	if [ -n "$MACCHINA_THEME" ]; then
		macchina --theme "$MACCHINA_THEME"
	else
		macchina --theme rosh
	fi
fi

_evalcache oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json
# modules/darwin/home/zsh/core/prompt.sh (end)

