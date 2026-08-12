> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Context

`modules/home/programs/llm/skills/wtrun/wtrun.sh` is 167 lines of bash. It splits
one WezTerm pane below the caller's, writes the command into a `.cmd` file, sends
one line of text to that pane's interactive shell, and reads the exit code back
out of a `.rc` file. The state lives under the `agentWtrun` path in the layout
manifest.

Three things it does are load-bearing and easy to lose in a rewrite. It refuses to
send a command to the caller's own pane (`wtrun.sh:43`). It returns focus to the
caller after splitting (`wtrun.sh:121`). It detects a second run against a busy
worker and says what it is queued behind (`wtrun.sh:113`, `wtrun.sh:145`).

The queue is not a queue. `wezterm cli send-text` writes into the pane's tty input
buffer, and the shell reads it when the running command finishes. The ordering is
the terminal's, not this script's. That constrains the design: `wtrun` MUST NOT
claim to schedule work it does not schedule.

Three packages in `pkgs/sysinit-agent/internal/` already hold what the shell
copies. `paths.AgentWtrun()` reads the same manifest key as `wtrun.sh:26`.
`repo.Workspace(dir)` resolves a directory to the thing state should be keyed on,
preferring a seshy session over a git top level, and `internal/editevent` already
keys its log that way. `internal/store` writes a file without a torn read.

The closest existing pattern is `internal/editevent`, added in
`add-agent-edit-bus`: a small subcommand, a hand-rolled flag parser, tests over
the failure paths, and mutation testing over the parser. This design follows it
rather than introducing anything new.

`modules/home/programs/llm/runtime/agent-sessions.sh` holds the third copy of the
pane-liveness check (`agent-sessions.sh:75`), and it is the copy that gets the
bounding right: `PROBE_TIMEOUT` at `agent-sessions.sh:12` caps the call, where
`wtrun.sh:35` does not.

It holds no copy of the manifest reader. `runtime/paths.sh:3` defines
`sysinit_path` once and the runtime prepends it, so `agent-sessions.sh:2` is a call
site. `wtrun.sh:12-23` is the only hand-rolled copy in the tree, and it exists
because `skill-tools.nix:14` reads the script raw rather than prepending that
library. Its state model is already correct and is not changed here.

## Goals / Non-Goals

Goals:

- One implementation of the keying rule, the manifest reader, and the pane
  liveness check.
- A worker addressable from any pane in the workspace, so a closed caller pane
  does not orphan it.
- The six behavioral changes in the proposal, with the negative scenarios as
  tests.
- Every existing invocation keeps working, except the two exceptions the proposal
  names.

Non-Goals:

- Real scheduling. The tty input buffer stays the queue.
- A daemon, a socket, or a server. herdr's answer is "a background server; the
  terminals live inside it" [cite: herdr-is-a-server]; this stays a command that
  exits.
- Replacing the terminal. cmux is itself "a Ghostty-based macOS terminal"
  [cite: cmux-is-a-terminal]; this drives WezTerm through `wezterm cli`.
- Changing the pane-record schema, or editing `switcher.lua`, `agent-sessions.sh`, or
  the status line. What they render changes without them changing: the worker becomes
  one more pane record, so the switcher gains a row labeled `in worker` and a session
  holding a blocked worker reads as `waiting`. That is what reusing the bus buys and
  what it costs, recorded under the `waiting` decision and in the proposal's `Impact`.
- Filtering the worker out of the session rollup. It would need `agent-sessions.sh` to
  read the agent field, which it does not do for any pane today, and that is a change
  to how every harness pane is counted rather than a wtrun change.
- Inferring a run's state. See the `waiting` decision.

## Decisions

- Decision: the command is named `worker`, decided by the owner on 2026-08-11,
  with no `wtrun` alias. Every sibling subcommand is a plain noun and `wtrun` was
  the only tool-prefixed abbreviation among them. `worker` is the word the state
  files (`worker-pane`, `worker-running`, `worker-runs`) and this design already
  used for the pane, so the rename retires a second name for one thing.
  - Consequence: the rename is a caller-visible break, and the proposal's
    "nothing that invokes `wtrun` today has to change" no longer holds. It is
    scoped to the wrapper on PATH and the skill, both of which land together in
    phase 2, so no window exists in which the old name resolves to nothing.
  - Consequence: the state root moves from `agentWtrun` to a new `agentWorker`
    manifest key. Nothing is migrated across it. The old root holds only the
    superseded flat and `pane-N` shapes, so the two roots never hold two shapes of
    the same thing, and the prune can take the old root whole.
  - Alternative rejected: keep `wtrun` as an alias beside `worker`. Rejected by the
    owner on the rule the rename exists to satisfy: two names for one thing is what
    is being removed, so shipping both would leave the defect and add a name.
  - Alternative rejected: keep the name `wtrun` and move only the implementation.
    Rejected because the port is the one moment the name can change without a
    second migration of the state root, which is keyed off the name.

