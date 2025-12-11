#!/usr/bin/env zsh
# shellcheck disable=all
_path_debug() {
  [[ -n $SYSINIT_DEBUG ]] && echo "[PATH] $*" >&2
}

path.print() {
  echo "$PATH" | tr ':' '\n' | bat --style=numbers,grid
}

path.add() {
  local dir="$1"
  if [[ -d $dir ]]; then
    path=("$dir" "${path[@]}")
    _path_debug "Added $dir"
  else
    _path_debug "Skipped $dir (not a directory)"
  fi
}

path.add.bulk() {
  local -a dirs=("$@")
  local -a existing=()

  for dir in "${dirs[@]}"; do
    [[ -d $dir ]] && existing+=("$dir")
  done

  if ((${#existing[@]} > 0)); then
    path=("${existing[@]}" "${path[@]}")
    _path_debug "Added ${#existing[@]} paths"
  fi
}
