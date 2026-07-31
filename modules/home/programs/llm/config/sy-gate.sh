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
# seshy is NOT Nix-managed on this machine; it installs itself to
# ~/.local/bin/sy. The Nix profile sits ahead of that on PATH (position 2 versus
# 11), which is what lets this gate shadow it. So the real binary is found by
# scanning PATH for an `sy` outside the Nix store rather than baked in.
sy_real() {
  if [ -n "${SY_REAL:-}" ] && [ -x "$SY_REAL" ]; then
    printf '%s' "$SY_REAL"
    return 0
  fi
  _ifs=$IFS
  IFS=:
  for _d in $PATH; do
    case "$_d" in
      /nix/store/* | /etc/profiles/*) continue ;;
    esac
    if [ -x "$_d/sy" ]; then
      IFS=$_ifs
      printf '%s' "$_d/sy"
      return 0
    fi
  done
  IFS=$_ifs
  return 1
}

SY_REAL=$(sy_real) || {
  printf 'sy: cannot find the seshy binary outside the Nix store\n' >&2
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
