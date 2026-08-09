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

session_dir=$("$SY_REAL" path "$name" 2> /dev/null) || session_dir=""
if [ -z "$session_dir" ] || [ ! -d "$session_dir" ]; then
  # sysinit:documented-default
  sg_root=$(sysinit_path seshySessions) || sg_root="$HOME/.local/state/seshy/sessions"
  session_dir="$sg_root/$name"
fi

if [ ! -d "$session_dir" ]; then
  printf 'sy: no session directory for %s; readiness check skipped.\n' "$name" >&2
elif ! command -v agent-review > /dev/null 2>&1; then
  printf 'sy: agent-review is not on PATH; readiness check skipped.\n' >&2
else
  rc=0
  SESHY_SESSION=$name agent-review "$session_dir" || rc=$?
  if [ "$rc" -eq 1 ] && [ "$forced" -eq 0 ]; then
    printf '\nsy: refusing to delete an unfinished session.\n' >&2
    printf "sy: use '%s %s --force' to proceed anyway.\n" "$sub" "$name" >&2
    exit 1
  fi
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 1 ]; then
    printf 'sy: readiness check could not run (exit %s); continuing.\n' "$rc" >&2
  fi
fi

exec "$SY_REAL" "$sub" "$@"
