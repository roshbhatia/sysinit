# Claude Code SessionEnd hook. Reads the session JSON on stdin and appends one
# JSON line to the cross-session worklog — a durable index of every session,
# with `summary` left null for the `worklog` skill to fill in on demand.
#
# Best-effort by design: no `set -e`, every field is guarded so one failure
# (not a git repo, no transcript, no jq) never aborts the append.
#
# Identity lives in `repos[]` — always a list, never a scalar. A plain git cwd
# yields one entry; a seshy session (~/.local/state/seshy/sessions/<name>, whose
# root is NOT a repo but holds one nested worktree per repo) yields one entry
# per nested git child. Each entry carries the branch-tree URL plus the real
# "did work" signal: commits ahead of the base branch and the branch-vs-base
# diffstat — NOT the working-tree diff, which is empty once work is committed.
#
# Append-only and lock-free: a single small `printf >> file` is one O_APPEND
# write(), which the kernel serializes per-inode — safe when several sessions
# end at once. The `worklog` skill is the only rewriter; it merges via a temp
# file, so the worst concurrent-write outcome is one summary recomputed, never
# a corrupted line.

input=$(cat)

log=${CLAUDE_WORKLOG_FILE:-$HOME/Documents/worklog.jsonl}

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
reason=$(printf '%s' "$input" | jq -r '.reason // empty')

# Nothing to index without a session id — bail quietly.
[ -n "$session_id" ] || exit 0

# Skip continuation events. `resume` is a session *start*, not a completion;
# recording it produces a junk line with no work behind it.
[ "$reason" = "resume" ] && exit 0

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

