STATE_DIR="${AGENT_REFINE_STATE_DIR:-$HOME/.local/state/agents/refine}"
WORKLOG="${CLAUDE_WORKLOG_FILE:-$HOME/.local/state/agents/worklog.jsonl}"
MEMORY_ROOT="${AGENT_REFINE_MEMORY_ROOT:-$HOME/.claude/projects}"
WINDOW_DAYS="${AGENT_REFINE_WINDOW_DAYS:-7}"

mkdir -p "$STATE_DIR"

stamp=$(date +%Y-%m-%d)
out="$STATE_DIR/$stamp.md"

if [ ! -s "$WORKLOG" ]; then
  echo "agent-refine: no worklog at $WORKLOG; nothing to refine" >&2
  exit 0
fi

cutoff=$(date -v-"${WINDOW_DAYS}"d +%Y-%m-%d 2> /dev/null || date -d "-${WINDOW_DAYS} days" +%Y-%m-%d)
recent=$(jq -c --arg c "$cutoff" 'select((.ts // .timestamp // "") >= $c)' "$WORKLOG" 2> /dev/null | tail -400)

if [ -z "$recent" ]; then
  echo "agent-refine: no worklog entries since $cutoff; nothing to refine" >&2
  exit 0
fi

memories=$(find "$MEMORY_ROOT" -path '*/memory/*.md' -not -name MEMORY.md 2> /dev/null | head -200)
mem_count=$(printf '%s\n' "$memories" | grep -c . || true)

prompt=$(
  cat << PROMPT
Refine the durable agent memory from evidence. Do not edit any file.

Evidence, last $WINDOW_DAYS days of worklog (JSONL):
$recent

Existing memory files ($mem_count):
$memories

Produce a markdown report with exactly these sections:

Memories the evidence shows are now wrong. Quote the memory and the evidence.

Memories that duplicate each other or restate what the repo already records.

Recurring corrections or constraints in the evidence that no memory captures.
Give the memory name, type, and one-line body you would write.

One line confirming the rest still holds.

Rules: cite evidence for every claim; a claim you cannot cite goes in no section.
Propose only. The owner applies. Never state that something was approved.
PROMPT
)

if ! pi -p "$prompt" > "$out.tmp" 2>&1; then
  echo "agent-refine: pi exited non-zero; leaving $out untouched" >&2
  rm -f "$out.tmp"
  exit 1
fi

if [ ! -s "$out.tmp" ]; then
  echo "agent-refine: pi produced no output" >&2
  rm -f "$out.tmp"
  exit 1
fi

mv -f "$out.tmp" "$out"
echo "agent-refine: wrote $out"

if command -v agent-notify > /dev/null 2>&1; then
  agent-notify claude "done" > /dev/null 2>&1 || true
fi