- Decision: `wtrun` becomes a `sysinit-agent worker` subcommand, and the skill
  ships a wrapper that execs it. The wrapper keeps the flags, so every existing
  call site changes only in the command name.
  - Alternative rejected: keep bash and move the shared parts into a sourced
    library. This is cheaper than the first draft of this design said, and the
    draft's stated reason was wrong: it claimed the keying rule would be written
    twice, once here and once in `agent-sessions.sh`, when `agent-sessions.sh`
    already calls the shared `runtime/paths.sh` and writes no key of its own.
    Prepending `runtime.paths` in `skill-tools.nix:14` and deleting
    `wtrun.sh:12-23` would remove the last hand-rolled reader in two lines.
    Rejected anyway, on the remaining reason: the two defects found by using it
    were both in code a test would have caught, a sourced library does nothing
    about that, and there is no test harness for these scripts. The port's case is
    tests over a 167-line script that runs every build, not deduplication.

- Decision: the worker is keyed on `repo.Workspace(cwd)`, named with the same
  `basename-digest16` shape `repo.keyed` already produces for the diff note and
  the edit log.
  - Alternative rejected: keep `pane-$WEZTERM_PANE` and reap dead records.
    Rejected because reaping does not make the record reachable. The orphan is
    caused by a new pane computing a different key, so it splits a second worker
    whether or not the first record was cleaned up.
  - Alternative rejected: key on the seshy session name alone. Rejected because
    `wtrun` is used outside a seshy session, and `repo.Workspace` already falls
    back to the git top level and then to the directory itself.

- Decision: the watch renderer takes a directory and keys it internally, the way
  `newBus` at `watch.go:302` already does. `repo.Workspace` returns a directory
  path, and `watch.go:233` rejects a session containing `/`, so the guard MUST apply
  to the derived name rather than to the argument. `WTRUN_SESSION` keeps its meaning
  as a literal key, which is still slash-free.
  - Alternative rejected: have the caller spell the derived `basename-digest16`
    name. Rejected because nothing prints that name, so the key becomes unspellable
    by the owner at the moment the watch keybinding is the thing that needs it.
  - Alternative rejected: drop the `/` guard. Rejected because it is what stops a
    session name from escaping the state root, and `newBus` shows the guard is
    unnecessary only once the argument is resolved with `filepath.Abs` first.

- Decision: `waiting` is declared by the run and published through the state bus
  that already exists. A run that knows it is blocked calls
  `sysinit-agent agent-state`, which `agentstate.go:231` writes to the WezTerm user
  var `agent_state` and to a pane record under the agents path. `--status` reads
  the worker pane's record, and the blocked-wait mode watches it.
  - Alternative rejected: a new state file under the wtrun path, which the first
    draft of this design specified. Rejected because it is a second publication
    path for one fact. `panes.lua:57` reads the user var and validates it against
    `panes.lua:6`, whose top-ranked value is already `waiting`, and
    `ui.lua:174`, `ui/tabtitle.lua:48`, `ui/session_tree.lua:50`, and
    `ui/switcher.lua:98` read the same value. A worker-only file would make
    `--status` say `waiting` while all five of those said `working` about the same
    pane. This change's stated goal is removing duplicated readers, so adding a
    writer is the wrong direction.
  - Alternative rejected: infer it from output silence. Rejected because it
    reports a slow link step as blocked, which is a guess dressed as a fact.
  - Alternative rejected: infer it from the pane fields WezTerm exposes. Rejected
    on evidence: `wezterm cli list --format json` exposes `cursor_shape`,
    `cursor_visibility`, `cursor_x`, `cursor_y`, `cwd`, `is_active`, `is_zoomed`,
    `left_col`, `pane_id`, `size`, `tab_id`, `tab_title`, `title`, `top_row`,
    `tty_name`, `window_id`, `window_title`, and `workspace`. None of them says
    whether the foreground process is reading input. This rules out inferring the
    state from WezTerm; it does not rule out publishing it to WezTerm, which is
    what the user var is for.
  - Alternative rejected: infer it from the process state on `tty_name`. Rejected
    on evidence: macOS `ps -o wchan` prints an empty column, and `STAT` separates
    sleeping from runnable without separating a tty read from any other sleep.
  - Consequence that MUST be stated in the skill: `waiting` is opt-in. A command
    that blocks without declaring it is reported as running. This is the same
    contract every harness pane already has, since `agent-sessions.sh` learns the
    word from a hook the harness fires.
  - Consequence the first draft did not state: opt-in leaves this with one
    producer, a harness run inside the worker pane. `sysinit-notify.ts:78` is the
    only caller that declares `waiting` today, and `SKILL.md:18` documents the
    worker as the place for builds, switches, test suites, and `nix` evaluations,
    which declare nothing. So `waiting` reports for a run that is itself an agent
    and for nothing else this repository runs.
  - Consequence that conflicts with the workspace key: a harness parked at a prompt
    holds the shared worker for as long as it waits, and the run-name refusal above
    then fails every other run in that workspace. One worker per workspace and a
    long-blocking run in it are the same resource.
  - Consequence the owner accepted on 2026-08-11, having been shown it: a worker's
    `waiting` flips its whole session's status. `agent-sessions.sh:121-139` filters
    only on pane liveness, groups on `.session`, and takes the max rank, and
    `agentstate.go:92-97` fills `Session` from the process cwd, which the body makes
    the caller's directory. So a build waiting on a sudo prompt reads, in the status
    line and at the top of the switcher, like the agent in that session being blocked
    on the owner. The switcher row is labeled `in worker`; the session rollup is not,
    because it does not read the agent field.
  - Consequence: a worker that publishes its own state never notifies.
    `ui.lua:172-175` fires `agent-notify` only for a pane that carries no
    `agent_state` var, so publishing is what suppresses the notification. `waiting`
    on a worker is a visual signal in the switcher, the status line, the tab title,
    and the session tree, and it is not a notification. The skill MUST say so, since
    an owner who reads `waiting` as "I will be told" would wait for a notification
    that is suppressed by design.

