## ADDED Requirements

### Requirement: Enrich switcher rows with repo, branch, and pane counts

The session switcher (`wm.get_choices`) SHALL, in addition to the existing state
icon / reason / age, decorate each session row with its repo name, git branch
plus a dirty marker, the count of agent panes in the session, and the count of
those panes that are blocked (e.g. `3 · 1◔`), plus the worst pane's agent icon.
These fields SHALL be sourced from the same shared rollup and per-pane view the
statusline and jump use, not recomputed. Sessions with no agent state SHALL keep
their existing bare-name rendering.

#### Scenario: Blocked session row shows repo, branch, and counts

- **WHEN** session `auth-refactor` on repo `app` branch `main` has three agent
  panes, one `waiting`
- **THEN** its row shows the repo, `main`, a pane count of 3, a blocked count of
  1 with the waiting icon, and the agent icon, alongside the existing
  reason/age

#### Scenario: Clean branch omits the dirty marker

- **WHEN** a session's worktree has no uncommitted changes
- **THEN** its branch renders without the dirty marker

#### Scenario: Stateless session keeps a bare row

- **WHEN** a session has no agent panes
- **THEN** its row is the plain session name with no repo/branch/count
  decoration

#### Scenario: Missing git metadata degrades gracefully

- **WHEN** a session's repo or branch cannot be determined
- **THEN** the row omits those fields and still renders the session name and any
  available agent state without error
