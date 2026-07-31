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

`sy delete` SHALL run the readiness report before removing a session, through
seshy's `preDelete` hook, and SHALL refuse when the report exits non-zero.

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
