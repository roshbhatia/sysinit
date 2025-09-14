#!/usr/bin/env zsh
# shellcheck disable=all
should_show_macchina()
                       {
  [[ -z "$NVIM" && "$TERM_PROGRAM" != "vscode" && (-z "$WEZTERM_PANE" || "$WEZTERM_PANE" == "0") ]]
}

if should_show_macchina; then
  macchina --theme "${SYSINIT_MACCHINA_THEME:-rosh}"
fi

_evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
