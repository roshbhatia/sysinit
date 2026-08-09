# Read one path out of the paths manifest.
#
# Prepended to every runtime script that needs a state path. The manifest holds
# absolute paths, so a caller never composes one, and `modules/shared/options/
# paths-layout.json` is the only place the layout is written down.
#
# Absolute rather than a variable to expand, because `repo.go:62-65` records
# that a process launched from a mux server inherits no session variables, so
# `XDG_STATE_HOME` is unset in exactly the place a composed path would run.
#
# Fails rather than guesses. A caller that wants a fallback writes its own, one
# per file, marked `sysinit:documented-default`. Putting the fallback here
# instead would make this file a second producer of the layout, which is the
# defect the manifest removes.
sysinit_path() {
  # The manifest's own location is the one fact it cannot carry, so this is the
  # single bootstrap constant of the shell tree. Phase 9 installs the manifest
  # here on a box with no Nix.
  # sysinit:documented-default
  manifest="${SYSINIT_PATHS_MANIFEST:-${XDG_STATE_HOME:-$HOME/.local/state}/sysinit/paths.json}"
  [ -s "$manifest" ] || return 1
  command -v jq > /dev/null 2>&1 || return 1
  value=$(jq -er --arg k "$1" '.paths[$k] // empty' "$manifest" 2> /dev/null) || return 1
  [ -n "$value" ] || return 1
  printf '%s\n' "$value"
}