is_git() {
  git -C "$1" rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# Normalize a git remote URL to a browseable https web URL.
#   git@github.com:org/repo.git    -> https://github.com/org/repo
#   ssh://git@github.com/org/repo  -> https://github.com/org/repo
#   https://github.com/org/repo.git-> https://github.com/org/repo
normalize_remote() {
  u=$1
  u=${u%.git}
  case "$u" in
    git@*)
      host=${u#git@}
      host=${host%%:*}
      path=${u#*:}
      printf 'https://%s/%s' "$host" "$path"
      ;;
    ssh://*)
      rest=${u#ssh://}
      rest=${rest#*@}
      printf 'https://%s' "$rest"
      ;;
    *)
      printf '%s' "$u"
      ;;
  esac
}

# Print a JSON object describing the git worktree at $1, or nothing on failure.
# Captures branch-tree URL and the committed-work signal (commits ahead of the
# base branch + branch-vs-base diffstat), plus any uncommitted working-tree
# delta as `dirty`.
git_repo_obj() {
  d=$1
  name=$(basename "$(git -C "$d" rev-parse --show-toplevel 2> /dev/null)")
  [ -n "$name" ] || return 0
  branch=$(git -C "$d" branch --show-current 2> /dev/null)
  head=$(git -C "$d" rev-parse --short HEAD 2> /dev/null)
  dirty=$(git -C "$d" diff --shortstat 2> /dev/null | sed 's/^ *//')

  remote_raw=$(git -C "$d" remote get-url origin 2> /dev/null)
  [ -n "$remote_raw" ] || remote_raw=$(git -C "$d" remote get-url "$(git -C "$d" remote 2> /dev/null | head -1)" 2> /dev/null)
  url=""
  if [ -n "$remote_raw" ]; then
    url=$(normalize_remote "$remote_raw")
    [ -n "$branch" ] && url="$url/tree/$branch"
  fi

  # Base branch (origin's default). When the current branch differs, the real
  # work signal is what this branch adds on top of it.
  base=$(git -C "$d" symbolic-ref refs/remotes/origin/HEAD 2> /dev/null | sed 's#.*/##')
  commits=0
  diffstat=""
  if [ -n "$base" ] && [ -n "$branch" ] && [ "$branch" != "$base" ]; then
    commits=$(git -C "$d" rev-list --count "origin/$base..HEAD" 2> /dev/null)
    [ -n "$commits" ] || commits=0
    diffstat=$(git -C "$d" diff --shortstat "origin/$base...HEAD" 2> /dev/null | sed 's/^ *//')
  fi

  jq -nc \
    --arg name "$name" \
    --arg branch "$branch" \
    --arg head "$head" \
    --arg url "$url" \
    --argjson commits "${commits:-0}" \
    --arg diffstat "$diffstat" \
    --arg dirty "$dirty" \
    '{ name: $name, branch: $branch, head: $head, url: $url, commits: $commits, diffstat: $diffstat, dirty: $dirty }'
}

kind=""
session_name=""
repos_json="[]"

seshy_root="$HOME/.local/state/seshy/sessions"
case "$cwd/" in
  "$seshy_root"/*)
    # cwd is under a seshy session (the root itself or a nested repo). The unit
    # of work is the session, which spans every nested git child.
    kind="seshy-session"
    rest=${cwd#"$seshy_root"/}
    session_name=${rest%%/*}
    session_dir="$seshy_root/$session_name"
    objs=""
    for child in "$session_dir"/*/; do
      [ -d "$child" ] || continue
      is_git "$child" || continue
      obj=$(git_repo_obj "$child")
      [ -n "$obj" ] && objs="${objs}${obj}
"
    done
    [ -n "$objs" ] && repos_json=$(printf '%s' "$objs" | jq -sc '.')
    ;;
  *)
    if [ -n "$cwd" ] && is_git "$cwd"; then
      kind="repo"
      obj=$(git_repo_obj "$cwd")
      [ -n "$obj" ] && repos_json=$(printf '%s' "$obj" | jq -sc '.')
    else
      kind="dir"
    fi
    ;;
esac

# Resolve the transcript. The stdin path is only a hint — on resume it can name
# a uuid whose file never materialized — so prefer it when it exists, else look
# the session up by id under the projects dir, else record nothing.
resolved_transcript=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  resolved_transcript="$transcript"
else
  match=$(ls -t "$HOME"/.claude/projects/*/"$session_id".jsonl 2> /dev/null | head -1)
  [ -n "$match" ] && resolved_transcript="$match"
fi

# First real user prompt: a human-readable title so the rollup can label and
# rank a session without opening its transcript. Non-object lines (summaries),
# tool-result turns, and blanks are skipped; content is a string or text blocks.
first_prompt=""
if [ -n "$resolved_transcript" ] && [ -f "$resolved_transcript" ]; then
  first_prompt=$(jq -rc '
    select(type == "object" and .type == "user")
    | .message.content
    | if type == "string" then .
      elif type == "array" then (map(select(.type == "text") | .text) | join(" "))
      else "" end
  ' "$resolved_transcript" 2> /dev/null | grep -v '^[[:space:]]*$' | head -1 | tr '\n' ' ' | cut -c1-200)
fi

# Zero-signal guard: no repos and no first prompt means nothing worth indexing.
if [ "$repos_json" = "[]" ] && [ -z "$first_prompt" ]; then
  exit 0
fi

line=$(jq -nc \
  --arg ts "$ts" \
  --arg session_id "$session_id" \
  --arg kind "$kind" \
  --arg session_name "$session_name" \
  --arg cwd "$cwd" \
  --arg first_prompt "$first_prompt" \
  --arg transcript "$resolved_transcript" \
  --arg reason "$reason" \
  --argjson repos "$repos_json" \
  '{
    ts: $ts,
    session_id: $session_id,
    kind: $kind,
    session_name: $session_name,
    repos: $repos,
    cwd: $cwd,
    first_prompt: $first_prompt,
    transcript_path: $transcript,
    end_reason: $reason,
    summary: null
  }')

[ -n "$line" ] || exit 0

mkdir -p "$(dirname "$log")"
printf '%s\n' "$line" >> "$log"
