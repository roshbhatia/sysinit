#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
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

# Create shift-select keymap
bindkey -N shift-select 2>/dev/null

# Define shifted keys for selection
bindkey "\e[1;2D" select-word-left # Shift+Left
bindkey "\e[1;2C" select-word-right # Shift+Right
bindkey "\e[1;2A" select-line-up # Shift+Up
bindkey "\e[1;2B" select-line-down # Shift+Down

# Deletion in shift-select mode
bindkey -M shift-select "^?" delete-selection # Backspace
bindkey -M shift-select "^[[3~" delete-selection # Delete

# Functions to handle text selection
select-word-left() {
  MARK=$CURSOR
  zle backward-word
  zle set-mark-command
  zle -K shift-select
}
zle -N select-word-left

select-word-right() {
  MARK=$CURSOR
  zle forward-word
  zle set-mark-command
  zle -K shift-select
}
zle -N select-word-right

select-line-up() {
  MARK=$CURSOR
  zle up-line-or-history
  zle set-mark-command
  zle -K shift-select
}
zle -N select-line-up

select-line-down() {
  MARK=$CURSOR
  zle down-line-or-history
  zle set-mark-command
  zle -K shift-select
}
zle -N select-line-down

delete-selection() {
  zle kill-region
  zle -K main
}
zle -N delete-selection