- Decision: the clear writes the ranked status `idle`, and it MUST NOT use `exit`.
  `agentstate.go:58-62` handles `exit` by removing the record and returning, above
  the `emitUserVar` call at `agentstate.go:84`, so `exit` never updates the user var.
  WezTerm holds a var for the life of the pane and `panes.lua:59-66` prefers the var
  over the record, so `exit` would leave `--status` reporting idle while the status
  line, tab title, switcher, and session tree still read `waiting`. That is the exact
  divergence the worker-only state file was rejected for, so `exit` reproduces the
  defect its replacement was chosen to avoid.
  - Accepted cost: writing `idle` keeps the record, so the worker pane stays
    registered as an agent pane. `switcher.lua:172` lists any pane whose status is
    non-nil and `agent-sessions.sh:123-137` counts it in the session's panes. The
    owner accepted this on 2026-08-11 in preference to the divergence.
  - Alternative rejected: `exit`. Rejected on the evidence above. Note that
    `sysinit-notify.ts` in the pi, atomic, and prime-agent bridges all call `exit`
    today, so a harness pane already keeps its last ranked var after the harness
    exits. That is a pre-existing defect in those bridges, not a precedent to follow,
    and it is out of scope here.
  - Alternative rejected: leave it for the next run to overwrite. Rejected because
    a run that declares itself blocked and then finishes would leave the workspace
    reporting `waiting` for as long as the worker pane lives, which makes every
    later blocked-wait return at once and name a run that ended.
  - Alternative rejected: let pruning clear it. Rejected because pruning keys on
    whether the pane exists, and the pane is alive in exactly this case. The
    proposal requires that pruning MUST NOT remove state under a live pane, so
    pruning cannot be the owner of this.

- Decision: the clear has three owners, because no single one covers every way a run
  can stop. The first draft named one, and named it in a place that does not exist.
  - The generated `.cmd` body installs a zsh `trap` on `EXIT INT TERM HUP` that
    writes `idle`. This is what makes the clear survive a signal. The first draft
    said the body clears "in the same place `wtrun.sh:140` already removes the
    `running` file", which names two different places: the body at
    `wtrun.sh:129-133` holds three lines and no `rm`, and the `rm -f running` is the
    tail of the interactive line sent at `wtrun.sh:140`. Ctrl-C makes the worker's
    zsh abandon the rest of that line, so neither the `rm` nor `echo $? > rc` runs.
    A trap inside the body runs; the tail of an abandoned input line does not.
  - `--close` removes the worker's record file directly, before killing the pane. It
    cannot go through `agent-state`, which keys on its own `WEZTERM_PANE` and writes
    the OSC to its own tty, so a caller clearing another pane's state would write the
    var onto itself. It does not need to: killing the pane discards that pane's user
    vars, so only the record file outlives it.
  - Accepted residue: a worker pane closed by the owner rather than by `--close`
    leaves its record behind. Every reader filters on pane liveness first
    (`agent-sessions.sh:127`), so the record is inert, and the var died with the
    pane. This is residue, not divergence, and the prune MUST NOT be extended to the
    agents path to chase it.
  - Alternative rejected: one owner, in the tail of the line sent to the worker's
    interactive shell, which is where the first draft put it. Rejected because that
    tail is abandoned on Ctrl-C along with the rest of the input line, and because it
    cannot cover `--close`, which kills the pane from the caller's process.
  - Alternative rejected: clear only in `--close`, and let the trap go. Rejected
    because `--close` is the rare path. A run that finishes normally is the common
    one, and it would leave `waiting` set on a live pane.

