# Claude Code SessionEnd hook. Reads the session JSON on stdin and appends one
# JSON line to the cross-session worklog — a durable index of every session,
# with `summary` left null for the `worklog` skill to fill in on demand.
#
# Best-effort by design: no `set -e`, every field is guarded so one failure
# (not a git repo, no transcript, no jq) never aborts the append.
#
# Identity is sourced from the right object. A seshy session root
# (~/.local/state/seshy/sessions/<name>) is NOT a git repo — it holds one
# nested worktree per repo — so we detect it, key on the session name, and
# enumerate the nested repos into `repos[]`. A plain git cwd keeps single-repo
# capture; anything else is a bare dir (and is dropped unless it carries a
# first prompt).
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

# Print a JSON object describing the git worktree at $1, or nothing on failure.
git_repo_obj() {
  d=$1
  r=$(basename "$(git -C "$d" rev-parse --show-toplevel 2> /dev/null)")
  b=$(git -C "$d" branch --show-current 2> /dev/null)
  h=$(git -C "$d" rev-parse --short HEAD 2> /dev/null)
  ds=$(git -C "$d" diff --shortstat 2> /dev/null)
  [ -n "$r" ] || return 0
  jq -nc \
    --arg repo "$r" \
    --arg branch "$b" \
    --arg head "$h" \
    --arg diffstat "$ds" \
    '{ repo: $repo, branch: $branch, head: $head, diffstat: $diffstat }'
}

kind=""
session_name=""
repo=""
branch=""
head=""
diffstat=""
repos_json="[]"

seshy_root="$HOME/.local/state/seshy/sessions"
case "$cwd/" in
  "$seshy_root"/*)
    # cwd is somewhere under a seshy session (the root itself or a nested repo).
    # The unit of work is the session, which spans every nested repo.
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
      repo=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null)")
      branch=$(git -C "$cwd" branch --show-current 2> /dev/null)
      head=$(git -C "$cwd" rev-parse --short HEAD 2> /dev/null)
      # Cumulative working-tree delta — a cheap "how much happened" signal for
      # the rollup to rank by; not session-scoped.
      diffstat=$(git -C "$cwd" diff --shortstat 2> /dev/null)
    else
      kind="dir"
      repo=$(basename "${cwd:-unknown}")
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

# Zero-signal guard: a bare directory with no first prompt carries no work
# worth indexing.
if [ "$kind" = "dir" ] && [ -z "$first_prompt" ]; then
  exit 0
fi

line=$(jq -nc \
  --arg ts "$ts" \
  --arg session_id "$session_id" \
  --arg kind "$kind" \
  --arg session_name "$session_name" \
  --arg repo "$repo" \
  --arg cwd "$cwd" \
  --arg branch "$branch" \
  --arg head "$head" \
  --arg diffstat "$diffstat" \
  --arg first_prompt "$first_prompt" \
  --arg transcript "$resolved_transcript" \
  --arg reason "$reason" \
  --argjson repos "$repos_json" \
  '{
    ts: $ts,
    session_id: $session_id,
    kind: $kind,
    session_name: $session_name,
    repo: $repo,
    repos: $repos,
    cwd: $cwd,
    branch: $branch,
    head: $head,
    diffstat: $diffstat,
    first_prompt: $first_prompt,
    transcript_path: $transcript,
    end_reason: $reason,
    summary: null
  }')

[ -n "$line" ] || exit 0

mkdir -p "$(dirname "$log")"
printf '%s\n' "$line" >> "$log"
