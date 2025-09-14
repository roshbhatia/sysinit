#!/usr/bin/env zsh
# shellcheck disable=all

should_run_zellij()
                    {
  [[ -z "$ZELLIJ" ]] &&
    [[ -z "$TMUX" ]] &&
    [[ "$TERM_PROGRAM" != "WezTerm" ]] &&
    [[ "$TERM_PROGRAM" != "vscode" ]] &&
    [[ -z "$NVIM" ]]
}

if [[ $- == *i* && "$SHLVL" -eq 1 ]]; then
  if should_run_zellij && command -v zellij > /dev/null 2>&1; then
    if [[ "${ZELLIJ_AUTO_ATTACH:-false}" == "true" ]]; then
      exec zellij attach -c
    else
      exec zellij
    fi
  fi
fi