- Decision: `waiting` is attributed to a run by correlating the pane record with the
  `worker-running` marker, and never by the record alone. The record has no run
  identifier: its fields are Version, Mux, Pane, Session, Repo, Branch, Dirty,
  Worktree, Agent, Status, Reason, Since (`agentstate.go:29-42`), and it is keyed on
  the pane (`agentstate.go:56`). One worker per workspace means every run in the
  workspace reads one record, so `waiting` on its own says "something in that pane is
  blocked", not "your run is blocked". A blocked-wait returns blocked only when
  `worker-running` names the caller's own run, and `--status` reports `waiting` only
  while that marker names a live run.
  - Alternative rejected: read the record alone. Rejected because a run still sitting
    in the tty input buffer has executed nothing, so a caller waiting on it would
    return on a different run's block and name a run that never started a line. That
    is the false blocked this design rejects over-reporting to avoid.
  - Alternative rejected: add a run field to the record. Rejected because it changes
    the pane-record schema, which is a non-goal, and because the marker already holds
    the run name and is written by the same body.
  - Consequence: a state written by something `wtrun` did not launch is not reported
    as a worker run. The worker is an ordinary interactive shell, split with no program
    argument (`wtrun.sh:116`), so the owner can type into it and start a harness there.
    `agentstate` keys on the pane, so that harness owns the record. Without the
    correlation, `--status` would report the worker as blocked while `wtrun` has no run
    at all. Residue makes this concrete: 5 of the 9 pane records on this machine name
    panes that no longer exist, and one of those carries `working`.

- Decision: the blocked wait is its own flag, not a third outcome on `-w`. This
  resolves what the first draft deferred as a naming choice that "does not change the
  mechanism". It does: `-w` has exactly two outcomes today, the command's own status
  (`wtrun.sh:167`) and 75 on timeout (`wtrun.sh:160`), and a caller branches on `$?`.
  A blocked return on `-w` would be a code the caller reads as the build's result, so
  it would be a fourth compatibility exception.
  - Alternative rejected: a third outcome on `-w` with a distinct code. Rejected
    because every code is either one the command can produce or a new contract on an
    existing flag, and the exception list is already three long.
  - Alternative rejected: return 0 on blocked. Rejected because a caller would read a
    blocked run as a successful build.

- Decision: the worker record carries the mux generation in a file of its own,
  `worker-mux`, written before `worker-pane` so a partial write reads as no record.
  Reuse rejects a worker from another generation, and treats absent, empty, and 0 as
  no state. `agentstate.MuxID` already computes the marker, exported so the two
  definitions of a generation cannot drift; the pane record's schema is untouched.
  A caller with no generation of its OWN refuses the invocation rather than splitting,
  because the record it would write is equally unverifiable, so splitting means one
  new pane per invocation and none of them reachable by `--close`.
  - Alternative rejected: rely on `pane_alive` alone, which is what the first draft
    specified. Rejected because pane ids restart with the mux, and the workspace key
    removes the collision that used to hide it. Reaching stale worker state used to
    require both the caller's id and the worker's id to recur; keyed on the workspace,
    it requires only the worker's. A `worker-pane` holding a low id, which a fresh
    generation allocates first, then passes `pane_alive` against an unrelated pane and
    a command is sent to a stranger.
  - Alternative rejected: rely on `reapDeadMuxes` to clear the stale record.
    Rejected on evidence: it runs only on a write, and `agentstate.go:289` skips any
    record whose `Mux` is 0. Five records on this machine carry `"mux":null` for panes
    that are gone, so nothing will ever remove them. A reader that treats 0 as current
    reads those as live state.

- Decision: the worker publishes with the agent name `worker`, not the default
  `agent`. `agentstate.go:46` takes the name positionally, so this needs no schema
  change, and `switcher.lua:34-56` renders it as `in worker`. A worker's row is
  therefore labeled as a worker wherever the agent name is rendered.
  - Known limit: `agent-sessions.sh` does not read the agent field at all, so the
    session rollup cannot distinguish a blocked build from a blocked agent. See the
    consequence recorded under the `waiting` decision.
  - Alternative rejected: the default name, `agent`. Rejected because the worker then
    renders identically to a harness pane in the one surface that does show the name,
    and a later filter would have no field to key on without a schema change.
  - Alternative rejected: the run's own name, so the row reads `in build`. Rejected
    because the field names which agent owns the pane, not which command is running,
    and the run name is already in the log path and in `--status`.

