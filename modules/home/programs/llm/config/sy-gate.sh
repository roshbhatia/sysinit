# sy: gate `sy delete` on session readiness.
#
# Shipped as an executable named `sy`, placed on PATH ahead of seshy's own bin,
# because an interactive-shell function is not a gate: .zshrc is read only by
# interactive shells, so `zsh -c`, every script, every cron entry, and every
# coding agent's shell tool would bypass it. Agents are precisely the callers
# this capability exists for.
#
# Every subcommand except delete/rm/remove is passed straight through, so this
# stays a gate and not a reimplementation of seshy.
#
# Find the real seshy binary. This gate is installed as `sy` and shadows it on
# PATH, so it must skip ITSELF rather than skip a directory.
#
# Do not filter on /nix/store: seshy is not Nix-managed today, but the day it
# is, a store filter would make this gate unable to find it at all. Comparing
# resolved paths against our own works either way.
self_path=$(command -v -- "$0" 2> /dev/null || printf '%s' "$0")
case "$self_path" in
  /*) ;;
  *) self_path="$PWD/$self_path" ;;
esac

sy_real() {
  if [ -n "${SY_REAL:-}" ] && [ -x "$SY_REAL" ]; then
    printf '%s' "$SY_REAL"
    return 0
  fi
  _ifs=$IFS
  IFS=:
  for _d in $PATH; do
    [ -x "$_d/sy" ] || continue
    # Skip this script, however it is reached (symlink, profile, store path).
    if [ "$_d/sy" -ef "$self_path" ] 2> /dev/null; then
      continue
    fi
    case "$_d/sy" in
      "$self_path") continue ;;
    esac
    IFS=$_ifs
    printf '%s' "$_d/sy"
    return 0
  done
  IFS=$_ifs
  return 1
}

SY_REAL=$(sy_real) || {
  printf 'sy: cannot find the seshy binary; only this gate is on PATH\n' >&2
  exit 127
}

sub=${1:-}

case "$sub" in
  delete | rm | remove) ;;
  *)
    exec "$SY_REAL" "$@"
    ;;
esac

# Resolve the session name: the first argument after the subcommand that is not
# a flag. Also note whether --force was passed.
forced=0
name=""
shift
for arg in "$@"; do
  case "$arg" in
    -f | --force) forced=1 ;;
    -*) ;;
    *) [ -n "$name" ] || name=$arg ;;
  esac
done

# No name means seshy picks interactively; there is nothing to check yet.
if [ -z "$name" ]; then
  exec "$SY_REAL" "$sub" "$@"
fi

session_dir=$("$SY_REAL" path "$name" 2> /dev/null)
if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
  session_dir="$HOME/.local/state/seshy/sessions/$name"
fi

if [ -d "$session_dir" ] && command -v agent-review > /dev/null 2>&1; then
  # Run the report even under --force. The spec requires the findings to be
  # printed either way, so the owner sees what they are discarding.
  # Capture the status without tripping errexit. writeShellApplication sets
  # `set -e`, so a bare call would abort the script the moment agent-review
  # reports unfinished work: no refusal message, no --force path, and a gate
  # that appears to hold only because the script died.
  rc=0
  SESHY_SESSION=$name agent-review "$session_dir" || rc=$?
  if [ "$rc" -eq 1 ] && [ "$forced" -eq 0 ]; then
    printf '\nsy: refusing to delete an unfinished session.\n' >&2
    printf "sy: use 'sy delete --force %s' to delete anyway.\n" "$name" >&2
    exit 1
  fi
  # rc 2 means the check could not run. Permissive on purpose: a readiness
  # check that fails must never make a session undeletable.
  [ "$rc" -eq 2 ] && printf 'sy: readiness check could not run; continuing.\n' >&2
fi

exec "$SY_REAL" "$sub" "$@"
