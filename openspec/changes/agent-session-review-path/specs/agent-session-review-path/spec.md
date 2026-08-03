## ADDED Requirements

### Requirement: A session reports its readiness before it is archived

A command SHALL report whether one seshy session is finished. For each
repository in the session it SHALL report the branch, the count of uncommitted
files, and the count of commits not present on the upstream branch. It SHALL
also report every live pane holding an agent state above `idle`.

The report SHALL exit zero when the session is ready and non-zero when it is
not, so a hook can gate on it.

Readiness is git state and agent state only. Both are free to read. A check
that costs minutes, such as a build or a test run, MUST NOT run here: the report
is on the path of an interactive command.

#### Scenario: A finished session reports ready

- **POLARITY** positive
- **WHEN** every repository in the session is clean and has no unpushed commit,
  and no live pane holds a state above `idle`
- **THEN** the report exits zero
- **AND** it names each repository as clean

#### Scenario: Uncommitted work blocks the report

- **POLARITY** negative
- **WHEN** a repository in the session has uncommitted files
- **THEN** the report exits non-zero
- **AND** it names that repository, its branch, and the file count

#### Scenario: An unpushed commit blocks the report

- **POLARITY** negative
- **WHEN** a repository has commits the upstream branch does not carry
- **THEN** the report exits non-zero and names the commit count

#### Scenario: A repository with no upstream is not treated as unpushed

- **POLARITY** negative
- **WHEN** a repository's branch has no upstream configured
- **THEN** the report does not count its commits as unpushed
- **AND** it says the branch has no upstream rather than reporting a number it
  cannot compute
- **AND** the missing upstream ALONE does NOT make the session unfinished, because
  seshy creates every session branch without one and blocking on it would
  refuse the most common delete on this machine

#### Scenario: A commit reachable from no other ref makes the session unfinished

- **POLARITY** negative
- **WHEN** a repository holds a commit reachable from no branch, tag, or
  remote-tracking ref other than the checked-out branch itself
- **THEN** the report exits non-zero and names how many such commits there are
- **AND** it does so whether or not an upstream is configured, because a missing
  upstream does not measure this: `sy delete` removes the worktree and then runs
  `git branch -D`, which never refuses an unmerged branch, so the commit
  becomes unreachable
- **AND** a session whose HEAD is reachable from another ref is still ready, so
  the common delete is not refused

#### Scenario: A gate that cannot report still reaches its decision

- **POLARITY** negative
- **WHEN** the report exits non-zero under a shell with `errexit` set
- **THEN** the gate still prints its refusal, still honors `--force`, and still
  reaches its exit path
- **AND** it does not abort mid-script, which would look like a held gate while
  actually being a crash

#### Scenario: A working agent blocks the report

- **POLARITY** negative
- **WHEN** a live pane in the session holds `working`, `waiting`, or `done`
- **THEN** the report exits non-zero and names the pane and its status

#### Scenario: A stale state file does not block the report

- **POLARITY** negative
- **WHEN** a state file names a pane id that no longer exists
- **THEN** the report ignores it
- **AND** a session whose agents have all exited still reports ready

#### Scenario: The report degrades outside WezTerm

- **POLARITY** negative
- **WHEN** the live pane set cannot be determined, for example outside WezTerm
- **THEN** the report skips the agent-state check rather than treating every
  state file as live
- **AND** it says the agent check was skipped

### Requirement: Deleting a session is gated on its readiness

`sy delete` SHALL run the readiness report before removing a session and SHALL
refuse when the report exits non-zero.

The gate MUST NOT be seshy's `preDelete` hook. seshy runs that hook advisorily:
a non-zero exit logs a warning and the deletion proceeds anyway, with or without
`--force`. This was verified against seshy 4.0.0, after an earlier draft of this
capability assumed the hook could veto. A hook that prints "refusing" and then
does not refuse is worse than no hook.

The gate SHALL therefore be an executable named `sy`, installed ahead of the
seshy binary on PATH, that runs the report and returns non-zero before invoking
the real binary.

It MUST NOT be an interactive-shell function. A `.zshrc` function is read only
by interactive shells, so `zsh -c`, every script, every cron entry, and every
coding agent's shell tool would bypass it. Agents are the callers this
capability exists for, and they are exactly the ones with no `.zshrc`.

The gate SHALL be overridable. `sy delete --force` is the documented escape and
MUST still delete.

The gate MUST only ever refuse. It MUST NOT commit, push, merge, or modify a
repository, because the owner decides what happens to unfinished work.

#### Scenario: An unfinished session is not deleted

- **POLARITY** negative
- **WHEN** the owner runs `sy delete` on a session with uncommitted work
- **THEN** the deletion does not proceed
- **AND** the output names what is unfinished

#### Scenario: A finished session deletes normally

- **POLARITY** positive
- **WHEN** the owner runs `sy delete` on a ready session
- **THEN** the deletion proceeds with no extra prompt

#### Scenario: Force still deletes

- **POLARITY** negative
- **WHEN** the owner runs `sy delete --force` on an unfinished session
- **THEN** the deletion proceeds
- **AND** the report's findings are still printed, so the owner sees what was
  discarded

#### Scenario: A broken report does not trap a session

- **POLARITY** negative
- **WHEN** the report command is missing or fails for a reason other than
  unfinished work
- **THEN** the gate allows the deletion rather than making the session
  undeletable
- **AND** it prints that the readiness check could not run