- Decision: the command runs in the caller's working directory. The generated
  `.cmd` body's first statement enters that directory and exits non-zero if it
  cannot, before the command, with the path shell-quoted. The header line names the
  directory, and the log records the one the body actually entered.
  - Alternative rejected: pass `--cwd` to `wezterm cli split-pane`. Rejected
    because it sets the directory once, at split time, and the whole point of the
    worker is that it is reused by later callers that are somewhere else.
  - Alternative rejected: leave the directory alone and document it. Rejected
    because the failure is silent: a build ran against the wrong flake and
    rewrote the wrong repository's `flake.lock`, and no output named a directory.
  - Alternative rejected: check the directory only in the caller's process, which
    the first draft of this design did. Rejected because the two events are minutes
    apart. `wtrun.sh:129` writes a body with no error handling and `wtrun.sh:140`
    records the status of its last command, so a failed `cd` would print one line
    and let the command run in the worker's directory under a plausible exit code.
    The header, printed at `wtrun.sh:146` before the body runs, would name the
    directory the command did not use. Both checks are needed: the caller's fails
    fast, the body's is the one that binds.

- Decision: a run name whose previous run has no exit-code file is refused. This
  extends the guard at `wtrun.sh:124`, which today compares only against the run
  currently executing.
  - Alternative rejected: keep the existing guard. Rejected because the workspace
    key makes two panes share the run namespace, and the existing guard reads the
    `running` marker, which is empty while a run sits in the tty input buffer. Two
    panes each running `wtrun -n build` would then share `build.log` and
    `build.rc`: the second truncates the log at `wtrun.sh:135` and removes the
    exit-code file at `wtrun.sh:110`, and the first pane's wait reads the second
    pane's status.
  - Alternative rejected: key the log directory on the pane while keying the worker
    on the workspace. Rejected because two keys is the thing this change removes,
    and `--status`, `--close`, and the watch subcommand would each have to know
    which key answers which question.
  - Consequence the first draft did not state: this is the third break in
    compatibility, and it removes something that works today. `wtrun.sh:110` clears
    the stale `.rc` unconditionally, so bash reuses any name. An interrupted run
    leaves a log and no `.rc`, which is how three names on disk got into that state,
    one of them in today's session. The refusal MUST therefore ship with a per-run
    release, so the owner can retype a name a Ctrl-C burned. The release clears that
    run's `.cmd`, `.log`, and `.rc` and nothing else. Its flag name is an
    implementation choice; its existence is not.
  - Alternative rejected: let the prune be the release. Rejected because the prune
    removes a whole record when the worker pane dies, so releasing one name would
    discard every other run's log in the workspace, and it is not reachable while
    the worker is alive, which is exactly when the name is burned.

- Decision: the flag parser is hand-rolled, matching `internal/editevent`'s
  `parse`, and a flag that wants a number MUST reject a non-number before any
  pane is created.
  - Alternative rejected: the standard `flag` package. Rejected for consistency
    with the neighbouring subcommands and because its usage-and-exit behavior
    would replace the `die` diagnostics that name the flag and the value.

- Decision: old `pane-N` state is ignored, and pruned once its pane is gone. On
  the first run after this ships, a `pane-N` record naming a live pane is reported
  on one line so the owner can close it, and is not adopted and not killed. That
  report MUST ship in the same phase as the cutover, not after it.
  - Alternative rejected: adopt the old worker once. Rejected because adoption
    would hand a caller a shell that may be halfway through a command, and the
    shim would then have to be found and deleted later.
  - Alternative rejected: kill the leaked pane. Rejected because it may be
    running a build the owner wants.
  - Alternative rejected: ship the report a phase later, which the first draft of
    this rollout did. Rejected because pane 434 is a live worker held under
    `pane-241` right now. Without the report, the first run after the cutover
    splits a second pane next to a visible worker, and the phase's only human gate
    is worded to reject exactly that observation. The gate would fail for the
    reason the design already accepted, which makes it useless for catching a real
    reuse defect.

