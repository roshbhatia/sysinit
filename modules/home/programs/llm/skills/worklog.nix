''
  # Worklog

  Turns the append-only worklog into a human report: **"what did we accomplish
  today"** across every Claude Code session, spanning all repos. Sessions are
  otherwise isolated; this is the one place their work is collated.

  ## Decision routing

  ```
  How did the user phrase the window?   today (default) | date/range | repo filter | outcomes
  Entry's `summary` is null?            -> drain it (read the transcript, generate, cache back)
  Many entries to drain?                -> fan out one subagent per session
  Transcript missing?                   -> recover by session_id, else infer and prefix summary with `~`
  Window empty?                         -> say so plainly and stop; do not invent activity
  ```

  ## Data source

  A `SessionEnd` hook appends one JSON line per session to
  `~/Documents/worklog.jsonl` (override: `$CLAUDE_WORKLOG_FILE`). The hook is dumb —
  it records pointers and cheap facts, never a summary. It skips `resume` and bare
  directories with no prompt, so every line carries real work. Each line:

  ```json
  {
    "ts": "2026-06-09T21:04:11Z",
    "session_id": "abc123",
    "kind": "repo",
    "session_name": "",
    "repos": [
      {
        "name": "lrl-aws",
        "branch": "dev/roshan/inf-1786/lrl-aws",
        "head": "a0a29123",
        "url": "https://github.com/pinginc/lrl-aws/tree/dev/roshan/inf-1786/lrl-aws",
        "commits": 7,
        "diffstat": "10 files changed, 110 insertions(+), 74 deletions(-)",
        "dirty": ""
      }
    ],
    "cwd": "/Users/roshan/github/...",
    "first_prompt": "fix wezterm tab…",
    "transcript_path": "/Users/.../<uuid>.jsonl",
    "end_reason": "prompt_input_exit",
    "summary": null
  }
  ```

  Git context **always** lives in `repos[]` — there is no scalar `repo`/`branch`/
  `head`. `kind` only selects grouping:

  - **`repo`** — `cwd` was a single git worktree; `repos[]` has one entry.
  - **`seshy-session`** — `cwd` was under a [[feature-based-session-manager]]
    session spanning many repos. Identity is `session_name`; `repos[]` holds one
    entry per nested git child.
  - **`dir`** — neither; `repos[]` is empty (survived only because it had a `first_prompt`).

  Per-repo, `commits` (ahead of base) + `diffstat` (branch-vs-base) are the real
  "how much happened" signal; `dirty` is uncommitted remainder; `url` is the
  branch-tree link. Pre-schema lines have scalar `repo`/`branch`/`head` and no
  `repos[]` — synthesize a single-element `repos[]` and treat missing `kind` as
  `repo`. The transcript is the source of truth; the log line is just the index.

  ## Procedure

  ### 1. Read and filter

  ```bash
  jq -c 'select(.ts >= "2026-06-09")' ~/Documents/worklog.jsonl
  ```

  Parse defensively — skip malformed lines. Dedup by `session_id`, keeping the
  latest `ts`. If the window is empty, say so and stop.

  ### 2. Drain — generate summaries, cache them back

  For each selected entry where `summary` is null, produce a 1–3 sentence "what was
  done" plus concrete artifacts (files, commits, tickets). Read `transcript_path`
  (JSONL) — prefer it over `first_prompt`. If the path is empty or missing, recover
  by `session_id` via `~/.claude/projects/*/<session_id>.jsonl` (Glob) before
  degrading. Only when no transcript exists anywhere, synthesize from
  `first_prompt` + `diffstat` + repo/branch and prefix the summary with `~`. For
  many entries, fan out one subagent per session via the Agent tool.

  Write summaries back so re-runs are cheap. **Rewrite atomically — never edit lines
  in place:**

  ```bash
  # good — merge into a temp file, then atomic swap (a swap-window session loses only its own append)
  jq -c '...apply summaries by session_id...' ~/Documents/worklog.jsonl \
    > ~/Documents/worklog.jsonl.tmp && mv ~/Documents/worklog.jsonl.tmp ~/Documents/worklog.jsonl

  # bad — in-place edit can corrupt the file or drop a concurrent append
  sed -i 's/"summary":null/"summary":"..."/' ~/Documents/worklog.jsonl
  ```

  ### 3. Compose

  Markdown grouped **by date, then unit of work**, newest first. The unit is
  `repos[0].name` for `kind: repo`, and `session_name` for `kind: seshy-session`
  (one heading spanning its `repos[]`, not one per repo). Within a unit, order
  repos by signal (`commits`, then `diffstat` magnitude); link repo names to `url`.

  ```markdown
  ## 2026-06-09

  ### sysinit
  - Slugified Claude tab titles in wezterm and branded with a sparkle. (3 commits, c04e5e0)

  ### inf-1785 (session · lrl-aws, infra, cdk8s-platform-definitions)
  - Reworked the AWS landing-zone modules.
    ([lrl-aws](…/tree/dev/roshan/inf-1786/lrl-aws): 7 commits, +110/-74; infra: 5 commits)

  ### laurel-api
  - ~Investigated the auth refresh races (inferred: transcript pruned).
  ```

  Mark inferred entries with `~`. End with a one-line tally (N sessions across M
  repos). Do not pad thin days — terseness is the point.

  ### 4. Outcomes (only when asked, or when an MCP is connected)

  Map activity to tracked work; join key is **time window + repo + branch**.

  ```
  # good — resolve real status, flag the gaps
  ENG-1234 -> In Progress; branch `rb/no-ticket-fix` has no linked ticket

  # bad — guess a mapping the data does not support
  ENG-1234 -> Done   (asserted with no Linear lookup)
  ```

  - **Linear** — branch names usually carry the ticket id (`rb/ENG-1234-…`); the
    `linear-cli` skill or Linear MCP resolves status.
  - **Notion / Slack** — via their MCP tools, correlate by repo + day.

  ## Guardrails

  - Read-mostly. The only write is caching summaries back via temp-file `mv`.
  - Never delete or reorder existing log entries.
  - Never block on a missing transcript or absent MCP — degrade and note it.
  - Never fabricate accomplishments, commits, or ticket links.
  - Keep summaries factual and terse; this is a work record, not a changelog ad.
''
