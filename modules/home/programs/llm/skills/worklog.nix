''
  # Worklog

  Turns the append-only worklog into a human report: **"what did we accomplish
  today"** across every Claude Code session, spanning all repos. Sessions are
  otherwise isolated; this is the one place their work is collated.

  ## Data source

  A `SessionEnd` hook appends one JSON line per session to
  `~/Documents/worklog.jsonl` (override: `$CLAUDE_WORKLOG_FILE`). The hook is
  dumb — it records pointers and cheap facts, never a summary. It skips
  `resume` (a session start, not a completion) and bare directories with no
  prompt, so every line carries real work. Each line:

  ```json
  {
    "ts": "2026-06-09T21:04:11Z",      // session end, UTC ISO-8601
    "session_id": "abc123",
    "kind": "repo",                     // repo | seshy-session | dir
    "session_name": "",                 // seshy session name (seshy-session only)
    "repos": [                          // ALWAYS a list — git context lives here
      {
        "name": "lrl-aws",
        "branch": "dev/roshan/inf-1786/lrl-aws",
        "head": "a0a29123",
        "url": "https://github.com/pinginc/lrl-aws/tree/dev/roshan/inf-1786/lrl-aws",
        "commits": 7,                   // ahead of base branch — the "did work" signal
        "diffstat": "10 files changed, 110 insertions(+), 74 deletions(-)", // branch-vs-base
        "dirty": ""                     // uncommitted working-tree delta, if any
      }
    ],
    "cwd": "/Users/roshan/github/...",
    "first_prompt": "fix wezterm tab…", // cheap title, first user turn
    "transcript_path": "/Users/.../<uuid>.jsonl",
    "end_reason": "prompt_input_exit",  // clear | logout | prompt_input_exit | …
    "summary": null                     // YOU fill this — see Drain
  }
  ```

  Git context **always** lives in `repos[]` — there is no scalar `repo`/`branch`/
  `head`. `kind` only selects how to group:

  - **`repo`** — `cwd` was a single git worktree; `repos[]` has exactly one entry.
  - **`seshy-session`** — `cwd` was under a [[feature-based-session-manager]]
    session, which spans many repos. Identity is `session_name`; `repos[]` holds
    one entry per nested git child of the session.
  - **`dir`** — neither a repo nor a seshy session; `repos[]` is empty (the line
    only survives the hook's zero-signal guard because it had a `first_prompt`).

  Per-repo, `commits` (ahead of the base branch) + `diffstat` (branch-vs-base)
  are the real "how much happened" signal — committed work the old working-tree
  diff missed; `dirty` is any uncommitted remainder. `url` is the branch-tree
  web link.

  Lines written before this schema have a scalar `"repo"`/`"branch"`/`"head"`/
  `"diffstat"` and no `repos[]` — synthesize a single-element `repos[]` from
  them and treat a missing `kind` as `repo`. `summary` is pre-seeded `null`. The
  transcript at `transcript_path` is the source of truth for what actually
  happened; the log line is just the index.

  ## Modes

  Pick from how the user phrased the ask; default to **today**.

  - **today** (default) — entries whose `ts` is the current local date.
  - **date / range** — "yesterday", "this week", "since Monday", "2026-06-01".
  - **repo filter** — "what did I do in sysinit this week".
  - **outcomes** — additionally map work to Linear / Notion / Slack (below).

  ## Procedure

  ### 1. Read and filter

  Read the log and select the window. Parse defensively — skip malformed lines.

  ```bash
  jq -c 'select(.ts >= "2026-06-09")' ~/Documents/worklog.jsonl
  ```

  Dedup by `session_id`, keeping the latest `ts` (a session that was `/clear`ed
  and resumed emits several lines). If the window is empty, say so plainly and
  stop — do not invent activity.

  ### 2. Drain (generate the agent summaries, cache them back)

  For each selected entry where `summary` is `null`, produce a 1–3 sentence
  "what was done" plus the concrete artifacts (files touched, commits, tickets).

  - Read `transcript_path` (JSONL, one turn per line). It is the real record —
    prefer it over `first_prompt`. If the path is empty or the file is
    **missing**, try to recover it by `session_id` first —
    `~/.claude/projects/*/<session_id>.jsonl` (Glob) — before degrading. Only
    when no transcript exists anywhere, synthesize from `first_prompt` +
    `diffstat` + repo/branch and prefix the summary with `~` (inferred).
  - For commits, iterate `repos[]`: each entry's `commits`/`diffstat` already
    quantify the branch-vs-base work, and `head`/`branch`/`url` locate it. To
    list them, run `git -C "$dir" log --oneline` against the repo dir — `$cwd`
    for `kind: repo`, or `~/.local/state/seshy/sessions/<session_name>/<name>`
    per entry for a `seshy-session`.
  - **Many entries → fan out.** Spawn one subagent per session via the Agent
    tool (they are independent); have each return its summary. Keep summaries
    factual and terse — no marketing, no padding.

  Write each summary back into the log so re-runs are cheap (this is the
  generate-on-first-read cache). **Rewrite safely** — never edit lines in place:

  ```bash
  # merge updates into a temp file, then atomically swap
  jq -c '...apply summaries by session_id...' ~/Documents/worklog.jsonl \
    > ~/Documents/worklog.jsonl.tmp && mv ~/Documents/worklog.jsonl.tmp ~/Documents/worklog.jsonl
  ```

  The `mv` is atomic. A session ending in the brief read→swap window loses only
  that one append (recovered on the next drain); lines are never corrupted.

  ### 3. Compose

  Emit markdown grouped **by date, then unit of work**, newest first. The unit
  is the single `repos[0].name` for `kind: repo`, and the `session_name` for
  `kind: seshy-session` (one heading spanning its `repos[]`, not one per repo).
  Within a unit, order repos by signal (`commits`, then `diffstat` magnitude);
  link repo names to their `url` when present. Keep it skimmable:

  ```markdown
  ## 2026-06-09

  ### sysinit
  - Slugified Claude tab titles in wezterm and branded with a sparkle;
    disabled tabline rendering so sigil titles show. (3 commits, c04e5e0)
  - Added a session-aware statusline and a cross-session worklog hook.

  ### inf-1785 (session · lrl-aws, infra, cdk8s-platform-definitions)
  - Reworked the AWS landing-zone modules and threaded the change into infra.
    ([lrl-aws](…/tree/dev/roshan/inf-1786/lrl-aws): 7 commits, +110/-74;
    infra: 5 commits)

  ### laurel-api
  - ~Investigated the auth refresh races (inferred: transcript pruned).
  ```

  Mark inferred entries with `~`. End with a one-line tally (N sessions across M
  repos). Do not pad thin days — terseness is the point.

  ### 4. Outcomes (only when asked, or when an MCP is connected)

  Map activity to tracked work. The join key is **time window + repo + branch**:

  - **Linear** — branch names usually carry the ticket id (`rb/ENG-1234-…`); the
    `linear-cli` skill or the Linear MCP resolves status. Report "ENG-1234 →
    In Progress", flag work with no obvious ticket.
  - **Notion / Slack** — via their MCP tools, correlate by repo + day to surface
    related docs or messages you sent in the window.

  Never fabricate a mapping. If a branch encodes no ticket and none is connected,
  say "no linked ticket" rather than guessing.

  ## Guardrails

  - Read-mostly. The only write is caching summaries back via temp-file `mv`.
  - Never delete or reorder existing log entries.
  - Never block on a missing transcript or absent MCP — degrade and note it.
  - Don't fabricate accomplishments, commits, or ticket links.
  - Keep summaries factual and terse; this is a work record, not a changelog ad.
''