- Decision: the prune considers only entries under the `agentWorker` root that are
  directories whose name matches `^pane-[0-9]+$` or the current key shape,
  `<basename>-<16 hex>` as `repo.keyed` produces it. The match MUST be anchored, and
  the current shape MUST be tested first, because a workspace whose basename is
  `pane-3` keys to `pane-3-<16hex>` and matches an unanchored `pane-*` too.
  Everything else it leaves alone, and it says how many it left.
  - Decision within it: the superseded `agentWtrun` root is removed whole, decided
    by the owner on 2026-08-11, rather than left on disk or swept entry by entry.
    Nothing under it is current shape and nothing new writes there, so the two
    branches the earlier draft left open, adopt or ignore, collapse: there is
    nothing to adopt and nothing to keep ignoring. This supersedes the by-hand
    deletion the earlier tasks 3.9 and 4.1 left to the owner.
  - Alternative rejected: sweep the old root entry by entry with the same anchored
    match. Rejected because it would preserve exactly the 296 flat artifacts the
    match cannot claim, which is the state the removal exists to end.
  - Decision within it: liveness is read from `<dir>/worker-pane`, never from the
    directory name. A `pane-N` name is the CALLER pane (`wtrun.sh:25`), and
    `worker-pane` holds the WORKER pane (`wtrun.sh:29`), so the two are different
    panes and only the worker's liveness makes the record live. The first draft of
    this decision said only "a record whose pane no longer exists", which does not
    say which pane, and the two branches disagree.
  - Alternative rejected: read liveness from the `pane-N` name. Rejected on
    evidence: `pane-241/worker-pane` holds `434`, and both are alive now, so the
    branches agree today and no test built from current disk state separates them.
    The moment caller pane 241 closes, that branch deletes `pane-241/` while worker
    434 is on screen. It would destroy the only pointer to a live pane, take the
    directory's other 31 entries including a 288 KB log written today, and silence the
    superseded-worker report that phase 2's gate depends on, since that report reads
    `pane-N/worker-pane`. Phase 3 would then manufacture the exact observation
    task 2.7 is worded to treat as a failure.
  - Consequence: task 3.5's test MUST construct a record whose caller is dead and
    whose worker is alive. Today's disk holds no such case, so a test written from
    it passes under either branch and proves nothing.
  - Decision within it: a liveness probe that does not answer means remove nothing,
    and the report line says so. The proposal already requires the call to be bounded,
    which says what happens to the call and not what happens to the records. The
    ambiguity is live in the tree: `wtrun.sh:35-36` pipes to `jq -e`, so an
    unreachable mux makes `worker_id` treat the worker as absent, and carried into a
    prune, absent means delete. On this machine that reading deletes all four records
    including the one naming live pane 434.
  - Alternative rejected: treat an unanswerable probe as absent, which is what the
    existing script's idiom implies. Rejected because it makes an unreachable mux a
    delete-everything trigger on a routine operation.
  - Alternative rejected: retry until the probe answers. Rejected because the prune is
    a side effect of running a command, so it MUST NOT be able to delay the command it
    rides along with.
  - Alternative rejected: treat every entry under the root as a candidate key.
    Rejected on evidence: the root holds 303 entries, of which 4 are directories and
    299 are not: 296 regular `*.cmd`, `*.log`, and `*.rc` files from a layout that had
    no session directory, the `last.log` and `last.rc` symlinks, and a root-level
    `worker-pane`. Treating those as keys would have the prune reading
    `agentgateway-build.cmd` as a session.
  - Alternative rejected: extend the prune to clean the legacy flat files too.
    Rejected for this change: it is a one-time cleanup of a layout no code writes
    any more, and folding it into the prune gives a routine operation a
    delete-anything path. It is named in the Migration Plan as a separate manual
    step the owner decides on.

## Rollout & Gating

The default repo sequence applies: edit, `nix flake check`, `nh darwin build`,
owner spot-check, `nh darwin switch` from the `sysinit.laurel` checkout.

Phases ship in this order, and each MUST pass `go test ./...` and
`nix build .#darwinConfigurations.lv426.system` before the next starts:

1. The subcommand reaching parity with the bash script, keyed on the workspace,
   with the negative scenarios as tests. The bash script stays installed and stays
   the one the skill calls, so the subcommand is reachable but unused. This phase
   ships to the machine, because migration step 1 compares the two implementations
   on the same live state and cannot run before both are installed.
2. Every reader of the old key moves to the new one, the skill wrapper switches to
   the subcommand, the superseded-worker report lands, and `wtrun.sh` is deleted.
   Gate: the owner runs one real build through it.
3. `waiting`, the blocked-wait mode, and pruning.

There is no fourth phase. The first draft of this rollout had one, deleting a
duplicated manifest reader from `agent-sessions.sh` that does not exist. Removing
`wtrun.sh:12-23` is part of deleting `wtrun.sh` in phase 2, and nothing else in the
tree hand-rolls that reader.

Phase 2 is one commit for the deletion and the wrapper, so the revert restores both
halves together. The reader moves ship first, in their own commits, but they are
NOT independently correct and the first draft of this design claimed they were. A
reader moved to the new key is live the moment it is activated, and it resolves to a
path nothing writes until the wrapper switches. `keybindings.lua:260` is the case:
the watch key would open an empty log rather than fail visibly. So phase 2 MUST
reach the machine as one activation. Its commits are separable for review and for
the revert; its activation is not.

The kill switch for phase 2 is activating the previous system generation, which
restores the old `wtrun` in seconds with no build and no push. That is the fast
path and it MUST be the one written in the task, because the slow path runs through
the broken tool: `wtrun` on PATH is a store path installed through
`skill-tools.nix`, so it changes only at activation, and the applying checkout pins
this repository as `github:roshbhatia/sysinit`. A `git revert` therefore reaches
the machine only after a push, a flake update, and a full darwin build, and that
build is the exact workload `wtrun` exists to host.

