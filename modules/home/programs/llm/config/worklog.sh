# Claude Code SessionEnd hook. Reads the session JSON on stdin and appends one
# JSON line to the cross-session worklog — a durable index of every session,
# with `summary` left null for the `worklog` skill to fill in on demand.
#
# Best-effort by design: no `set -e`, every field is guarded so one failure
# (not a git repo, no transcript, no jq) never aborts the append.
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

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

repo=""
branch=""
head=""
diffstat=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  repo=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2> /dev/null)")
  branch=$(git -C "$cwd" branch --show-current 2> /dev/null)
  head=$(git -C "$cwd" rev-parse --short HEAD 2> /dev/null)
  # Cumulative working-tree delta — a cheap "how much happened" signal for the
  # rollup to rank by; not session-scoped.
  diffstat=$(git -C "$cwd" diff --shortstat 2> /dev/null)
fi
[ -n "$repo" ] || repo=$(basename "${cwd:-unknown}")

# First real user prompt: a human-readable title so the rollup can label and
# rank a session without opening its transcript. Non-object lines (summaries),
# tool-result turns, and blanks are skipped; content is a string or text blocks.
first_prompt=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  first_prompt=$(jq -rc '
    select(type == "object" and .type == "user")
    | .message.content
    | if type == "string" then .
      elif type == "array" then (map(select(.type == "text") | .text) | join(" "))
      else "" end
  ' "$transcript" 2> /dev/null | grep -v '^[[:space:]]*$' | head -1 | tr '\n' ' ' | cut -c1-200)
fi

line=$(jq -nc \
  --arg ts "$ts" \
  --arg session_id "$session_id" \
  --arg repo "$repo" \
  --arg cwd "$cwd" \
  --arg branch "$branch" \
  --arg head "$head" \
  --arg diffstat "$diffstat" \
  --arg first_prompt "$first_prompt" \
  --arg transcript "$transcript" \
  --arg reason "$reason" \
  '{
    ts: $ts,
    session_id: $session_id,
    repo: $repo,
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
