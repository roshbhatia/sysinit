#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/prompt.sh (begin)
if [ -z "$ZELLIJ" ] && [ -z "$WEZTERM_CONFIG_DIR" ] && [ -z "$NVIM" ] && [ "$SHLVL" -eq 1 ]; then
  if [[ $- == *i* ]] && [ -z "$VSCODE_INJECTION" ] && [ -z "$JETBRAINS_TERMINAL" ]; then
    if command -v zellij > /dev/null 2>&1; then
      exec zellij
    fi
  fi
fi

if [ "$WEZTERM_PANE" = "0" ] && [ -z "$NVIM" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme varre
  fi
fi

if [ -n "$ZELLIJ" ] && [ -z "$WEZTERM_PANE" ] && [ -z "$NVIM" ] && [ -z "$ZELLIJ_SYSTEM_INFO_SHOWN" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme varre
  fi
  export ZELLIJ_SYSTEM_INFO_SHOWN=1
fi

_evalcache oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh/themes/sysinit.omp.json
# modules/darwin/home/zsh/core/prompt.sh (end)
