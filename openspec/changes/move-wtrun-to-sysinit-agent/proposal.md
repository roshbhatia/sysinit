## Why

`wtrun` gives an agent a second WezTerm pane to run a command in, reuses that
pane across runs, and reports the result through a file rather than the screen.
That shape is right, and comparing it against `herdrdev/herdr` and
`manaflow-ai/cmux` confirms it: both projects converge on the same primitives,
and `wtrun` plus `agent-sessions.sh` already satisfy them.

- An agent's work is a visible pane, not a hidden background process. cmux
  "turns them into native panes and splits instead of hidden background
  processes" [cite: cmux-subagents-become-panes].
- Every pane carries a state. herdr marks each one "working, blocked, or idle"
  [cite: herdr-pane-state]. `agent-sessions.sh:113` and `panes.lua:6` rank
  `waiting`, `done`, `working`, and `idle`; `waiting` is the word this repository
  uses for herdr's `blocked`.
- The state is published by the process that knows it, not scraped off the screen.
  `agentstate.go:231` writes it to a WezTerm user var and to a pane record, and
  five surfaces read it back.
- An agent can wait until another agent is blocked, not merely until a command
  exits. herdr exposes exactly that: agents can "wait until another agent is
  genuinely blocked" [cite: herdr-wait-until-blocked].

The last one is the only primitive `wtrun` lacks.

herdr is the nearer analogue of the two. It keeps the terminal you already have,
"runs in whatever terminal you already use" [cite: herdr-runs-in-your-terminal],
and still marks every pane's state. That is the same shape as `wtrun` plus
`agent-sessions.sh`. What separates them is that herdr is "a background server;
the terminals live inside it" [cite: herdr-is-a-server], and this change stays a
command that exits.

What is wrong is where it lives and what it keys on.

`wtrun.sh` keys its worker on `pane-$WEZTERM_PANE`. When the pane that spawned
the worker closes, the record is unreachable: a new pane in the same session gets
a new key, so it splits a second worker and the first is left running with nothing
addressing it. That is the orphan the owner objects to, and it is caused by the
keying rather than by any missing cleanup.

The rest is duplication, and it is narrower than the first draft of this proposal
claimed. Pane liveness is implemented three times, in `wtrun.sh:35`,
`agent-sessions.sh:75`, and `switcher.lua:398`. Each parses
`wezterm cli list --format json` with its own filter, and only `agent-sessions.sh`
bounds the call, so the `wtrun` copy is the one that can hang.

The paths-manifest reader is copied once, not twice. `runtime/paths.sh:3` defines
`sysinit_path` a single time and the runtime prepends it, so `agent-sessions.sh:2`
only calls it. `wtrun.sh:12-23` is the sole hand-rolled copy, and it exists only
because `skill-tools.nix:14` reads the script raw rather than prepending that
library. Prepending it there and deleting those twelve lines is a two-line fix that
needs none of this change, so the duplication argument for porting rests on pane
liveness alone.

`wtrun` has no tests, and on the neighbouring `internal/editevent` work a test
suite plus six mutations caught six defects that review had not, with a seventh
found only by running the thing for real.

Two capabilities are missing rather than duplicated. `--status` reports idle or
running, but `agent-sessions.sh:112` already ranks a `waiting` state above `done`
and `working`, so the vocabulary exists and `wtrun` never reports into it. And
`-w` waits for a command's exit code, so an agent can wait until a command
finishes but not until another agent is blocked on a human.

Two defects were found by using `wtrun` for real, both in one sitting.

The worker pane keeps whatever working directory it was created in, and the
caller's own directory never reaches it. A caller that had changed directory ran
`nh darwin build .` and the worker resolved `.` to the repository the pane had been
created in. That built the wrong flake, failed on a hostname the wrong flake does
not define, and rewrote that repository's `flake.lock` on the way. Nothing in the
output said which directory it used.

`-w` takes a value, and passing `-w -t 900` set the wait to the literal string
`-t`, left `900` as the command, split a pane, and ran `900` in it. The wait then
failed inside bash with `[: -t: integer expected`. A flag that wants a number
accepted a flag name instead, and the pane was already open by the time anything
complained.

## What Changes

