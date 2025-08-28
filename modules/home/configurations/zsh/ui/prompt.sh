#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

should_run_zellij()
                    {
  [[ "$TERM_PROGRAM" != "WezTerm" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]
}

should_show_macchina()
                       {
  [[ -z "$NVIM" && "$TERM_PROGRAM" != "vscode" && (-z "$WEZTERM_PANE" || "$WEZTERM_PANE" == "0") ]]
}

if [[ -z "$ZELLIJ" && "$SHLVL" -eq 1 && $- == *i* ]]; then
  if should_run_zellij && command -v zellij > /dev/null 2>&1; then
    if [[ -z "$ZELLIJ" ]]; then
      if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
      else
        zellij
      fi
      if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
      fi
    fi
    exec zellij
  fi
fi

if should_show_macchina; then
  macchina --theme "${MACCHINA_THEME:-varre}"
fi

_evalcache oh-my-posh init zsh --config "$XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json"
