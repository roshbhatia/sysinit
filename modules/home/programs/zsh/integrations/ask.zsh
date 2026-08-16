#!/usr/bin/env zsh
# shellcheck disable=all

# Snapshots the pane for `ask --last`, as `wezterm cli` does not expose the
# OSC 133 zones that mark where one command's output starts. Costs 25ms per
# prompt; set ASK_CAPTURE=0 to turn it off. preexec, not precmd, so a bare enter
# does not rotate the snapshots away.
_ask_capture() {
  [[ ${ASK_CAPTURE:-1} == 1 ]] || return 0
  [[ -n $WEZTERM_PANE ]] || return 0
  command -v ask > /dev/null 2>&1 || return 0
  ask --capture 2> /dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _ask_capture