`wtrun` becomes a `sysinit-agent` subcommand. `internal/repo` supplies the keying
that `internal/editevent` already uses, `internal/paths` replaces the script's own
manifest reader, and the bounded liveness probe is written once.

The subcommand is called `worker`, not `wtrun`. The owner decided this on
2026-08-11 and chose no alias, so the flags carry over unchanged and the command
name does not. Every sibling subcommand is a plain noun (`agent-state`,
`edit-event`, `note`, `watch`, `citelock`, `bash-guard`), and `wtrun` was the only
tool-prefixed abbreviation among them. `worker` is the word the state files and the
documentation already used for the pane, so the rename removes a second name for
one thing rather than adding one.

Six behavioral changes ride along, in dependency order:

1. The worker is keyed on the workspace, resolved by `repo.Workspace`, rather than
   on the parent pane id.
2. `--status` reports `waiting` when the run is blocked on input, not just idle or
   running.
3. State whose pane no longer exists is pruned rather than left to accumulate.
4. A wait mode returns when the worker reaches `waiting`, not only when it exits.
5. The command runs in the caller's working directory, and that directory is named
   in the output.
6. A flag that wants a number rejects anything else, before a pane is split.

Item 4 depends on item 2 existing. Items 1, 3, 5, and 6 are independent. The
rename is independent of all six and lands with the cutover, so phase 1 ships the
subcommand while the script keeps the name on PATH.

### Non-goals

- Not a terminal. cmux is itself "a Ghostty-based macOS terminal"
  [cite: cmux-is-a-terminal]; this keeps WezTerm and drives it through
  `wezterm cli`.
- No server, which is the one thing that separates this from herdr
  [cite: herdr-is-a-server]. The state stays files under a manifest path, now
  `agentWorker`, readable by a shell one-liner, because that is what makes the
  status line and the Lua side able to read it without linking anything.
- No second state bus. `agentstate` already publishes a pane's state to a WezTerm
  user var and a pane record, and `panes.lua:57`, `ui.lua:174`,
  `ui/tabtitle.lua:48`, `ui/session_tree.lua:50`, and `ui/switcher.lua:98` read it.
  `wtrun` reports into that, and MUST NOT invent a parallel one.
- No change to `agent-sessions.sh`. It reads its paths through the shared
  `runtime/paths.sh`, so it holds no copy to remove. Its state model is already
  right.
- No new pane kinds. One worker per workspace, as today.
- The bash `wtrun.sh` is removed, not kept as a fallback. Two implementations of
  the keying rule is the failure this change exists to stop.

## Behavior

### The worker is addressed by workspace, not by the pane that asked for it

The worker record SHALL be keyed on `repo.Workspace(dir)`, which resolves a seshy
session directory before a git top level, matching what `internal/editevent`
already keys its log on.

- WHEN a pane asks for a worker and a live worker is already recorded for the
  workspace
- THEN that worker is reused, whichever pane recorded it

- WHEN the pane that recorded the worker has closed but the worker is alive
- THEN a new pane in the same workspace reuses the existing worker rather than
  splitting a second one

#### Scenario: the recorded worker is gone (negative)

- WHEN a worker id is recorded but no pane with that id exists
- THEN a fresh worker is split, the record is replaced, and no command is sent to
  the dead id

#### Scenario: the caller is the recorded worker (negative)

- WHEN the recorded worker id equals the calling pane
- THEN the record is rejected and a new worker is split, so a command is never
  sent to the pane that asked for it

### One worker per workspace does not mean one log per workspace

Sharing a worker across the panes of a workspace is the accepted trade. Sharing a
run's log and exit-code file is not.

- WHEN two panes in one workspace each ask for a worker
- THEN they share the worker, and each run keeps its own log and its own exit-code
  file

#### Scenario: the same run name is already in flight (negative)

- WHEN a caller uses a run name whose previous run has not recorded an exit code
- THEN the call fails naming that run, and neither truncates its log nor removes
  its exit-code file

This closes a hole the per-pane key hid. Today the guard compares against the one
run currently executing, so a run that is queued and not yet started is not
matched, and a second caller with the same name truncates its log and then reads
its exit code.

### A blocked run is reported as blocked

- WHEN a run is executing and has not asked for input
- THEN `--status` reports it as running, with the run's name

