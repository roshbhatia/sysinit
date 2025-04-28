#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/prompt.sh (begin)
if [ "$WEZTERM_PANE" = "0" ] && [ "$VSCODE_INJECTION" != "1" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi

# Check for VSCode terminal using multiple environment variables
if [ -n "$VSCODE_INSPECTOR_OPTIONS" ] || [ -n "$VSCODE_GIT_ASKPASS_NODE" ] || [ -n "$VSCODE_GIT_IPC_HANDLE" ]; then
  # VSCode terminal detected
  eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/zash.omp.json)"
else
  # Not in VSCode terminal
  _evalcache oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin_mocha.omp.json
fi
# modules/darwin/home/zsh/core/prompt.sh (end)