`git revert` is still the durable fix, applied after the generation rollback has
restored a working tool. There is no runtime toggle, and there SHOULD NOT be one:
two implementations selected at runtime is the duplication this change exists to
remove.

A run in flight at activation time is not interrupted. The worker pane holds a
shell, and the store path the shell already started is not collected while it
runs. The next invocation gets the new implementation.

`SYSINIT_WORKER_SESSION` is the explicit key override. It is the escape hatch for a
caller that wants a worker of its own, and it is not a compatibility shim. It is
deliberately NOT the superseded `WTRUN_SESSION`, and not because the two would
collide: they read different roots. It is because `watch.go:222` reads
`WTRUN_SESSION` and resolves it under the OLD root, so honouring that name here
would aim the watcher at a path nothing writes, with no error. Task 2.9 repairs the
watch side, and until it lands the watch override keeps its own name and its own
meaning.

State keyed by that override is exempt from the prune, and the exemption MUST be
stated in the skill rather than left to be discovered. An override is an arbitrary
caller-supplied string, so `SYSINIT_WORKER_SESSION=build` writes `<root>/build/`, which
matches neither prune shape. A caller that takes a private worker therefore owns its
cleanup. The alternative, constraining the override to the keyed shape, is rejected
because the point of the hatch is a name the caller chooses and can type again. The
count the prune reports MUST separate override-shaped directories from the legacy
flat artifacts, so an accumulating hatch is visible rather than folded into the files
the owner has already decided to keep. The report states the count it measured rather
than a number fixed here, because the set is ambiguous at its edges: the root holds
99 `.cmd`, 100 `.log`, and 99 `.rc` names, of which `last.log` and `last.rc` are
symlinks, so 296 regular run artifacts, 298 counting the symlinks. The report MUST say
whether the symlinks are inside its count.

## Risks / Trade-offs

- [A regression here breaks every long-running command an agent runs] -> The three
  guards at `wtrun.sh:43`, `wtrun.sh:113`, and `wtrun.sh:121` become named tests
  rather than review notes, and phase 1 ships behind the unchanged bash script so
  a failure is invisible to the owner until phase 2. Named tests means tests that
  fail when the guard is removed, which is not the same as tests that touch the code:
  two of the three were implemented and unprotected, and dropping the focus return or
  the queued-behind report left the suite green. Each of the three now has a mutation
  recorded against it in `review.md`.

- [Phase 2 deletes the only working implementation in one commit] -> It is gated
  on the owner running a real build through the new one, which is the
  human-verification checkpoint in `tasks.md`. Recovery is the previous system
  generation, not the revert; the revert is the durable fix applied afterwards.

- [Changing the key leaks one live worker per caller pane that ever ran wtrun, not
  one per workspace] -> The old key is per caller pane (`wtrun.sh:25`), so the bound
  is per caller pane. Four such records accumulated between 6 and 11 August; only one
  names a live worker today, which is timing rather than a bound. Phase 1 keeps the
  bash script as the one the skill calls, so it mints another record per caller pane
  right up to the cutover, and two live workers under distinct old keys in one
  workspace is reachable. The report therefore enumerates every superseded record
  whose worker is live, and the gate accepts N extra panes when the report names N.
  The first draft said "at most one per workspace" and the gate was worded to reject
  a second, which would have failed on a state the design accepts.

- [A superseded record cannot be attributed to a workspace] -> No `pane-N` record
  stores a directory. Its contents are `worker-pane`, `worker-runs`, the run
  artifacts, and the `last.*` symlinks, and the log header at `wtrun.sh:136-137`
  prints the name, the date, and the command with no directory. So the report names a
  leaked pane id and cannot say which workspace it served. The owner identifies the
  pane by what is on its screen, and the final confirm says so rather than asking them
  to accept state they cannot attribute.

- [Two panes in one workspace share the run namespace] -> A name whose previous run
  has not recorded an exit code is refused. Without that, the second caller
  truncates the first's log and the first reads the second's exit code, which is
  silent and needs no race.

- [`waiting` is opt-in, so it under-reports] -> Stated in the skill. Under-report
  is the safe direction: a caller that waits for blocked and gets nothing waits
  out its timeout, where an over-report would return a false "blocked" and the
  caller would act on it. This holds only because the marker is cleared when the
  run ends; a marker with no owner would over-report permanently.

- [Reporting `waiting` through the shared bus means a worker run writes the same
  pane state a harness writes] -> Correct and intended: it is one pane and one
  state. Three costs follow and all three are accepted rather than mitigated: the
  session rollup cannot tell a blocked build from a blocked agent, the worker stays
  registered as an agent pane because the clear writes `idle` rather than removing
  the record, and the worker never notifies because publishing the var is what
  suppresses notification. The switcher labels the row `in worker`; nothing else does.