- WHEN a run is waiting on input
- THEN `--status` reports `waiting`, and the pane record and the WezTerm user var
  carry the same word, so the status line, the tab title, the switcher, the session
  tree, and `agent-sessions.sh` agree with `--status` about that pane

`waiting` is declared by the run, so it has exactly one producer: a harness run
inside the worker pane, whose hooks already call `agent-state`. The opencode plugin
does so today at `sysinit-notify.ts:78`. Nothing else does, and `SKILL.md:18`
documents the worker as the place for builds, switches, test suites, and `nix`
evaluations, none of which declare anything. So the common case stays `running`,
and `waiting` reports only for a run that is itself an agent.

That producer also conflicts with one worker per workspace. A harness parked at a
prompt holds the shared worker for as long as it waits, and the run-name refusal
above then fails every other run in that workspace. Whether `waiting` is worth
shipping under that constraint is an owner decision, recorded as such.

#### Scenario: a run that does not declare itself (negative)

- WHEN a run is blocked on input and never calls `agent-state`
- THEN it is reported as running, and a blocked-wait on it holds until its timeout,
  which is the behavior `wtrun` has today

#### Scenario: a run that ended is not still blocked (negative)

- WHEN a run that declared itself blocked then exits, at any status
- THEN the state is set to `idle` in both the pane record and the WezTerm user var,
  so neither `--status` nor a later wait reports a run that has finished, and no
  reader is left holding `waiting`

#### Scenario: the run is interrupted rather than finishing (negative)

- WHEN the owner interrupts a blocked run with Ctrl-C, or closes the worker with
  `--close`
- THEN the state is cleared the same way, rather than leaving a live pane reporting
  `waiting` for as long as it lives

The clear MUST NOT be the bus's `exit` status. `exit` removes the pane record without
updating the user var, and WezTerm holds a var until the pane closes, so `exit` makes
`--status` disagree with all five readers about the same pane. That is the divergence
this design rejected a worker-only state file to avoid.

A blocked worker is a visual signal, not a notification. `ui.lua:172` suppresses
notification for any pane carrying a state var, so publishing is what silences it.

#### Scenario: no worker at all (negative)

- WHEN no worker is recorded for the workspace
- THEN `--status` says so and exits 0, rather than reporting a state it does not
  have

### Waiting can end on blocked as well as on exit

- WHEN a caller waits and the run exits
- THEN the wait returns the run's exit code, as it does today

- WHEN a caller waits for a blocked run and that caller's own run reaches `waiting`
- THEN the wait returns and says which run is blocked, rather than holding until
  the timeout

The blocked wait is its own flag. `-w` keeps exactly two outcomes, the command's own
status and 75 on timeout, so no existing caller that branches on `$?` reads a blocked
run as a build result.

#### Scenario: another run in the workspace is the blocked one (negative)

- WHEN a caller waits for its own run to block, and a different run in the same
  workspace is the one that declared `waiting`
- THEN the wait does not return, because the pane record carries no run identifier and
  `waiting` is attributed only by the run named in the running marker

#### Scenario: the caller's run has not started yet (negative)

- WHEN a caller's command is still sitting in the tty input buffer, having executed
  nothing, and the worker pane holds `waiting` from an earlier run
- THEN the wait does not return, rather than naming a run that never ran a line

#### Scenario: the worker pane holds a state wtrun did not produce (negative)

- WHEN the owner types into the worker pane and starts a harness there, and that
  harness declares `waiting`
- THEN `--status` does not report a blocked wtrun run, because no running marker names
  a live run

#### Scenario: a recorded worker id belongs to a new mux generation (negative)

- WHEN a recorded worker id names a live pane that a later mux generation allocated
- THEN the record is rejected rather than reused, so no command is sent to an
  unrelated pane, and a record whose generation marker is absent is treated as no
  state rather than as current

- WHEN a caller waits with a timeout and neither happens in time
- THEN the wait returns non-zero and names the file to poll, as it does today

### State does not accumulate

- WHEN a command runs and a record's pane no longer exists
- THEN that record is removed

#### Scenario: pruning cannot remove live state (negative)

- WHEN a record's WORKER pane is alive, whichever pane the record is named after
- THEN the record survives pruning, whatever its age

#### Scenario: the liveness probe does not answer (negative)

