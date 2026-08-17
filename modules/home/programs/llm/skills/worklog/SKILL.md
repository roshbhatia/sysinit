---
description: Generates a cross-session work report from worklog.jsonl, digested per day and per repo. Use when the user asks what they worked on or accomplished recently, or wants a daily or weekly progress report spanning repos.
allowed-tools: Read Write Edit Glob Bash(bash:*) Bash(jq:*) Bash(git:*) Agent
---

# Worklog

Turns the append-only worklog into a human report: **"what did we accomplish
today"** across every Claude Code session, spanning all repos. Sessions are
otherwise isolated; this is the one place their work is collated.

## Decision routing

```
How did the user phrase the window?   today (default) | date/range | repo filter | outcomes
Entry's `summary` is null?            -> drain it (read the transcript, generate, cache back)
Many entries to drain?                -> fan out one {{agent}} per session
Transcript missing?                   -> recover by session_id, else infer and prefix summary with `~`
Window empty?                         -> say so plainly and stop; do not invent activity
```

## Data source

A `SessionEnd` hook appends one JSON line per session to
`~/.local/state/agents/worklog.jsonl`. The hook is a PEP-723 Python script,
`harnesses/claude/worklog-hook.py`, run via uv. `$CLAUDE_WORKLOG_FILE`
overrides the path. The hook is dumb, it records pointers and cheap facts,
never a summary. It skips `resume` and bare directories with no prompt, so every
line carries real work. A **schema v2** line:

```json
{
  "v": 2,
  "ts": "2026-06-09T21:47:03Z",
  "ts_start": "2026-06-09T21:04:11.512Z",
  "duration_min": 42,
  "session_id": "abc123",
  "kind": "repo",
  "session_name": "",
  "model": "claude-opus-4-8",
  "user_turns": 7,
  "repos": [
    {
      "name": "sysinit",
      "branch": "dev/rshnbhatia/wezterm-tabs/sysinit",
      "head": "a0a29123",
      "base": "main",
      "url": "https://github.com/roshbhatia/sysinit/tree/dev/rshnbhatia/wezterm-tabs/sysinit",
      "commits_ahead": 7,
      "commits": [{ "sha": "a0a2912", "subject": "feat: slugify wezterm tab titles" }],
      "files": [{ "status": "M", "path": "modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua" }],
      "insertions": 110,
      "deletions": 74,
      "diffstat": "10 files changed, 110 insertions(+), 74 deletions(-)",
      "dirty": ""
    }
  ],
  "cwd": "/Users/rshnbhatia/github/...",
  "first_prompt": "fix wezterm tab…",
  "last_prompt": "ship it and open the PR",
  "transcript_path": "/Users/.../<uuid>.jsonl",
  "end_reason": "prompt_input_exit",
  "summary": null
}
```

Git context **always** lives in `repos[]`, there is no scalar `repo`/`branch`/
`head`. `kind` only selects grouping:

- `repo`, `cwd` was a single git worktree; `repos[]` has one entry.
- `seshy-session`, `cwd` was under a seshy session (see the
  `feature-based-session-manager` skill) spanning many repos. Identity is
  `session_name`; `repos[]` holds one entry per nested git child.
- `dir`, neither; `repos[]` is empty (survived only because it had a `first_prompt`).

**Session signal** (v2): `duration_min`, `user_turns`, and `model` size the
effort; `first_prompt`/`last_prompt` bracket the intent (where it started, where
it ended). **Per-repo signal**. `commits[]` holds subjects, at most 30, newest
first, and `files[]` holds name-status, at most 50. Those two are *what changed
in words*. `commits_ahead`, `insertions`, `deletions`, and `diffstat` are *how
much*. All are measured against `base`, which is `origin/<base>` for a feature
branch and `origin/<branch>` when on the base branch. So work committed
straight to main still registers. `dirty` is the uncommitted
remainder; `url` is the branch-tree link. The raw diff is **not** stored, read
the transcript or follow `url` when you need it.

