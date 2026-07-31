# Gates `sy delete` on session readiness.
#
# Shipped as an executable named `sy` so it shadows seshy for every caller: a
# shell function would be bypassed by `zsh -c`, by scripts, and by every agent's
# shell tool. seshy stays out of home.packages so the two do not collide on bin/sy.
#
# SY_REAL is baked in by notify.nix.

if [ ! -x "$SY_REAL" ]; then
  printf 'sy: the seshy binary is missing at %s\n' "$SY_REAL" >&2
  exit 127
fi

sub=${1:-}

case "$sub" in
  delete | rm | remove) ;;
  *)
    exec "$SY_REAL" "$@"
    ;;
esac

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

# no name means seshy picks interactively, so there is nothing to check
if [ -z "$name" ]; then
  exec "$SY_REAL" "$sub" "$@"
fi

session_dir=$("$SY_REAL" path "$name" 2> /dev/null)
if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
  session_dir="$HOME/.local/state/seshy/sessions/$name"
fi

if [ -d "$session_dir" ] && command -v agent-review > /dev/null 2>&1; then
  # `|| rc=$?` not a bare call: writeShellApplication sets `set -e`, which would
  # abort here on unfinished work and skip both the refusal and the --force path
  rc=0
  SESHY_SESSION=$name agent-review "$session_dir" || rc=$?
  if [ "$rc" -eq 1 ] && [ "$forced" -eq 0 ]; then
    printf '\nsy: refusing to delete an unfinished session.\n' >&2
    printf "sy: use 'sy delete --force %s' to delete anyway.\n" "$name" >&2
    exit 1
  fi
  # rc 2 is permissive on purpose: a broken check must not trap a session
  [ "$rc" -eq 2 ] && printf 'sy: readiness check could not run; continuing.\n' >&2
fi

exec "$SY_REAL" "$sub" "$@"