- WHEN `wezterm cli` cannot be reached at the moment the prune runs
- THEN the prune removes nothing and says so on its report line, rather than reading
  an unanswerable probe as every worker being absent

The section title is true of whole records and NOT of the inside of a live one, and
the difference matters more after this change than before it. The old key was per
caller pane, so a record aged out with the pane that made it. The workspace key gives
one record per repository, reused by every pane for as long as the repository exists,
and the negative scenario above guarantees that such a record is never pruned.

One of the two things that accumulated is fixed here. The generated body deletes
itself once its exit code is recorded, because a body is dead the moment its run ends:
13 of the 41 entries in the live superseded record are dead bodies. Measured twice
before relying on it, since a script removing the file it is running from is not
obviously safe: zsh runs a 300-line script to completion after the file is deleted
mid-run, and a trap can remove it.

Logs are NOT rotated, and that is out of scope rather than solved. Measured on the
live superseded record: 41 entries and 816 KB over five days of one owner's use, with
the two largest logs at 288 KB and 273 KB, so roughly 163 KB and 8 files a day per
record. A month of the same use is about 5 MB. The `.cmd` fix removes about a third of
the file count and almost none of the bytes.

#### Scenario: a finished run leaves no script behind

- WHEN a run records its exit code
- THEN its generated body is gone, while its log and its exit-code file remain

### A relative path means the caller's directory

- WHEN a caller runs a command containing a relative path
- THEN the command runs in the caller's working directory, whatever directory the
  worker pane was created in

- WHEN a run starts
- THEN the output names the directory the command will run in, so a wrong one is
  visible before the command's own output is

The directory is resolved twice, because the two checks answer different
questions. The caller's process checks it exists before splitting anything. The
worker checks it again when it actually runs, which can be minutes later, because
the tty input buffer holds the command until the previous one finishes.

#### Scenario: the caller's directory is gone (negative)

- WHEN the caller's working directory no longer exists at the moment the caller
  runs
- THEN the call fails with that reason and splits nothing

#### Scenario: the directory disappears while the run is queued (negative)

- WHEN the directory existed at send time and is gone when the worker reaches the
  command
- THEN the run stops before the command, and records a non-zero exit code
  distinguishable from the command's own, rather than running it in the worker's
  directory

#### Scenario: the directory name needs quoting (negative)

- WHEN the caller's directory contains a space or a shell metacharacter
- THEN the run enters that directory, rather than failing or entering another one

### A numeric flag takes a number

- WHEN `-w` or `-t` is given a value that is not a non-negative integer
- THEN the command fails naming the flag and the value, and splits no pane

#### Scenario: the value is the next flag (negative)

- WHEN `-w` is followed by `-t`
- THEN that is the failure above, rather than a wait of `-t` and a command of
  whatever followed

### An existing invocation behaves the same, under the new name

- WHEN an existing invocation runs, with any combination of `-w`, `-t`, `-n`,
  `--status`, `--close`, and a command, spelled `worker` rather than `wtrun`
- THEN it behaves as the bash implementation did, including the exit code and the
  log and rc file paths

The command name is the fourth exception, and unlike the other three it is a
decision rather than a defect being corrected. The owner chose `worker` with no
alias on 2026-08-11, so `wtrun` stops resolving when phase 2 lands, and every call
site is edited in the same phase that removes the script.

There are three further deliberate exceptions. A caller that relied on the worker's
directory rather than its own gets a different directory, and a caller that passed a
non-number to `-w` gets an error where it used to get a pane. Both were the defect;
preserving them is not compatibility.

The third is the run-name refusal, and it is the one that costs the owner something
they have today. An earlier draft of this paragraph said bash reused any name. It did
not: `wtrun.sh:124-126` refuses a name the running marker currently holds. What
changes is the refusal's scope and how long it lasts.

Bash keyed the refusal on the marker, so it covered only the one name the marker held,
and any later run overwrote the marker and cleared the burn. The new refusal keys on a
missing `.rc`, so it covers every name whose run recorded no exit code and it lasts
until the name is released. That is a real cost: an interrupted run leaves a log and no
`.rc`, three such names exist on disk right now, one from today's session, which is one
run in eight. The workspace key widens it further, because a burned name is scoped to
one caller pane today and to the whole workspace after the change.