The log spans schema generations v0, v1, and v2. The query script below
normalizes every line to the v2 shape. Older lines simply lack the rich fields:
`commits[]`, `files[]`, `insertions`, `deletions`, and `base`. Never read or
write `worklog.jsonl` with hand-rolled `jq`; all I/O goes through the script.

The transcript is the source of truth; the log line is just the index.

## Procedure

All worklog I/O runs through the deterministic helper shipped with this skill:

```bash
Q=~/.claude/skills/worklog/scripts/worklog-query.sh
```

### 1. Read and filter

```bash
bash "$Q" list --since 2026-06-09 [--until TS] [--repo NAME]     # normalized entries, newest first
bash "$Q" pending --since 2026-06-09                             # the subset still needing a summary
```

The script skips malformed lines, dedups by `session_id` (latest `ts` wins),
and normalizes old schema generations. If the window is empty, say so and stop.

### 2. Drain: generate summaries, cache them back

For each `pending` entry, produce a 1–3 sentence "what was done" plus concrete
artifacts (files, commits, tickets). Read `transcript_path` (JSONL), prefer it
over `first_prompt`. If the path is empty or missing, recover by `session_id`
via `~/.claude/projects/*/<session_id>.jsonl` (Glob) before degrading. Only
when no transcript exists anywhere, synthesize from the line itself. Read
`first_prompt` and `last_prompt` for intent. Read `commits[]` and `files[]`, or
`diffstat` on older lines, for the change. Prefix the summary with `~`. For many
entries, fan out one {{agent}} per session via the Agent tool.

Cache summaries back through the script, it fills only null summaries and
rewrites via temp-file + atomic `mv`:

```bash
# good — write {"<session_id>": "<summary>", ...} to a temp file, then:
bash "$Q" apply /tmp/summaries.json

# bad — in-place edit can corrupt the file or drop a concurrent append
sed -i 's/"summary":null/"summary":"..."/' ~/.local/state/agents/worklog.jsonl
```

### 3. Compose

Markdown grouped **by date, then unit of work**, newest first. The unit is
`repos[0].name` for `kind: repo`, and `session_name` for `kind: seshy-session`
(one heading spanning its `repos[]`, not one per repo). Within a unit, order
repos by signal (`commits_ahead`, then `insertions` + `deletions`); link repo
names to `url`.

```markdown
## 2026-06-09

### sysinit
- Slugified Claude tab titles in wezterm and branded with a sparkle. (3 commits, c04e5e0)

### wezterm-tabs (session · sysinit, neph.nvim)
- Reworked the wezterm tab-title rendering.
  ([sysinit](…/tree/dev/rshnbhatia/wezterm-tabs/sysinit): 7 commits, +110/-74; neph.nvim: 5 commits)

### finances
- ~Investigated the transaction sync races (inferred: transcript pruned).
```

Mark inferred entries with `~`. End with a one-line tally (N sessions across M
repos). Do not pad thin days, terseness is the point.

### 4. Outcomes (only when asked, or when an MCP is connected)

Map activity to tracked work; join key is **time window + repo + branch**.

```
# good — resolve real status, flag the gaps
ENG-1234 -> In Progress; branch `rb/no-ticket-fix` has no linked ticket

# bad — guess a mapping the data does not support
ENG-1234 -> Done   (asserted with no Linear lookup)
```

- Linear, branch names usually carry the ticket id (`rb/ENG-1234-…`); the
  `linear-cli` skill or Linear MCP resolves status.
- Notion / Slack, via their MCP tools, correlate by repo + day.

## Guardrails

- Read-mostly. The only write is caching summaries back via `worklog-query.sh apply`.
- Never read or write `worklog.jsonl` directly, the query script is the only I/O path.
- Never delete or reorder existing log entries.
- Never block on a missing transcript or absent MCP, degrade and note it.
- Never fabricate accomplishments, commits, or ticket links.
- Keep summaries factual and terse; this is a work record, not a changelog ad.
