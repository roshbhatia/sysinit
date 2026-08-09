#!/usr/bin/env bash

agent_review_suffix() {
  local pane="$1"
  local now="${2:-}"
  [ -n "$pane" ] || return 0
  local panes_dir
  # sysinit:documented-default
  panes_dir=$(sysinit_path agentPanes) || panes_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes"
  # One pane record. Schema: pkgs/sysinit-agent/internal/agentstate/SCHEMA.md.
  local state_file="$panes_dir/$pane.json"
  [ -f "$state_file" ] || return 0

  local st
  st=$(jq -rj '[.repo // "", .branch // "", (if .dirty then "dirty" else "" end), (.since // 0 | tostring)] | join("\u0001")' \
    "$state_file" 2> /dev/null) || return 0
  [ -n "$st" ] || return 0

  local s_repo s_branch s_dirty s_since
  IFS=$(printf '\001') read -r s_repo s_branch s_dirty s_since <<< "$st"

  local where=""
  [ -n "$s_repo" ] && where="$s_repo"
  if [ -n "$s_branch" ]; then
    if [ -n "$where" ]; then where="$where · $s_branch"; else where="$s_branch"; fi
  fi
  [ -n "$s_dirty" ] && [ -n "$where" ] && where="$where ✱"

  local age=""
  case "$s_since" in
    '' | *[!0-9]*) : ;;
    0) : ;;
    *)
      [ -n "$now" ] || now=$(date +%s 2> /dev/null) || now=0
      local secs=$((now - s_since))
      if [ "$secs" -ge 0 ] 2> /dev/null; then
        if [ "$secs" -lt 60 ]; then
          age="${secs}s"
        elif [ "$secs" -lt 3600 ]; then
          age="$((secs / 60))m"
        else
          age="$((secs / 3600))h"
        fi
      fi
      ;;
  esac

  local part
  for part in "$where" "$age"; do
    [ -n "$part" ] && printf ' — %s' "$part"
  done
  return 0
}
