# Periodic harness refinement, modelled on prime-agent's Continual Harness.
#
# prime-agent (which is itself built on pi) separates an immutable base prompt
# from durable supplemental state — memories, skills, subagent specs — and
# refines that state from evidence rather than rewriting the prompt. This is the
# same split this configuration already has: `instructions.nix` is Nix-owned and
# immutable at runtime, while `~/.claude/projects/*/memory/` accumulates.
# Nothing was refining the mutable half, so it only ever grew.
#
# It PROPOSES and never applies. The owner's own responsibility rules say model
# output is a draft until evidence verifies it, and that approval is never
# claimed on their behalf; a job that edited memory unattended would do both.
# Output is one reviewable markdown file per run.

STATE_DIR="${AGENT_REFINE_STATE_DIR:-$HOME/.local/state/agents/refine}"
WORKLOG="${CLAUDE_WORKLOG_FILE:-$HOME/.local/state/agents/worklog.jsonl}"
MEMORY_ROOT="${AGENT_REFINE_MEMORY_ROOT:-$HOME/.claude/projects}"
WINDOW_DAYS="${AGENT_REFINE_WINDOW_DAYS:-7}"

mkdir -p "$STATE_DIR"

# `date` is the only clock here, so the output name is the run identity. A second
# run on the same day overwrites rather than accumulating near-duplicates.
stamp=$(date +%Y-%m-%d)
out="$STATE_DIR/$stamp.md"

if [ ! -s "$WORKLOG" ]; then
  echo "agent-refine: no worklog at $WORKLOG; nothing to refine" >&2
  exit 0
fi

# Bound the evidence to the window. Feeding the whole worklog would make every
# run re-propose the same things and cost more each time.
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

## Contradicted
Memories the evidence shows are now wrong. Quote the memory and the evidence.

## Redundant
Memories that duplicate each other or restate what the repo already records.

## Missing
Recurring corrections or constraints in the evidence that no memory captures.
Give the memory name, type, and one-line body you would write.

## Leave alone
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

# A run that produced nothing is a failed run, not an empty report.
if [ ! -s "$out.tmp" ]; then
  echo "agent-refine: pi produced no output" >&2
  rm -f "$out.tmp"
  exit 1
fi

mv -f "$out.tmp" "$out"
echo "agent-refine: wrote $out"

# Positional, not flags: agent-notify takes `<agent> <reason> [focus-exe]`. An
# earlier version here passed `--agent claude --reason ...`, which set agent to
# the literal "--agent" and fell through to the generic "needs your attention"
# branch. It notified, so it looked wired, but said nothing useful.
if command -v agent-notify > /dev/null 2>&1; then
  # `done` quoted: unquoted, shellcheck reads it as the loop keyword (SC1010).
  agent-notify claude "done" > /dev/null 2>&1 || true
fi
