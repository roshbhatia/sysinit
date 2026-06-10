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
    "repo": "sysinit",                  // single-repo: basename of git toplevel
    "repos": [],                        // seshy-session: one obj per nested repo
    "cwd": "/Users/roshan/github/...",
    "branch": "rb/ENG-1234-tabs",       // single-repo: bridge to a tracker ticket
    "head": "c04e5e0e9",                // single-repo: short HEAD sha
    "diffstat": "3 files changed, ...", // single-repo: working-tree delta
    "first_prompt": "fix wezterm tab…", // cheap title, first user turn
    "transcript_path": "/Users/.../<uuid>.jsonl",
    "end_reason": "prompt_input_exit",  // clear | logout | prompt_input_exit | …
    "summary": null                     // YOU fill this — see Drain
  }
  ```

  `kind` selects where the git context lives:

  - **`repo`** — `cwd` was a single git worktree; read `repo`/`branch`/`head`/
    `diffstat` at the top level.
  - **`seshy-session`** — `cwd` was a [[feature-based-session-manager]] session
    root, which spans many repos. Identity is `session_name`; per-repo context
    is in `repos[]` (each `{repo, branch, head, diffstat}`). Top-level
    `repo`/`branch`/`head` are empty — use `repos[]`.
  - **`dir`** — neither; only `repo` (the cwd basename) is set.

  Lines written before this schema lack `kind`/`repos` — treat a missing `kind`
  as `repo`. `summary` is pre-seeded `null`. The transcript at `transcript_path`
  is the source of truth for what actually happened; the log line is just the
  index.

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
  - For commits, run `git -C "$cwd" log --oneline "$head"..HEAD` (or around the
    session window) when the repo still exists. For a `seshy-session`, iterate
    `repos[]` and run the log per nested repo under
    `~/.local/state/seshy/sessions/<session_name>/<repo>`.
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
  is the `repo` for `kind: repo`/`dir`, and the `session_name` for
  `kind: seshy-session` (a seshy session is one heading spanning its `repos[]`,
  not one heading per repo). Within a unit, order by signal (`diffstat`
  magnitude, commit count). Keep it skimmable:

  ```markdown
  ## 2026-06-09

  ### sysinit
  - Slugified Claude tab titles in wezterm and branded with a sparkle;
    disabled tabline rendering so sigil titles show. (3 commits, c04e5e0)
  - Added a session-aware statusline and a cross-session worklog hook.

  ### no-jared-dependencies (session · go-common, oncallbot)
  - Wired the on-call escalation path through go-common and verified it from
    oncallbot. (go-common: 2 commits; oncallbot: 4 files)

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
