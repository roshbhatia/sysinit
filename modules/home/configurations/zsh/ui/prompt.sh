#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

should_run_zellij() {
  [[ "$TERM_PROGRAM" != "WezTerm" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]
}

should_show_macchina() {
  [[ -z "$NVIM" && (-z "$WEZTERM_PANE" || "$WEZTERM_PANE" == "0") ]]
}

if [[ -z "$ZELLIJ" && "$SHLVL" -eq 1 && $- == *i* ]]; then
  if should_run_zellij && command -v zellij >/dev/null 2>&1; then
    exec zellij
  fi
fi

if should_show_macchina; then
  macchina --theme "${MACCHINA_THEME:-varre}"
fi

if [[ -n "$ZELLIJ" && -z "$WEZTERM_PANE" && -z "$NVIM" ]]; then
  macchina --theme "${MACCHINA_THEME:-varre}"
fi

_evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
