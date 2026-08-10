# Read one path out of the paths manifest.
# per file, marked `sysinit:documented-default`. Putting the fallback here
sysinit_path() {
  # The manifest's own location is the one fact it cannot carry, so this is the
  # sysinit:documented-default
  manifest="${SYSINIT_PATHS_MANIFEST:-${XDG_STATE_HOME:-$HOME/.local/state}/sysinit/paths.json}"
  [ -s "$manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$manifest" 2> /dev/null) || return 1
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}
