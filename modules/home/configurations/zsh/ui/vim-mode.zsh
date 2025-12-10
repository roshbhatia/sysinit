#!/usr/bin/env zsh
# shellcheck disable=all
# Vim mode integration with wezterm user vars

# Set wezterm user var for vim mode detection
_set_vim_mode_user_var() {
  printf "\033]1337;SetUserVar=ZVM_MODE=%s\007" "${ZVM_MODE:-n}"
}

# Hook into zsh-vi-mode
if (($ + functions[zvm_after_select_vi_mode])); then
  # Wrap existing hook
  functions[_orig_zvm_after_select_vi_mode]=$functions[zvm_after_select_vi_mode]
  zvm_after_select_vi_mode() {
    _orig_zvm_after_select_vi_mode
    _set_vim_mode_user_var
  }
else
  zvm_after_select_vi_mode() {
    _set_vim_mode_user_var
  }
fi

# Fallback: hook into zle for non-zsh-vi-mode setups
zle-keymap-select() {
  case $KEYMAP in
    vicmd) ZVM_MODE="n" ;;
    viins | main) ZVM_MODE="i" ;;
    visual) ZVM_MODE="v" ;;
  esac
  _set_vim_mode_user_var
}
zle -N zle-keymap-select

# Set initial mode
ZVM_MODE="i"
_set_vim_mode_user_var
