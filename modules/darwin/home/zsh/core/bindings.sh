#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/zsh/core/bindings.sh (begin)
# Modified version of https://github.com/jirutka/zsh-shift-select/blob/master/zsh-shift-select.plugin.zsh
# vim: set ts=4:
# Copyright 2022-present Jakub Jirutka <jakub@jirutka.cz>.
# SPDX-License-Identifier: MIT
#
# Emacs shift-select mode for Zsh - select text in the command line using Shift
# as in many text editors, browsers and other GUI programs.
#
# Version: 0.1.1
# Homepage: <https://github.com/jirutka/zsh-shift-select>
# Move cursor to the end of the buffer.
# This is an alternative to builtin end-of-buffer-or-history.
function end-of-buffer() {
	CURSOR=${#BUFFER}
	zle end-of-line -w  # trigger syntax highlighting redraw
}
zle -N end-of-buffer

# Move cursor to the beginning of the buffer.
# This is an alternative to builtin beginning-of-buffer-or-history.
function beginning-of-buffer() {
	CURSOR=0
	zle beginning-of-line -w  # trigger syntax highlighting redraw
}
zle -N beginning-of-buffer

# Kill the selected region and switch back to the main keymap.
function shift-select::kill-region() {
	zle kill-region -w
	zle -K main
}
zle -N shift-select::kill-region

# Deactivate the selection region, switch back to the main keymap and process
# the typed keys again.
function shift-select::deselect-and-input() {
	zle deactivate-region -w
	# Switch back to the main keymap (emacs).
	zle -K main
	# Push the typed keys back to the input stack, i.e. process them again,
	# but now with the main keymap.
	zle -U "$KEYS"
}
zle -N shift-select::deselect-and-input

# If the selection region is not active, set the mark at the cursor position,
# switch to the shift-select keymap, and call $WIDGET without 'shift-select::'
# prefix. This function must be used only for shift-select::<widget> widgets.
function shift-select::select-and-invoke() {
	if (( !REGION_ACTIVE )); then
		zle set-mark-command -w
		zle -K shift-select
	fi
	zle ${WIDGET#shift-select::} -w
}

function {
	emulate -L zsh

	# Create a new keymap for the shift-selection mode.
	bindkey -N shift-select

	# Bind all possible key sequences to deselect-and-input, i.e. it will be used
	# as a fallback for "unbound" key sequences.
	bindkey -M shift-select -R '^@'-'^?' shift-select::deselect-and-input

	local kcap seq seq_mac widget

	# Bind Shift keys in the emacs and shift-select keymaps.
	for	kcap   seq          seq_mac    widget (             # key name
		kLFT   '^[[1;2D'    x          backward-char        # Shift + LeftArrow
		kRIT   '^[[1;2C'    x          forward-char         # Shift + RightArrow
		kri    '^[[1;2A'    x          up-line              # Shift + UpArrow
		kind   '^[[1;2B'    x          down-line            # Shift + DownArrow
		kHOM   '^[[1;2H'    x          beginning-of-line    # Shift + Home
		x      '^[[97;6u'   x          beginning-of-line    # Shift + Ctrl + A
		kEND   '^[[1;2F'    x          end-of-line          # Shift + End
		x      '^[[101;6u'  x          end-of-line          # Shift + Ctrl + E
		x      '^[[1;6D'    '^[[1;4D'  backward-word        # Shift + Ctrl/Option + LeftArrow
		x      '^[[1;6C'    '^[[1;4C'  forward-word         # Shift + Ctrl/Option + RightArrow
		x      '^[[1;6H'    '^[[1;4H'  beginning-of-buffer  # Shift + Ctrl/Option + Home
		x      '^[[1;6F'    '^[[1;4F'  end-of-buffer        # Shift + Ctrl/Option + End
	); do
		# Use alternative sequence (Option instead of Ctrl) on macOS, if defined.
		[[ "$OSTYPE" = darwin* && "$seq_mac" != x ]] && seq=$seq_mac

		zle -N shift-select::$widget shift-select::select-and-invoke
		bindkey -M emacs ${terminfo[$kcap]:-$seq} shift-select::$widget
		bindkey -M shift-select ${terminfo[$kcap]:-$seq} shift-select::$widget
	done

	# Bind keys in the shift-select keymap.
	for	kcap   seq        widget (                          # key name
		kdch1  '^[[3~'    shift-select::kill-region         # Delete
		bs     '^?'       shift-select::kill-region         # Backspace
	); do
		bindkey -M shift-select ${terminfo[$kcap]:-$seq} $widget
	done
}

# Bind CTRL + Space + HJKL keys for these actions:
bindkey '^ h' beginning-of-line    # CTRL + Space + h for beginning of line
bindkey '^ j' backward-word        # CTRL + Space + j for back word
bindkey '^ k' forward-word         # CTRL + Space + k for forward word
bindkey '^ l' end-of-line          # CTRL + Space + l for end of line

# Bind CTRL + Space + YUIO keys for word and line selection actions:
bindkey '^ y' vi-select-word-forward    # CTRL + Space + y to select the current word forward
bindkey '^ u' vi-select-word-backward   # CTRL + Space + u to select the current word backward
bindkey '^ i' vi-select-to-line-start   # CTRL + Space + i to select from cursor to line start
bindkey '^ o' vi-select-to-line-end     # CTRL + Space + o to select from cursor to line end

# Define widgets for the new bindings
function vi-select-word-forward() {
  zle vi-forward-word -w
  zle set-mark-command -w
}
zle -N vi-select-word-forward

function vi-select-word-backward() {
  zle vi-backward-word -w
  zle set-mark-command -w
}
zle -N vi-select-word-backward

function vi-select-to-line-start() {
  zle beginning-of-line -w
  zle set-mark-command -w
}
zle -N vi-select-to-line-start

function vi-select-to-line-end() {
  zle end-of-line -w
  zle set-mark-command -w
}
zle -N vi-select-to-line-end
# modules/darwin/home/zsh/core/bindings.sh (end)