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

### Requirement: Source identity from the correct object

The hook SHALL derive work identity from the actual repository context. When
`cwd` is under `~/.local/state/seshy/sessions/<name>`, it SHALL set
`kind = "seshy-session"`, set `session_name` to `<name>`, and populate `repos[]`
with one object per immediate child directory that is a git worktree
(`repo`, `branch`, `head`, `diffstat`). When `cwd` is itself a git worktree it
SHALL set `kind = "repo"` with top-level `repo`/`branch`/`head`/`diffstat`.
Otherwise it SHALL set `kind = "dir"`.

#### Scenario: Seshy session enumerates nested repos
- **WHEN** a session ends with `cwd` =
  `~/.local/state/seshy/sessions/no-jared-dependencies` containing nested repo
  worktrees
- **THEN** the line has `kind: "seshy-session"`,
  `session_name: "no-jared-dependencies"`, and a `repos[]` entry per nested
  worktree with its branch and head

#### Scenario: Plain repo keeps single-repo capture
- **WHEN** a session ends with `cwd` inside an ordinary git worktree
- **THEN** the line has `kind: "repo"` and populated top-level `repo`,
  `branch`, and `head`

#### Scenario: Session root is not mislabeled as a repo (negative)
- **WHEN** `cwd` is a seshy session root (not itself a git repo)
- **THEN** `repo` is NOT set to the session directory's basename and git fields
  are NOT left empty in place of the nested per-repo data

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

The hook SHALL NOT append a line when there is no `first_prompt`, no git
context, and `kind` is `dir`.

#### Scenario: Empty session is dropped (negative)
- **WHEN** a session ends in a non-repo, non-seshy directory with no resolvable
  first user prompt
- **THEN** no line is appended to the worklog

### Requirement: Skill reads the multi-repo schema and resolves transcripts

The `worklog` skill SHALL interpret `kind`/`repos[]`/`session_name`, group
`seshy-session` entries by `session_name` (spanning their repos), treat lines
lacking `kind` as `kind = "repo"`, and resolve a missing `transcript_path` by
`session_id` before degrading to an inferred summary.

#### Scenario: Seshy session reported as one unit across repos
- **WHEN** the report window contains a `seshy-session` entry with multiple
  `repos[]`
- **THEN** the digest presents it grouped under its `session_name` and reflects
  work across the listed repos

#### Scenario: Legacy line without kind still reports (negative)
- **WHEN** a pre-existing line has no `kind` field
- **THEN** the skill does not error and treats it as a single-repo entry
