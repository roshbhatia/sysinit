# agent-diff-notes Specification

## Purpose
TBD - created by archiving change make-sysinit-composable. Update Purpose after archive.
## Requirements
### Requirement: The note record is this repository's, and the viewer is a reader of it

An agent review note SHALL be written to a durable record this repository owns.
The writer MUST NOT drive, launch, or push into a viewer, and the record MUST
answer when no viewer is installed.

The record's location SHALL come from the state-path manifest, so one owner
names it and every reader resolves it the same way.

The write surface SHALL be `sysinit-agent note`, with `add`, `apply`, `list`,
`clear`, `path`, and `rebuild`. A note SHALL carry a file, a line or line range,
a summary, and MAY carry a rationale and an author. `--replace` SHALL upsert
against an existing note rather than appending a second one.

This is Command-Query Separation as a rule about the writer: recording a note
produces a fact and nothing else. The predecessor command violated it by
mutating the store and performing a visible side effect in one call, which is
what forced a CLI to know how to drive an editor.

#### Scenario: A note is recorded with no viewer present

- **POLARITY** positive
- **WHEN** `sysinit-agent note add` runs on a box with no viewer installed
- **THEN** the note is written to the record
- **AND** the command exits zero and opens nothing

#### Scenario: The writer never reaches a viewer

- **POLARITY** negative
- **WHEN** a note is recorded while a viewer is running
- **THEN** the writer does not call, signal, or push to that viewer
- **AND** a viewer that misses the note re-reads on its next run rather than
  being left permanently wrong by a failed push

#### Scenario: Replacing a note upserts

- **POLARITY** positive
- **WHEN** `sysinit-agent note add --replace` names a file and line that already
  carry a note
- **THEN** the existing note is replaced
- **AND** the record holds one note for that location, not two

### Requirement: The export is derived from the record and republished with it

The record SHALL have a derived export in the schema the viewer's agent-context
flag expects. The export is derived state and never a second source of truth.

The export SHALL be republished inside the same lock that publishes the record,
on every write, so the two cannot drift under concurrent writers.

The record SHALL be written before the export. That order can only ever leave
the export missing a note the record already holds, which `rebuild` repairs; the
reverse order would show a note the record does not have, which nothing repairs.

`sysinit-agent note rebuild` SHALL regenerate the export from the record. It
exists because a record written before the export existed is the state every box
is in the moment this lands, and nothing else rebuilds it.

#### Scenario: A write republishes the export

- **POLARITY** positive
- **WHEN** a note is added
- **THEN** the export is rewritten in the same operation
- **AND** it reflects the record as of that write

#### Scenario: A record with no export is repairable

- **POLARITY** negative
- **WHEN** the record holds notes and the export is missing
- **THEN** `sysinit-agent note rebuild` regenerates it from the record
- **AND** no note is lost

### Requirement: `review` is the reader, and it is a separate verb

Reading the working-tree diff with this repository's notes attached SHALL be a
command named `review`. It SHALL supply the viewer's agent-context flag and the
flag that turns note display on, and SHALL pass every other argument through.

It MUST NOT be named for the viewer binary. A wrapper with that name is one name
for two things: it collides with the viewer on the same path entry in one home
profile, and `which` can no longer say which one ran. A separate verb composes
with the tool; a shadow hides it.

`review` SHALL fail loudly when the note-path command is missing, rather than
showing a review that silently has no notes. Without that, "this repository has
no notes" is indistinguishable from "the note reader is missing", and the second
is the ordinary state on a box that installed the viewer by hand.

`review` SHALL fail loudly when the record holds notes and the export does not
exist, and SHALL name the rebuild verb.

An empty record and an empty export are the ordinary state of a clean
repository, not an error. `review` SHALL then omit the flag rather than pass a
path that does not exist or synthesize an empty file.

The agent-context path SHALL be a real file and never stdin. Reading the sidecar
from stdin returns a null watch plan, which turns a watching review into a
one-shot with no diagnostic.

#### Scenario: Notes attach to the diff

- **POLARITY** positive
- **WHEN** `review` runs in a repository whose record holds notes
- **THEN** the viewer opens with the export attached and note display on

#### Scenario: A clean repository reviews normally

- **POLARITY** positive
- **WHEN** `review` runs with no record and no export
- **THEN** the viewer opens on the plain diff
- **AND** no context file is created to answer a question that needs no file

#### Scenario: A missing note reader is loud

- **POLARITY** negative
- **WHEN** `review` runs and the note-path command is not on PATH
- **THEN** it exits non-zero and says the record cannot be located
- **AND** it does not open a review that appears to have no notes

#### Scenario: A stale export is named, not ignored

- **POLARITY** negative
- **WHEN** the record holds notes and the export is missing or empty
- **THEN** `review` exits non-zero, names both paths, and names the rebuild verb

### Requirement: A running viewer is not refreshed by a write

A note written while a viewer is already running SHALL NOT be expected to reach
that viewer. Re-running `review` is the remedy.

This is recorded as a contract rather than left to be rediscovered. It was
measured: a note written during a watching review did not appear at 5, 15, 30,
or 60 seconds, after a focus change, or after keystrokes, and a control edit to
a tracked file failed the same way. The viewer's own reload verb is not the
remedy either, because it picks the working tree up and drops the agent context
to zero doing it, trading a stale note view for no notes at all.

#### Scenario: A note written mid-review needs a re-run

- **POLARITY** negative
- **WHEN** a note is recorded while a watching `review` is open
- **THEN** the open viewer is not required to show it
- **AND** re-running `review` shows it

