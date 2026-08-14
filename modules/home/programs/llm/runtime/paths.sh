sysinit_path() {
  manifest="${SYSINIT_PATHS_MANIFEST:-${XDG_STATE_HOME:-$HOME/.local/state}/sysinit/paths.json}"
  [ -s "$manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$manifest" 2> /dev/null) || return 1
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}