- [The clear must survive a signal, and the first draft's clear did not] -> A zsh
  trap in the body on `EXIT INT TERM HUP`, plus an explicit removal in `--close`.
  Ctrl-C at a blocked prompt is the reproduction, and it is one keystroke, so this is
  a named test rather than a review note. The residue that remains is a record under
  a pane the owner closed by hand, which every reader ignores because it filters on
  liveness first.

- [The tty input buffer is still the queue] -> Unchanged from today, and named as
  a non-goal so the subcommand does not grow an ordering claim it cannot keep.

- [Running the command in the caller's directory changes behavior for a caller
  that relied on the worker's] -> Deliberate, recorded as one of the two
  exceptions in the proposal. No known caller relies on it; the owner judges this,
  since no command can prove the absence of such a caller.

## Migration Plan

Step 0 exists because the later steps compare against a baseline that running the
tool destroys. The prune is a side effect of running a command, and on this machine
`nh darwin switch` itself runs through `wtrun`: `pane-241/citelockfix-switch.cmd`
holds `cd .../sysinit.laurel && nh darwin switch . --update`, and three sibling
`*-switch.cmd` files have the same shape. So each phase's own Apply step is a wtrun
invocation, and the first invocation after phase 3 activates prunes.

0. Capture the baseline from a plain shell, BEFORE phase 3 is activated. For every
   key-shaped directory under the state root, record its name, the id in
   `<dir>/worker-pane`, and whether that id appears in
   `wezterm cli list --format json`. Counts alone are not a baseline: they cannot say
   which record went.
1. Verify: with both implementations installed after phase 1, establish the
   precondition first by recording `pane-$WEZTERM_PANE/worker-pane` and confirming
   that id is live at the moment of the comparison. Create a worker through the bash
   script immediately before comparing if none is live. Then run
   `sysinit-agent worker --status` and the bash `--status`. They are expected to
   DISAGREE: the script names the worker and the subcommand reports none. Agreement on
   "no worker" means the precondition lapsed, not a defect. That distinction matters
   here because the only superseded record naming a live worker is keyed on a
   conversation pane, and closing that pane is the ordinary end of a session.
2. Switch the wrapper and delete `wtrun.sh` in one commit, with the
   superseded-worker report already in place.
3. Confirm: the owner runs one real build through `wtrun` and reads the exit code,
   the log tail, and the directory it reported. Extra panes are expected, one per
   superseded record whose worker is live, and the report names each. N extra panes
   with N named is the pass; any extra pane the report did not name is the failure.
4. Verify: run the prune's report-only form, which names each candidate directory, its
   recorded worker, and its verdict. This is what makes step 5 a comparison of decided
   sets rather than an inference from counts.
5. Prune, then assert set equality against step 0: the directories removed equal
   exactly those whose recorded worker was absent, and every directory whose recorded
   worker was live survives. Checking that the flat artifacts did not move is NOT the
   check. The prune enumerates directories and no flat entry is a directory, so that
   invariant is true of any implementation, including one that deletes every record.
6. Decide: the owner decides whether the legacy flat artifacts AND the dead root
   `worker-pane` are deleted by hand. The root `worker-pane` holds `298`, a pane that
   does not exist. It is a worker record under the same filename the prune reads, but
   it sits at the root, so the prune never considers it, and it is not a `.cmd`,
   `.log`, or `.rc`, so deleting the run artifacts leaves it behind. Naming it here is
   what stops a dead worker record surviving the whole migration.
7. Confirm: the owner accepts the remaining state, including any live worker the
   old key leaked. A superseded record stores no directory, so the owner identifies
   each leaked pane by what is on its screen rather than by workspace.

## Open Questions

Answered. Whether the blocked-wait mode is a new flag or a value on `-w` was deferred
as a naming choice that "does not change the mechanism". `wtrun.sh:167` falsifies that:
`-w` exits with the command's own status, so a third outcome on it is a new contract on
an existing flag. It gets its own flag, decided above.
Answered, and recorded here because the first draft deferred it wrongly. Whether
`agent-sessions.sh` reads the wtrun worker's state was listed as out of scope on the
grounds that it "would change the pane-record schema, which is a non-goal". It
changes no schema. `agent-sessions.sh:121-139` reads every pane record with pane
liveness as its only filter, so publishing through the bus makes it read the worker's
state by construction. The question is not deferred; it is decided by the `waiting`
decision, and its cost is recorded there.

Whether `waiting` earns its phase was put to the owner on 2026-08-11, with the
no-producer finding and the clearing defect in front of them. They chose to keep it
and design the clear, which the two decisions above now specify.
