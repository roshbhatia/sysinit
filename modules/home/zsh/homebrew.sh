#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore
#       ___           ___           ___           ___           ___
#      /  /\         /  /\         /__/\         /  /\         /  /\
#     /  /::|       /  /:/_        \  \:\       /  /::\       /  /:/
#    /  /:/:|      /  /:/ /\        \__\:\     /  /:/\:\     /  /:/
#   /  /:/|:|__   /  /:/ /::\   ___ /  /::\   /  /:/~/:/    /  /:/  ___
#  /__/:/ |:| /\ /__/:/ /:/\:\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/  /  /\
#  \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/
#      |  |:/:/   \  \::/ /:/   \  \::/       \  \::/~~~~   \  \:\  /:/
#      |  |::/     \__\/ /:/     \  \:\        \  \:\        \  \:\/:/
#      |  |:/        /__/:/       \  \:\        \  \:\        \  \::/
#      |__|/         \__\/         \__\/         \__\/         \__\/

if [ -f "/opt/homebrew/bin/brew" ]; then
  _evalcache "$(/opt/homebrew/bin/brew shellenv)"

  # Initialize shell tools and completions with evalcache
  _evalcache "$(brew --prefix)/opt/fzf/shell/completion.zsh"
  _evalcache "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
  _evalcache atuin init zsh --disable-up-arrow
  _evalcache kubectl completion zsh
  _evalcache docker completion zsh
  _evalcache stern --completion zsh
  _evalcache gh completion -s zsh

  # Source syntax highlighting and autosuggestions with evalcache
  _evalcache "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  _evalcache "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi