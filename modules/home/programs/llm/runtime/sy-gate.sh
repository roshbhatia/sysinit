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

# A bare `sy delete` used to exec straight through, so the picker form bypassed the
# gate completely. Do the pick here and fall through to the named path. On cancel,
# an empty pick, or no fzf, exec unchanged: this gate never traps a session.
if [ -z "$name" ]; then
  if command -v fzf > /dev/null 2>&1; then
    picked=$("$SY_REAL" list --names 2> /dev/null | fzf --prompt 'delete session> ' --height 40%) || picked=""
    if [ -n "$picked" ]; then
      name=$picked
      set -- "$picked" "$@"
    else
      exec "$SY_REAL" "$sub" "$@"
    fi
  else
    printf 'sy: fzf is unavailable, so the readiness check cannot see the pick.\n' >&2
    exec "$SY_REAL" "$sub" "$@"
  fi
fi

# `|| session_dir=""` not a bare assignment: `sy path` exits non-zero for a name
# it cannot resolve, and writeShellApplication sets `set -e`, so a bare assignment
# aborts the wrapper here. stderr is discarded, so the owner would see nothing at
# all and `sy delete` would be a silent no-op for that name. Verified: `sy path
# definitely-not-a-session` exits 1.
session_dir=$("$SY_REAL" path "$name" 2> /dev/null) || session_dir=""
if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
  session_dir="$HOME/.local/state/seshy/sessions/$name"
fi

if [ ! -d "$session_dir" ]; then
  # Say so rather than deleting silently: the owner has every reason to think the
  # gate ran. Permissive by D3, but never quiet.
  printf 'sy: no session directory for %s; readiness check skipped.\n' "$name" >&2
elif ! command -v agent-review > /dev/null 2>&1; then
  printf 'sy: agent-review is not on PATH; readiness check skipped.\n' >&2
else
  # `|| rc=$?` not a bare call: writeShellApplication sets `set -e`, which would
  # abort here on unfinished work and skip both the refusal and the --force path
  rc=0
  SESHY_SESSION=$name agent-review "$session_dir" || rc=$?
  if [ "$rc" -eq 1 ] && [ "$forced" -eq 0 ]; then
    printf '\nsy: refusing to delete an unfinished session.\n' >&2
    printf "sy: use '%s %s --force' to proceed anyway.\n" "$sub" "$name" >&2
    exit 1
  fi
  # Permissive on purpose for every non-blocking code: a broken check must not trap
  # a session. But it must never be silent, so this covers 2 and anything else,
  # including the 127 a missing sourced helper would produce.
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ]; then
    printf 'sy: readiness check could not run (exit %s); continuing.\n' "$rc" >&2
  fi
fi

exec "$SY_REAL" "$sub" "$@"