Bash's own refusal was also unfollowable, which is why keeping it as it stood was not an
option. `wtrun.sh:110` removes the `.rc` file at the top of every run, before the guard
at `:124` runs, so the message telling the caller to wait for that file names a file the
same invocation had just deleted.

So the refusal MUST come with a release, and the release MUST NOT be "wait for the
worker pane to die", which discards every other run's log in the workspace.

#### Scenario: a name burned by an interrupted run (negative)

- WHEN a caller reuses a run name whose previous run was interrupted and recorded no
  exit code
- THEN the call names the run, names how to release it, and the release clears that
  one run's artifacts without touching any other run in the workspace

The release MUST refuse while the run could still execute, and "could still execute"
is not the same as "is executing". A run queued in the tty input buffer has not
written the running marker, because the body writes it when the PREVIOUS command
finishes, so a marker-based refusal released a run that was about to start: it
deleted the body, the pane then failed to open its own script, and the name was
burned a second time by the release itself. The decidable test is a missing exit code
plus a live worker pane.

#### Scenario: a run queued behind another is released (negative)

- WHEN a caller releases the name of a run that has been sent but has not begun
- THEN the call refuses, names the pane that is going to run it, and leaves its body
  and its log in place

#### Scenario: the pane is closed under a running run (negative)

- WHEN `--close` kills a pane whose run has recorded no exit code
- THEN the run is recorded as exit 129, so closing the pane does not leave that name
  unusable, and the output says which run it ended

The smaller differences below are deliberate, and are declared here rather than left
for a reader to find by diffing the two implementations. Each one changes observable
output, so none of them is an implementation detail. They are grouped by kind rather
than counted, because a count in this list goes stale every time one is added:

- A caller error exits 2, where `wtrun.sh:7` exited 1. 2 separates a caller mistake
  from a command that failed, and 75 already means "still running". `--close` also
  exits 2 when the kill itself fails, where bash exited 0 whatever happened.
- A run whose directory disappeared exits 78, not 2, so it is distinguishable from
  the ordinary failure `make` and `go test` report as 2.
- A flag with no value is an error. Bash defaulted `-w` to 0, `-t` to 20, and `-n` to
  empty at `wtrun.sh:54,58,62`, then ran `shift 2` with one argument left. Measured:
  bash's `shift` refuses to shift past `$#` and returns non-zero, and the script sets
  no `-e`, so the loop re-enters with `$1` still `-w` and spins. `wtrun -w` therefore
  ran nothing at all, rather than waiting.
- Mode flags are no longer order-dependent. Bash acted on `--status` inside its
  parse loop, so a later flag was never read; here the parse finishes first, and a
  mode flag combined with a command is refused rather than discarding the command.
- `-n` validates its value as one path element. Bash passed it into a path unchecked.
- Every log's header, and the line printed on a successful start, carry an `in <dir>`
  field, because the directory is now the key and a log that does not name it cannot
  be read six hours later. The start line goes from `pane <id>  <name>  log <path>`
  to `pane <id>  <name>  in <dir>  log <path>`, and the queued form gains the same
  field. This is the one line every ordinary invocation prints.
- Five reporting strings change wording. Bash printed `worker pane <id>, running
  <name>`, `worker pane <id>, idle`, `no worker pane` for both `--status` and
  `--close`, and `closed pane <id>`. The new forms are `pane <id>  running <name>
  log <path>`, `pane <id>  idle  in <root>`, `no worker for <root> (<reason>)`, and
  `closed pane <id> for <root>`, the last optionally followed by `; reclaimed a
  marker naming <name>`. Every exit code is unchanged, so a caller reading `$?` is
  unaffected and a caller grepping `no worker pane` finds nothing.

#### Scenario: not inside WezTerm (negative)

- WHEN `WEZTERM_PANE` is unset
- THEN the command fails with that reason and splits nothing

#### Scenario: the mux is unresponsive (negative)

- WHEN `wezterm cli` does not answer
- THEN the call is bounded and fails rather than hanging, matching the
  `PROBE_TIMEOUT` discipline `agent-sessions.sh:12` already applies

## Impact

