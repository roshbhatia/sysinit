#!/usr/bin/env zsh
# shellcheck disable=all

# A stale mux socket must not block every prompt, so pane capture is bounded.
_ask_capture() {
  local snapshot

  [[ ${ASK_CAPTURE:-1} == 1 ]] || return 0
  [[ -n $WEZTERM_PANE ]] || return 0
  export ASK_CAPTURE_ID="$WEZTERM_PANE"
  command -v ask > /dev/null 2>&1 || return 0
  command -v wezterm > /dev/null 2>&1 || return 0
  snapshot=$(@timeout@ 0.25 wezterm cli --no-auto-start get-text --pane-id "$WEZTERM_PANE" 2> /dev/null) || return 0
  print -rn -- "$snapshot" | ask --capture 2> /dev/null
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _ask_capture
