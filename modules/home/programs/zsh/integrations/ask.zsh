#!/usr/bin/env zsh
# shellcheck disable=all

# A stale mux socket must not block every prompt, so pane capture is bounded.
_ask_capture() {
  local snapshot

  [[ ${ASK_CAPTURE:-1} == 1 ]] || return 0
  [[ -n ${TMUX_PANE:-${WEZTERM_PANE:-}} ]] || return 0
  export ASK_CAPTURE_ID="${TMUX_PANE:-$WEZTERM_PANE}"
  command -v ask > /dev/null 2>&1 || return 0
  if [[ -n ${TMUX_PANE:-} ]]; then
    snapshot=$(@timeout@ 0.25 tmux capture-pane -p -S - -t "$TMUX_PANE" 2> /dev/null) || return 0
  else
    command -v wezterm > /dev/null 2>&1 || return 0
    snapshot=$(@timeout@ 0.25 wezterm cli --no-auto-start get-text --pane-id "$WEZTERM_PANE" 2> /dev/null) || return 0
  fi
  print -rn -- "$snapshot" | @timeout@ --kill-after=0.1 0.25 ask --capture 2> /dev/null || return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _ask_capture
