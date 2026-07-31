# agent-review: is this seshy session finished?
#
# Reports one session's readiness from data that is free to read: git state per
# repository, and the agent state the per-pane bus already carries. Prints a
# line per repository and exits non-zero when anything is unfinished, so
# seshy's preDelete hook can gate on it.
#
# Usage: agent-review [session-path]
#   Falls back to $SESHY_SESSION_PATH, then to $PWD. seshy sets SESHY_SESSION,
#   SESHY_SESSION_PATH, SESHY_REPOS, SESHY_REPO_COUNT, and SESHY_EVENT for its
#   hooks; confirmed against the installed binary.
#
# Exit codes:
#   0  ready, nothing unfinished
#   1  unfinished work found; the reasons are printed
#   2  the check could not run (bad path, no git). The gate treats this as
#      permissive: a report that cannot run must never make a session
#      undeletable.
#
# Deliberately does NOT run a build or a test suite. This sits on the path of an
# interactive command, and a multi-minute check there would train the owner to
# reach for `--force` every time, which destroys the gate.
#
# Never writes. It does not commit, push, stash, or merge. Unfinished work is
# the owner's decision.

root=${1:-${SESHY_SESSION_PATH:-$PWD}}
session=${SESHY_SESSION:-$(basename "$root")}

if [ ! -d "$root" ]; then
  printf 'agent-review: %s is not a directory; skipping the readiness check\n' "$root" >&2
  exit 2
fi

command -v git > /dev/null 2>&1 || {
  printf 'agent-review: git is not on PATH; skipping the readiness check\n' >&2
  exit 2
}

unfinished=0

printf 'session %s\n' "$session"

# --- per-repository git state -------------------------------------------------
# One level down from the session root is a repository checkout, which is the
# layout seshy creates. A directory without .git is not ours to judge.
for repo_dir in "$root"/*/; do
  [ -d "$repo_dir" ] || continue
  repo=$(basename "$repo_dir")
  git -C "$repo_dir" rev-parse --git-dir > /dev/null 2>&1 || continue

  branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2> /dev/null) || branch=""
  [ -n "$branch" ] || branch="(detached)"

  dirty=$(git -C "$repo_dir" status --porcelain 2> /dev/null | grep -c '') || dirty=0

  # A branch with no upstream has no answer to "how many commits are unpushed",
  # so say that rather than print a zero the owner would read as "pushed".
  if git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' > /dev/null 2>&1; then
    ahead=$(git -C "$repo_dir" rev-list --count '@{upstream}..HEAD' 2> /dev/null) || ahead=0
    upstream="yes"
  else
    ahead=0
    upstream="no"
  fi

  # Blocking conditions only. A branch with no upstream is NOT one: seshy
  # creates every session branch without one, so treating it as unfinished
  # would refuse the most common delete on this machine and train the owner to
  # reach for --force, which is the habit this gate exists to prevent.
  problems=""
  [ "$dirty" -gt 0 ] && problems="$problems ${dirty} uncommitted"
  [ "$upstream" = "yes" ] && [ "$ahead" -gt 0 ] && problems="$problems ${ahead} unpushed"

  # Informational, printed either way so the owner still sees it.
  note=""
  [ "$upstream" = "no" ] && note=" (no upstream)"

  if [ -n "$problems" ]; then
    unfinished=1
    printf '  %-24s %-28s%s%s\n' "$repo" "$branch" "$problems" "$note"
  else
    printf '  %-24s %-28s clean%s\n' "$repo" "$branch" "$note"
  fi
done

# --- live agent state ---------------------------------------------------------
# A state file records that a pane HELD a state, not that the pane still exists.
# Intersect with the live pane set, and when that set cannot be determined skip
# the input entirely: assuming liveness would turn one crashed session into a
# permanent blocker.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/agents/panes"
wz=$(command -v wezterm 2> /dev/null || true)

if [ -z "$wz" ]; then
  printf '  agents: skipped, the live pane set is unknown outside WezTerm\n'
elif [ -d "$state_dir" ]; then
  live=$("$wz" cli list --format json 2> /dev/null | jq -r '.[].pane_id' 2> /dev/null) || live=""
  if [ -z "$live" ]; then
    printf '  agents: skipped, the live pane set could not be read\n'
  else
    busy=0
    for f in "$state_dir"/*.json; do
      [ -f "$f" ] || continue
      pane=$(basename "$f" .json)
      printf '%s\n' "$live" | grep -qx "$pane" || continue

      read -r st ag sess <<< "$(jq -r '[.status // "", .agent // "", .session // ""] | @tsv' "$f" 2> /dev/null)"
      # Only this session's panes, and only states above idle.
      [ "$sess" = "$session" ] || continue
      case "$st" in
        working | waiting | done)
          busy=1
          unfinished=1
          printf '  pane %-19s %-28s %s is %s\n' "$pane" "" "$ag" "$st"
          ;;
      esac
    done
    [ "$busy" -eq 0 ] && printf '  agents: none active in this session\n'
  fi
fi

if [ "$unfinished" -ne 0 ]; then
  printf '\nsession %s is not finished\n' "$session"
  exit 1
fi

printf '\nsession %s is ready\n' "$session"
exit 0
