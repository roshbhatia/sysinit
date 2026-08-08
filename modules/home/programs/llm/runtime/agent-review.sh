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

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR

examined=0

report_repo() {
  repo_dir="$1"
  repo=$(basename "$repo_dir")
  top=$(git -C "$repo_dir" rev-parse --show-toplevel 2> /dev/null) || return 0
  here=$(cd "$repo_dir" 2> /dev/null && pwd -P) || return 0
  [ "$top" = "$here" ] || return 0
  examined=$((examined + 1))

  branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2> /dev/null) || branch=""
  detached=0
  if [ -z "$branch" ] || [ "$branch" = "HEAD" ]; then
    branch="(detached)"
    detached=1
  fi

  dirty=$(git -C "$repo_dir" status --porcelain 2> /dev/null | grep -c '') || dirty=0

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

  if git -C "$repo_dir" rev-parse --abbrev-ref '@{upstream}' > /dev/null 2>&1; then
    ahead=$(git -C "$repo_dir" rev-list --count '@{upstream}..HEAD' 2> /dev/null) || ahead=0
    upstream="yes"
  elif [ "$detached" -eq 0 ] &&
    git -C "$repo_dir" config --get "branch.$branch.merge" > /dev/null 2>&1; then
    ahead=0
    upstream="gone"
  else
    ahead=0
    upstream="no"
  fi

  problems=""
  [ "$dirty" -gt 0 ] && problems="$problems ${dirty} uncommitted"
  [ "$upstream" = "yes" ] && [ "$ahead" -gt 0 ] && problems="$problems ${ahead} unpushed"
  [ "$detached" -eq 1 ] && problems="$problems detached HEAD"
  [ -n "$midop" ] && problems="$problems mid-$midop"
  [ "$upstream" = "gone" ] && problems="$problems upstream gone"
  others=()
  while IFS= read -r ref; do
    others+=("$ref")
  done < <(git -C "$repo_dir" for-each-ref --format='%(refname)' \
    refs/heads refs/tags refs/remotes 2> /dev/null |
    grep -vFx "refs/heads/$branch")
  if [ "${#others[@]}" -gt 0 ]; then
    local_only=$(git -C "$repo_dir" rev-list --count HEAD --not "${others[@]}" 2> /dev/null) || local_only=0
  else
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

shopt -s dotglob 2> /dev/null || true

for repo_dir in "$root"/*/; do
  [ -d "$repo_dir" ] || continue
  report_repo "$repo_dir"
done

report_repo "$root"

if [ "$examined" -eq 0 ]; then
  printf '  no repository examined; readiness is unknown\n'
  printf '\nsession %s: readiness could not be determined\n' "$session"
  exit 2
fi

wz=$(command -v wezterm 2> /dev/null || true)

if [ -z "$wz" ]; then
  printf '  agents: skipped, the live pane set is unknown outside WezTerm\n'
else
  live=$("$wz" cli list --format json 2> /dev/null | jq -r '.[].pane_id' 2> /dev/null) || live=""
  if [ -z "$live" ]; then
    printf '  agents: skipped, the live pane set could not be read\n'
  else
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
