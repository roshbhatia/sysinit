# Is this seshy session finished? Reports git state per repo plus any live agent
# pane. Read by the `sy` delete gate.
#
# Usage: agent-review [session-path]   (else $SESHY_SESSION_PATH, else $PWD)

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
# Ambient git environment must not leak in: a hook or `rebase --exec` exports
# these, and `rev-parse --show-toplevel` would then answer about the ambient repo
# so every candidate mismatches and the session reports ready.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR

examined=0

report_repo() {
  repo_dir="$1"
  repo=$(basename "$repo_dir")
  # A repository ROOT, not any directory inside one: `rev-parse --git-dir` walks
  # upward, so without this every top-level directory of a repo reports as its own
  # repository carrying that repo's dirty count.
  top=$(git -C "$repo_dir" rev-parse --show-toplevel 2> /dev/null) || return 0
  here=$(cd "$repo_dir" 2> /dev/null && pwd -P) || return 0
  [ "$top" = "$here" ] || return 0
  examined=$((examined + 1))

  # `rev-parse --abbrev-ref HEAD` prints the literal "HEAD" on a detached head and
  # exits 0, so an empty-string test never fires. agent-identity.sh:48 already
  # normalises it the same way.
  branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2> /dev/null) || branch=""
  detached=0
  if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
    branch="(detached)"
    detached=1
  fi

  dirty=$(git -C "$repo_dir" status --porcelain 2> /dev/null | grep -c '') || dirty=0

  # A paused rebase, merge, or cherry-pick keeps its state in the gitdir, where
  # `status --porcelain` reports nothing. Deleting the worktree then discards every
  # commit the operation had already applied.
  midop=""
  for marker in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD sequencer/todo; do
    gp=$(git -C "$repo_dir" rev-parse --git-path "$marker" 2> /dev/null) || continue
    case "$gp" in
      /*) : ;;
      *) gp="$repo_dir/$gp" ;;
    esac
    if [ -e "$gp" ]; then
      midop="$marker"
      break
    fi
  done

  # no upstream means "unpushed" has no answer, so do not print a misleading 0
  if git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' > /dev/null 2>&1; then
    ahead=$(git -C "$repo_dir" rev-list --count '@{upstream}..HEAD' 2> /dev/null) || ahead=0
    upstream="yes"
  elif [ "$detached" -eq 0 ] &&
    git -C "$repo_dir" config --get "branch.$branch.merge" > /dev/null 2>&1; then
    # Configured but unresolvable: the remote-tracking ref is gone, which
    # `fetch.prune` makes routine after a merge-and-delete. Local commits may exist
    # nowhere else, so this must not take the benign carve-out below.
    ahead=0
    upstream="gone"
  else
    ahead=0
    upstream="no"
  fi

  # No upstream is NOT blocking: seshy creates every session branch without one,
  # so blocking would refuse the most common delete.
  problems=""
  [ "$dirty" -gt 0 ] && problems="$problems ${dirty} uncommitted"
  [ "$upstream" = "yes" ] && [ "$ahead" -gt 0 ] && problems="$problems ${ahead} unpushed"
  # A detached head is not a branch: commits are reachable only from this
  # worktree's HEAD, so removing the worktree makes them collectable. The
  # no-upstream carve-out below was written for a seshy-created branch and must
  # not launder this case into "clean".
  [ "$detached" -eq 1 ] && problems="$problems detached HEAD"
  [ -n "$midop" ] && problems="$problems mid-$midop"
  [ "$upstream" = "gone" ] && problems="$problems upstream gone"
  # The other refs are enumerated rather than excluded by pattern: verified that
  # `rev-list --not --exclude=refs/heads/<branch> --branches` counts 0 here, so the
  # pattern form silently measures nothing.
  others=()
  while IFS= read -r ref; do
    others+=("$ref")
  done < <(git -C "$repo_dir" for-each-ref --format='%(refname)' \
    refs/heads refs/tags refs/remotes 2> /dev/null |
    grep -vFx "refs/heads/$branch")
  if [ "${#others[@]}" -gt 0 ]; then
    local_only=$(git -C "$repo_dir" rev-list --count HEAD --not "${others[@]}" 2> /dev/null) || local_only=0
  else
    # No other ref at all, so everything on HEAD is reachable from nowhere else.
    local_only=$(git -C "$repo_dir" rev-list --count HEAD 2> /dev/null) || local_only=0
  fi
  case "$local_only" in
    '' | *[!0-9]*) local_only=0 ;;
  esac
  [ "$local_only" -gt 0 ] && problems="$problems ${local_only} commits nowhere else"

  note=""
  [ "$upstream" = "no" ] && note=" (no upstream)"

  if [ -n "$problems" ]; then
    unfinished=1
    printf '  %-24s %-28s%s%s\n' "$repo" "$branch" "$problems" "$note"
  else
    printf '  %-24s %-28s clean%s\n' "$repo" "$branch" "$note"
  fi
}

# A dot-named repo is invisible to `*/` but the delete path removes it anyway, so
# it must be inspected. `.git` and friends fail the repository-root test below.
shopt -s dotglob 2> /dev/null || true

for repo_dir in "$root"/*/; do
  [ -d "$repo_dir" ] || continue
  report_repo "$repo_dir"
done

# `$root` itself may be the repository: the documented no-argument form is run
# from inside one. Before this, that input examined nothing and reported ready.
report_repo "$root"

if [ "$examined" -eq 0 ]; then
  printf '  no repository examined; readiness is unknown\n'
  printf '\nsession %s: readiness could not be determined\n' "$session"
  exit 2
fi

# --- live agent state ---------------------------------------------------------
# A state file records that a pane held a state, not that it still exists. Skip
# the input entirely when the live set is unknown: assuming liveness would turn
# one crashed session into a permanent blocker.
wz=$(command -v wezterm 2> /dev/null || true)

if [ -z "$wz" ]; then
  printf '  agents: skipped, the live pane set is unknown outside WezTerm\n'
else
  live=$("$wz" cli list --format json 2> /dev/null | jq -r '.[].pane_id' 2> /dev/null) || live=""
  if [ -z "$live" ]; then
    printf '  agents: skipped, the live pane set could not be read\n'
  else
    # The intersection lives in a sourced helper so the flake check can drive it
    # with a fixed live set. wezterm cannot be stubbed here: writeShellApplication
    # prepends its runtimeInputs to PATH, so the real binary always wins.
    # Only 1 means busy. Any other non-zero is the helper itself failing, and this
    # gate fails OPEN by design (D3): treating a missing helper or a jq error as
    # "unfinished" would refuse every delete with no way to tell why.
    bp=0
    agent_busy_panes "$session" "$live" || bp=$?
    case "$bp" in
      0) printf '  agents: none active in this session\n' ;;
      1) unfinished=1 ;;
      *) printf '  agents: skipped, the state reader failed\n' ;;
    esac
  fi
fi

if [ "$unfinished" -ne 0 ]; then
  printf '\nsession %s is not finished\n' "$session"
  exit 1
fi

printf '\nsession %s is ready\n' "$session"
exit 0
