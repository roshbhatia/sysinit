#!/usr/bin/env zsh
# shellcheck disable=all

# `ask --last` hands an agent whatever the previous command printed. WezTerm
# marks command boundaries with OSC 133, but `wezterm cli` does not expose the
# zones, so the boundary is recorded here instead: one snapshot of the pane
# before every command, and the text between two snapshots is one command's
# output.
#
# This costs about 25ms per prompt, all of it inside `wezterm cli get-text`. It
# runs in preexec rather than precmd so a bare enter does not rotate the
# snapshots and throw away the output you were about to ask about. Set
# ASK_CAPTURE=0 to turn it off.
_ask_capture() {
  [[ ${ASK_CAPTURE:-1} == 1 ]] || return 0
  [[ -n $WEZTERM_PANE ]] || return 0
  command -v ask > /dev/null 2>&1 || return 0
  ask --capture 2> /dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _ask_capture
