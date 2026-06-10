## ADDED Requirements

### Requirement: Record only terminal session ends

The `SessionEnd` capture hook SHALL append a worklog line only for terminal end
reasons (e.g. `clear`, `logout`, `prompt_input_exit`, `other`) and SHALL NOT
append for continuation reasons such as `resume`.

#### Scenario: Terminal end is recorded
- **WHEN** a session ends with `end_reason` of `clear`, `logout`,
  `prompt_input_exit`, or `other`
- **THEN** the hook appends one JSON line for that session

#### Scenario: Resume is not recorded (negative)
- **WHEN** the hook receives `end_reason: "resume"`
- **THEN** the hook exits without appending any line to the worklog

### Requirement: Record git context as a uniform repos list

The hook SHALL record git context only in a `repos[]` array, never as scalar
`repo`/`branch`/`head`/`diffstat` fields. When `cwd` is under
`~/.local/state/seshy/sessions/<name>` (the session root OR any nested repo
within it), it SHALL set `kind = "seshy-session"`, set `session_name` to
`<name>`, and populate `repos[]` with one object per nested git child of the
session. When `cwd` is itself a git worktree it SHALL set `kind = "repo"` with a
one-element `repos[]`. Otherwise it SHALL set `kind = "dir"` with an empty
`repos[]`.

#### Scenario: Seshy session enumerates nested repos
- **WHEN** a session ends with `cwd` =
  `~/.local/state/seshy/sessions/inf-1785/lrl-aws` (a nested repo inside the
  session)
- **THEN** the line has `kind: "seshy-session"`, `session_name: "inf-1785"`, and
  a `repos[]` entry per nested git child of `inf-1785` with its `name`,
  `branch`, and `head`

#### Scenario: Plain repo yields a one-element list
- **WHEN** a session ends with `cwd` inside an ordinary git worktree
- **THEN** the line has `kind: "repo"` and a single `repos[]` entry with
  populated `name`, `branch`, and `head`

#### Scenario: No scalar repo fields remain (negative)
- **WHEN** any emitted line is inspected
- **THEN** it has no top-level `repo`, `branch`, `head`, or `diffstat` field —
  git context appears only inside `repos[]`

### Requirement: Capture committed work, not the working tree

Each `repos[]` entry SHALL quantify work as `commits` (count of commits the
current branch is ahead of the origin default branch) and `diffstat`
(branch-vs-base, three-dot diff), and SHALL record any uncommitted working-tree
delta separately as `dirty`. The entry SHALL also carry a `url` formed by
normalizing the origin remote to an https web URL and appending `/tree/<branch>`.

#### Scenario: Committed feature-branch work is visible
- **WHEN** a repo's branch is 7 commits ahead of `origin/main` with no
  uncommitted changes
- **THEN** the entry has `commits: 7`, a non-empty `diffstat`, and `dirty: ""`

#### Scenario: Working-tree diff is not the work signal (negative)
- **WHEN** a session's work was committed to a feature branch
- **THEN** `commits`/`diffstat` reflect that work rather than being left empty
  because the working tree is clean

### Requirement: Resolve the transcript by session id

The hook SHALL record `transcript_path` from stdin only when that file exists on
disk; otherwise it SHALL resolve the transcript by locating
`~/.claude/projects/*/<session_id>.jsonl`, and record an empty path if none is
found.

#### Scenario: Stale stdin path is replaced by session-id lookup
- **WHEN** the stdin `transcript_path` names a file that does not exist but a
  transcript for `<session_id>` exists under `~/.claude/projects/`
- **THEN** the recorded `transcript_path` points at the resolved file

#### Scenario: No transcript anywhere (negative)
- **WHEN** neither the stdin path nor any `~/.claude/projects/*/<session_id>.jsonl`
  exists
- **THEN** the hook still appends the line with `transcript_path` empty rather
  than failing

### Requirement: Suppress zero-signal entries

The hook SHALL NOT append a line when `repos[]` is empty and there is no
`first_prompt`.

#### Scenario: Empty session is dropped (negative)
- **WHEN** a session ends in a non-repo, non-seshy directory with no resolvable
  first user prompt
- **THEN** no line is appended to the worklog

### Requirement: Skill reads the multi-repo schema and resolves transcripts

The `worklog` skill SHALL interpret `kind`/`repos[]`/`session_name`, group
`seshy-session` entries by `session_name` (spanning their repos), synthesize a
one-element `repos[]` from legacy lines that carry a scalar `repo` and no
`repos[]` (treating their `kind` as `repo`), and resolve a missing
`transcript_path` by `session_id` before degrading to an inferred summary.

#### Scenario: Seshy session reported as one unit across repos
- **WHEN** the report window contains a `seshy-session` entry with multiple
  `repos[]`
- **THEN** the digest presents it grouped under its `session_name` and reflects
  work across the listed repos

#### Scenario: Legacy line without kind still reports (negative)
- **WHEN** a pre-existing line has no `kind` field
- **THEN** the skill does not error and treats it as a single-repo entry
