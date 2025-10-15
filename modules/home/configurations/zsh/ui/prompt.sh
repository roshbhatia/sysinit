#!/usr/bin/env zsh
# shellcheck disable=all
should_show_macchina() {
  # Only show macchina in the first pane and only once per window
  # WEZTERM_PANE=0 is the first pane, and we track if we've already shown it
  [[ -z $NVIM && $TERM_PROGRAM != "vscode" && $WEZTERM_PANE == "0" && -z $MACCHINA_SHOWN ]]
}

if should_show_macchina; then
  macchina --theme "${SYSINIT_MACCHINA_THEME:-rosh}"
  export MACCHINA_SHOWN=1
fi

eval "$(oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json")"