Affected: `pkgs/sysinit-agent/` (a new subcommand, plus `internal/repo` and
`internal/paths` gaining the lookups the shell copies did),
`modules/home/programs/llm/skills/wtrun/` (the script is replaced by a wrapper
around the subcommand, and `SKILL.md:57`'s promise that two runs never share a log
has to be restated for a shared key), and
`modules/home/programs/llm/runtime/agent-sessions.sh` (its duplicated manifest
reader is deleted).

Also affected, and missed in the first draft. Three places compute or hardcode the
old key, and none of them is a caller passing flags:

- `pkgs/sysinit-agent/internal/watch/watch.go:224` builds the session as
  `"pane-" + WEZTERM_PANE`, then reads `<session>/<log>.log` under the wtrun path.
  Its guard at `watch.go:233` rejects any session containing `/`, and
  `repo.Workspace` returns a directory path, so the renderer MUST take a directory
  and key it internally, as `newBus` at `watch.go:302` already does. The guard then
  applies to the derived name rather than to the argument.
- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua:260` binds a key
  to `watch wtrun pane-<pane_id>`, with the prefix written into the Lua. It never
  reads `WTRUN_SESSION`, so that override cannot repair it.
- `modules/home/programs/llm/skills/wtrun/SKILL.md` documents the per-pane worker.

Reporting `waiting` through `agentstate` rather than through a file of its own is
what makes the five surfaces agree, and it also puts the worker pane into the pane
record set those surfaces render. `switcher.lua:95` builds an attention row from any
record ranked at `working` or above, so the worker appears as an agent session with
the workspace as its crumb. That is a consequence of the round-1 decision, not a
side effect to be discovered later, and phase 3 MUST show the owner what the worker
looks like in the switcher before it is accepted.

Not affected: the pane record schema, and the file names a record carried before this
change (`worker-pane`, `worker-running`, `worker-runs`, `<name>.log`, `<name>.rc`,
`<name>.cmd`, `last.log`, `last.rc`).

A record gains two files. `worker-mux` holds the mux generation that wrote
`worker-pane`, and the phase-3 prune MUST know about it, since the pane record is now
two files rather than one. `worker-lock` is an empty file held under `flock` while a
run name is allocated; it carries no state and is never read.

Writes to `worker-mux` and `worker-runs` go through a temporary `<name>.new` beside
the target and then a rename, so a reader never sees a partial record. A `.new` file
left behind is a crashed write rather than state, and none has ever been left: a scan
of the 303 entries in the superseded root finds none.

`last` is reserved and cannot name a run. `last.log` and `last.rc` are the aliases
for the most recent run, so `-n last` made the alias and the run's own log the same
path: the run created a regular file where the symlink was, the alias was then
pointed at itself, and every read of the result returned ELOOP. The command ran and
reported its exit code with its entire output gone.

The `agentWtrun` path is affected, and an earlier draft of this line said it was
not. The rename gives the live state a new root, `agentWorker`, and phase 3 removes
the old root whole rather than sweeping it.

Risk: `wtrun` is what an agent uses to run a build, so a regression here is a
regression in every long-running command. The `WEZTERM_PANE`, dead-worker, and
self-reference negative scenarios above are the cases that made the bash version
correct, and they carry over as tests rather than as review notes.

Second risk: changing the key migrates nothing. A worker recorded under the old
`pane-N` key becomes unaddressable at the moment this ships, which leaks exactly
one pane per workspace that had a live worker. The design MUST state whether the
old keys are read once and adopted, or ignored and pruned, and the answer must be
one of those two rather than both.

This is live state, not a hypothetical. `pane-241/worker-pane` holds `434`, and
pane 434 is on screen. Whatever the design chooses, the cutover MUST explain that
pane on the first run rather than silently splitting a second one, because the one
human gate on the deletion is the owner watching for exactly that.

Third risk: the state on disk has three shapes, not one. The wtrun root holds 303
entries: four `pane-N/` directories, a root-level `worker-pane` naming a pane that
no longer exists, and roughly 300 flat `*.cmd`, `*.log`, and `*.rc` files from a
layout with no session directory at all. A prune scoped to workspace-keyed
directories reaches none of it, and a prune that treats every root entry as a
candidate key reads those 300 files as keys. The design MUST say which entries the
prune considers, and that set MUST be decidable without guessing.
