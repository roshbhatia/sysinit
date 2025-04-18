#!/usr/bin/env zsh
# shellcheck disable=all
if [ "$WEZTERM_PANE" = "0" ] && [ "$VSCODE_INJECTION" != "1" ]; then
  if [ -n "$MACCHINA_THEME" ]; then
    macchina --theme "$MACCHINA_THEME"
  else
    macchina --theme rosh
  fi
fi

# If this is a VSCODE terminal, we need to use a tiny prompt.
if [ "$VSCODE_INJECTION" = "1" ]; then
  eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/zash.omp.json)"
else
  _evalcache oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin_mocha.omp.json
fi