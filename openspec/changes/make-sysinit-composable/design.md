# Design

## The one defect behind all of it

Three subsystems each own two jobs: they produce a fact, and they render that
fact into a surface the owner is looking at.

| Subsystem | Produces | Also drives |
| --- | --- | --- |
| `wtrun` | command output | a wezterm pane, by simulating keystrokes |
| `diffnote` | review notes | a running neovim, over msgpack-RPC |
| `agent-state` | session state | nothing: see the note below |

That second column is the whole complaint. An agent that wants to record a fact
cannot do so without also moving something on the owner's screen.

`agent-state` was in that column in an earlier draft, for its OSC `SetUserVar`
write, and adversarial review removed it. A user var is not a surface the owner
is looking at: it is a value attached to the pane, which the status bar may read
or ignore, and which dies with the pane. Nothing moves when it is written. The
archived change that chose it
(`archive/2026-07-08-surface-agent-session-state/design.md:49-59`) picked it
over a per-pane file precisely because that lifetime removes a class of stale
state, and this change does not answer that reasoning. So the write stays.

That forces the rule below to be stated as who initiates and into which stream,
rather than as a rule about touching the terminal at all. An agent may write to
an output stream about itself. It may not write to an input stream, and it may
not move a surface the owner did not ask it to move. `SetUserVar` is the first.
`send-text` is the second. The distinction is the whole of phase 2.

This violates the Single Responsibility Principle in its actual formulation:
a module should have one reason to change. `wtrun` changes when the way we run
commands changes, and again when the pane layout changes. Parnas made the same
point in 1972 in "On the Criteria To Be Used in Decomposing Systems into
Modules": a module boundary should hide a design decision that is likely to
change independently. "Where output is shown" and "what output is" are exactly
two such decisions, and they are currently in one module.

It also violates Command-Query Separation. `diffnote add` mutates the store and
performs a visible side effect. A caller cannot record a note without also
opening a window, so the cheap operation and the expensive one cannot be
separated.

## Evidence

`modules/home/programs/llm/skills/wtrun/wtrun.sh:102` splits the caller's own
pane. `:106` sleeps one second and then re-activates the original pane, which is
a race with nothing synchronizing it. `:126` drives the worker shell by sending
a `\025` (Ctrl-U) followed by the command text as simulated typing.

That last line is the worst construct in the repository. Page-Jones would call
it connascence of timing and connascence of position between two processes: the
sending script and the receiving shell must agree on the input line's state, on
the keystroke that clears it, and on the shell being ready to accept it. Those
are the strongest and least local forms of coupling, and none of them is
checkable. The `\025` prefix exists because the coupling already failed once.

`pkgs/sysinit-agent/internal/nvimlink/nvimlink.go` dials a neovim socket and
executes `require("harness.diffnote").refresh()`. A Go package names a lua
module inside another process. That is Feature Envy across a process boundary,
and it breaks the Law of Demeter twice over: the CLI talks to the editor, which
talks to its own plugin.

`pkgs/sysinit-agent/internal/agentstate/agentstate.go:329` forks
`wezterm cli list` on every single tool call, inside `paneWorkspace`, to learn
the pane's workspace. That is a per-tool-call subprocess against the terminal's
own CLI, and it is the terminal coupling that survives after the keystroke
paths are gone. It cannot be replaced by an environment variable, because no
variable carries the workspace, so the fix is to cache it per pane.

## Decisions

### 1. Producers write files. Presenters read files. Nothing drives.

Every subsystem keeps only its first column. Facts go to a documented path
under `$XDG_STATE_HOME/agents/`. Presentation becomes a separate process the
owner starts, by hand or by keybinding, in whatever pane they choose.

"Nothing drives" rather than "nothing pushes", because the retained OSC write
is a push by any literal reading and it stays. What it does not do is drive: it
sets a value with no reader obligation and no effect on screen position, and it
expires on its own. The mirror deleted in decision 2 fails that test, since it
puts a note into another program's live display.

- Decision: keep the OSC `SetUserVar` write in `internal/agentstate`. An earlier
  draft of this change deleted it. That was a reversal worth recording, because
  it was wrong twice. A program reporting its own status to its own terminal is
  self-report, not remote control, so this rule never reached it. And
  `archive/2026-07-08-surface-agent-session-state/design.md:49-59` already chose
  the user var over a per-pane file, for a reason this change does not answer: a
  user var dies with its pane and a file does not. Claude and pi wire an exit
  hook, so their files are cleaned up. Codex and opencode do not, so they leave a
  record reading `working` forever, and a crash does the same for all four.
- Alternative rejected: delete the OSC write and keep the file bus alone. It
  would have traded a self-report for a class of permanently stale records, and
  it would have re-decided a settled question with no new evidence.

- Decision: `agent-state` no longer resolves the wezterm workspace. The
  per-tool-call fork of `wezterm cli list` is deleted, and readers that want the
  workspace fallback resolve it live.
- Alternative rejected: cache the workspace in the pane record. That amortizes
  the fork instead of removing it, and it is wrong on its own terms. A workspace
  is a per-pane fact stored under a bare pane id, and wezterm reuses pane ids, so
  a cached value serves the previous occupant's workspace. `ui.lua` reads it live
  on every tick while `agent-sessions.sh` would group by the cached one, giving
  one pane two session names with nothing comparing them.
- Alternative rejected: substitute `$WEZTERM_PANE` for the fork. It returns the
  pane id, not the workspace, and the id is already in hand at the call site.

- Decision: delete the `$EDITOR` shim in `utils/wezterm_terminal.lua`, along with
  `utils/remote_editor.lua`, its only consumer. An earlier draft kept it, on the
  reason that the owner runs `git commit` and the shim is what makes it open in
  their existing neovim. That reason does not survive its own evidence. The
  owner's shell never sees the shim: `modules/home/default.nix:41` sets
  `EDITOR = "nvim"` for the whole home configuration, and the shim was installed
  only by `editor_env`, which `_spawn` merged into every pane it creates. Every
  path through `_spawn` spawns an agent CLI into a new pane, so the shim reached
  agent panes and nothing else. `harness/preview.lua` never reaches `_spawn` at
  all, having its own inline split, so `<leader>jp` never got it either. It was a
  pure agent route, and it is the composite this phase exists to remove: it
  activated the owner's pane, drove the owner's editor, and blocked the caller
  until the owner wrote the buffer.
- Alternative rejected: keep the shim and accept the coupling. It is the same
  `nvim --server ... --remote-expr` construct as `internal/nvimlink`, which this
  change deletes and which this document calls Feature Envy across a process
  boundary. Keeping one instance of a construct while deleting the other on
  principle is not a decision, it is an exception with no rule.
- Consequence, recorded rather than hidden: an agent that runs `git commit` with
  no `-m` now opens nvim nested inside its own pane. That is worse for the agent,
  and that is the point. The cost lands on the process that chose to open an
  editor.

- Decision: `dismiss_start_screen` moves from the deleted `harness/control.lua`
  into `harness/preview.lua`, its only surviving caller. No task named it, and
  deleting `control.lua` wholesale would have broken `<leader>jp`, which task 2.7
  keeps on purpose as an owner keymap. It qualifies to survive on this phase's own
  rule: it closes a floating dashboard in the local editor, moves no pane, and
  answers no request.
- Alternative rejected: delete it with the rest of `control.lua`. `<leader>jp`
  would then open its preview split behind whatever dashboard was floating, which
  is a visible regression in an owner path this phase set out to protect.

This is the Unix rule McIlroy stated: write programs that do one thing, and
write programs to work together. It is also the X11 "mechanism, not policy"
rule. sysinit supplies the state files, which is mechanism. Which viewer reads
them, and where it runs, is the owner's policy.

The direction of control inverts: the viewer polls or watches, the agent never
calls out. That is the Hollywood principle, and it is what makes the pieces
synergistic without being dependent. An agent with no viewer running still
records everything. A viewer with no agent running still opens.

Rejected: an event bus or a daemon. A socket needs a lifecycle, a reconnect
policy, and an answer for what happens to events emitted while nothing is
listening. A file has none of those questions, and every producer here already
writes files. The filesystem is the bus we already have.

### 2. The note file is ours. `hunk` is a reader of it.

`hunk` was in this repository and was removed on 2026-08-05 in
`878f78300`, whose proposal states the reason: "Diff review consolidates on
neovim, so hunk goes and the annotated diff becomes ours to build."

That decision produced the coupling this change exists to remove. Consolidating
review on neovim is what forced a CLI to learn how to drive neovim.

An earlier draft of this decision said to delete `diffnote` outright, on the
claim that its command surface was a re-implementation of hunk's. Adversarial
review refuted that claim. The conclusion holds and the refutation's reasoning
does not, so both are recorded here rather than the tidier one alone.

That refutation argued from the documented `hunk session comment add` surface: it
carries `filePath`, one line selector, and `summary`, and so carries no second
body field, no author, and no upsert, leaving three of our fields with no target.
Task 3.1 probed the binary instead of the documentation and refuted all three.
`openspec/changes/make-sysinit-composable/hunk-probe.md` has the evidence.
`rationale` and `author` are first-class fields on BOTH of hunk's surfaces, the
sidecar annotation carries an optional `id` that is exactly an upsert key, and
the sidecar takes a line RANGE rather than one line selector. Reading the
documentation for a capability question is the mistake 3.1 was written to
prevent, and it caught one.

So "deleting them is not a feature loss" was false for a different reason than
the one given. `--rationale`, `--author`, and `--replace` are not data with
nowhere to go. They are data whose home is a viewer, and the record has to
outlive the viewer. Keep them because the note store is ours and answers when no
hunk is installed, which is the ordinary state on the non-Nix path phase 9
builds, not because hunk cannot represent them.

One thing that reasoning bought back: task 3.5 worried that `rationale` might
have to be flattened into a one-line field and that the loss would need
recording. It does not. `rationale` is a plain string with no newline handling,
so structure survives the boundary intact.

`diffnote` is not one tool. It is four responsibilities in one binary:

1. a durable note store (`internal/store`),
2. a CLI that appends to it (`internal/diffnote`),
3. a neovim renderer (`harness/diffnote.lua`),
4. a neovim launcher (`internal/nvimlink`).

Parnas says a module boundary should hide one decision. Three and four are the
coupling this change exists to remove. One and two are the thing that has no
other owner. So the split is by responsibility, not by binary:

| responsibility | after |
| --- | --- |
| durable note store | kept: `internal/store`, unchanged |
| append a note | kept: `sysinit-agent note add`, renamed from `diffnote add` |
| print the note file path | kept: `sysinit-agent note path` |
| render notes inside neovim | deleted: `harness/diffnote.lua` |
| launch neovim to show a note | deleted: `internal/nvimlink` |
| read and present the notes | `hunk`, as a consumer of the note file |

This is the Unix shape the owner asked for. One file, one format, one writer.
The viewer is a separate program that reads it. Remove `hunk` and the notes
still exist; remove the agent and `hunk` still reviews a diff.

What the two ends do know about each other is worth stating rather than
glossing. `review` knows hunk's `diff --agent-context` grammar and its store
path. The exporter knows the schema that flag expects. That is knowledge, and
claiming "neither knows the other's internals" would be false. The point is
where it sits: both facts live in `review` and the exporter, which exist to
hold them. The writer and the store know nothing about hunk, and hunk knows
nothing about our on-disk shape. Two named adapters at one boundary is the
McIlroy arrangement. Knowledge smeared through the writer would not be.

`hunk` reads the file through `hunk diff --agent-context <file>`. That flag is
viewer-side, so a plain `hunk diff` would show nothing. We close that hole with
`review`, a command that supplies the flag and passes everything else through,
so `review --watch` carries the flag. Whether carrying it is enough is a
separate question, settled by the probe in task 3.1 rather than assumed here.

`review` is a separate verb, not a wrapper named `hunk`. Shadowing the binary
would break this change's own non-goal from the other side: one name for two
things, a collision on `bin/hunk` in a single home profile, and `which hunk`
unable to say which one ran. A new verb composes; a shadow hides.

Nothing pushes, and that is a constraint on this decision rather than a
description of it. An earlier draft had the writer probe `hunk session get` and
push each summary to `hunk session comment add` whenever a session was live.
That is decision 1's forbidden second column wearing a new label: `note` would
produce a fact and also drive a surface. It is deleted. The viewer reads the
file; the writer never calls the viewer. A missed refresh is then the viewer's
problem to re-read, which is recoverable, rather than a one-shot push whose
failure leaves the display permanently wrong.

The cost of that is honest, and an earlier draft understated it twice. Without
a push, a note written after the viewer started reaches it only if the file
hunk re-reads actually changes. So the export is not a one-shot command: the
writer republishes it inside the same store lock that publishes the record, on
every write. And whether `hunk --watch` re-reads that file is a fact to probe
rather than assume, which is why task 3.1 probes it and task 3.10 checks the
write-after-start case either way. If it does not re-read, the live workflow is
to re-run `review`, and this document will say that.

If the probe in task 3.1 finds that `--agent-context` expects hunk's own
`filePath` and `newLine` vocabulary, the answer is a derived export the writer
republishes on every write, serialized at the boundary. That is not a second format: the file on disk stays one format
with one writer, and a serializer is what a boundary is for. It also gives
`author` and `rationale` a reader again, which they otherwise lose entirely
once the neovim renderer is deleted, because `note list` prints only
`file:line summary`.

`hunk session get --repo .` answers "is there a live session for this
directory", which is the autodetect the owner asked for, and it is upstream's
job rather than ours.

`hunk skill path` returns a skill file. Our harnesses already mount skills
through `modules/home/programs/llm/skills/render.nix`, so the skill reaches all
eleven harnesses through machinery that already exists. It reaches them two
different ways, and an earlier draft of this paragraph named only one. Codex gets
`localSkillDescriptions` inlined into its instruction block, and it is the only
one: `instructions.nix:93` includes the `skills` section under
`lib.optional (builtins.elem harness harnessesWithoutSkillLoader)`, and `:32-34`
is `[ "codex" ]`. The other ten get the rendered skill file installed, through
`allSkills` (`render.nix:197`, consumed at `llm/default.nix:13`). Task 3.13
verifies both paths, because a check written for the block alone fails on ten
correct harnesses.

Rejected: delete `internal/store` and let hunk's session be the record. Every
durability property we have is asserted by a test here and by nothing there:
zero-byte recovery (`store.go:85-100`), fsync before rename (`:107-145`, the
one of these with no test of its own),
validate before rename (`:111-114`), symlink refusal (`:115-119`), a mkdir lock
with a double-release guard (`:52-83`), and control-byte stripping on
agent-authored text (`:167-197`). Trading six tested properties for an
undocumented store to save 714 lines is not a trade, it is a hope.

Rejected: keep `diffnote` as a name and shim it. Two names for one concept is
the "one word, one meaning" rule broken in code. The writer is renamed to
`sysinit-agent note`, because the noun is a note and the neovim part is gone.

Risk accepted: hunk's session daemon is an unauthenticated listener on
`127.0.0.1:47657`. Any local process can post a comment to an open session.
That is upstream's posture and we inherit it. It is bounded by the fact that
the daemon is only a notifier here: nothing we keep reads from it, so a forged
comment can display a wrong line but cannot corrupt the record.

### 3. `wtrun` becomes an owner command. It keeps its pane.

An earlier draft deleted the pane half and ran the command as a plain child
process. Adversarial review refuted it. `skills/wtrun/SKILL.md:45-63` documents
six guarantees and a child of an agent's tool call loses five: a tty for
`nh darwin switch` to prompt sudo on, a lifetime past the tool call,
fire-and-forget with a later `.rc` read, queueing through the worker shell, and
something to watch. The motivating case in the skill's own text is the one that
breaks first.

The defect was never the pane. It was an agent opening one. So `wtrun` is
unchanged and leaves the rendered skill set, which removes its description and
its `allowed-tools` grant.

That is a reduction and not a fence, and the change should say so. `wtrun` stays
on `PATH` because the owner needs it. The allowlist default is ask rather than
deny, pi runs with `yoloMode = true` and no entries at all, and any harness with
a Bash tool can call `wezterm cli split-pane` itself. Removing the
advertisement is the largest reduction available from inside this repository.

Rejected: a `--pane` flag preserving the old behavior. With the skill removed
there is nothing to gate: the flag would be an option on a command agents are
no longer told about.

### 4. One viewer, one contract.

A single `sysinit-agent watch` subcommand renders any of the state files: a
wtrun log, the agent-state bus, or a harness transcript. It resolves what to
show from the current directory, the same way `hunk session get --repo .` does,
and it is launched by the owner.

It takes its state path from the phase 4 paths manifest, which is why the
manifest phase runs before the viewer phase rather than after.

An earlier draft added that `internal/repo` dies here. It does not, and the
reasoning was circular: the premise was that its callers are all in the note
writer, and the conclusion assumed the note writer is deleted. Decision 2 keeps
the writer. `repo` also is not the kind of thing a manifest replaces. A manifest
is static; `repo.Root` answers "which repository is this process in" by running
git with `GIT_DIR`, `GIT_WORK_TREE`, and `GIT_INDEX_FILE` scrubbed, because a
hook-invoked agent inherits them pointing at whatever triggered the hook. The
manifest owns the prefix. `repo` owns the identity under it. Those are two
decisions, and Parnas says they belong in two modules.

### 5. Harness transcripts become files.

Each harness writes its turn output to
`$XDG_STATE_HOME/agents/transcripts/<harness>/<session>.log` in addition to
stdout. That is the owner's "stdout and a file" ask, and it is what makes the
viewer useful for more than wtrun.

The exact mechanism differs per harness and some may have no hook for it. Any
harness without one is recorded as uncovered rather than worked around, because
a scraped transcript would reintroduce the coupling this change removes.

## What this buys the non-Nix goal

Every item above reduces the fresh-box requirement. A viewer that reads files
needs no wezterm. The remaining wezterm dependency in the agent runtime is the
workspace lookup, which caching reduces to once per pane rather than removing.

One item moves the other way and belongs here as a cost. `hunk` arrives as a
flake input and `review` ships from a Nix module, so neither is on a bare box,
while `harness/diffnote.lua` was plain lua inside the config `bootstrap.sh`
symlinks. Review is less available without Nix after this change, not more. What
remains there is `note list` and the file itself, which is a weaker reader than
the one being deleted. That is the price of moving review out of the editor. An agent
that never types into a pane needs no particular terminal. What remains to install on
a bare box is a list of binaries and a lua directory, which is the shape the
profile and bootstrap phases already assume.

## Rollout & Gating

Phases are ordered so each one is independently revertable and none depends on
a later one. Removal precedes replacement in every case, because leaving both
paths live is how two names for one concept survive a migration.

The STOP gate for the coupling phases is the same in each: after the phase, a
grep for the removed channel returns nothing outside its own history.

The gates split by platform. `lv426` is `aarch64-darwin` and every gate touching
it runs on the owner's machine. `arrakis` is `x86_64-linux` and cannot evaluate
there at all, because its module set imports from a derivation. That half runs
in a CI job task 1.1 adds. An earlier draft made a local remote-builder a hard
precondition for the whole change; a workflow file is at least declared in the
tree, where a second machine configured out of band is the same defect phase 4
exists to remove, a fact held somewhere other than the repository. The evidence
for the runner is narrower than an earlier draft claimed and still sufficient:
`build-cache.yml:32-33` declares `os: ubuntu-latest` under
`system: x86_64-linux` and the installer at `:51` runs on every matrix cell, so
a Linux runner is reachable and proven to install Nix. Nothing in CI touches
`arrakis` today. `check.yml:42` stays on `macos-latest` for the reason its own
comment gives.

No gate realizes a host closure, which is what makes the CI half possible at
all. An earlier draft used `nix store diff-closures`, which needs two realized
closures in one store. The `lv426` system closure measures 17.5 GiB, and
`check.yml:86-90` already records that a runner has roughly 14 GB free and that
`nix build` of a host fails on disk there. Two do not fit, and on the owner's
machine they are a 35 GiB hold across eleven phases for a comparison that never
needed the bytes. `nix derivation show -r` answers the same question by pure
evaluation, measured at 7441 derivations in 9.9 seconds for `lv426`. Comparing
the set of derivation paths with the root excluded is not order-insensitive,
which an earlier draft claimed: a `buildEnv`'s own derivation is interior and is
computed from the order of its `paths`. Order preservation is therefore a
requirement on tasks 6.2 and 9.4. What the set buys over a bare hash is a
readable failure, since it names which derivations moved, and it sees build-time
dependencies that `diff-closures` cannot. It trades size for
identity, so task 6.6 keeps `nix path-info -S` where a number is the point.

Two costs are accepted rather than solved. A gate in CI cannot be run before
committing, so eleven phase boundaries each mean pushing and waiting; the Darwin
half still runs locally in about ten seconds, so this applies to the `arrakis`
half alone. And the workflow the job joins establishes a skip-when-absent idiom
at `build-cache.yml:53-63`, which is what the phase 3 STOP moved a check out of
the pre-commit hook to avoid, so 1.1 requires the job to fail rather than skip.

Building on `arrakis` at pull time was the alternative and does not replace
this. These gates are per phase, and their whole purpose is to name which phase
dropped a module. A check that runs after all eleven land reports the loss with
no such signal. It stays as a final confirmation.

## Risks / Trade-offs

`hunk` is a third-party dependency reached over a loopback daemon on port
47657. If upstream changes that API, review breaks. Accepted because notes can
be authored offline into a JSON sidecar, so the agent's write path never
depends on the daemon.

Deleting `agent-prompt`'s keystroke injection removes a real convenience: today
the owner can approve a tool call from a notification without returning to the
terminal. Nothing replaces that. The trade is deliberate, because a process
answering a permission prompt on the owner's behalf, up to 300 seconds later,
into whatever the pane is doing by then, is not a convenience that should be
recoverable by a flag.

Ten of eleven harnesses will have no transcript file. Five fire no hooks at all,
and codex, pi, opencode, devin, and gemini fire hooks whose payloads carry no
transcript reference. An earlier draft said seven fire none, counting
`scrapeBridged` (`runtime/default.nix:25-33`), which records a different
property: `devin.nix:20` and `gemini/default.nix:20` each render a `PreToolUse`
hook. Recording them as uncovered is worse for the viewer and better than
the alternative, which is scraping pane text.

`sysinit.theme.enable = false` is a path no host exercises. It will be correct
the day it is written and can rot silently.

The two host `drvPath` values are the only thing standing between the profile
refactor and a silent loss. A baseline captured after an unrelated edit makes
every later gate compare against the wrong value and pass while wrong.

## Adversarial Review

Run the `adversarial-review` skill at the end of every phase; each phase's task
list carries the entry. The critics that matter most, and what each should try
to break:

- Phase 2: argue that removing the keystroke injection makes the notification
  useless, and that the honest move is deleting the notification too.
- Phase 3: argue that `hunk session comment` does not in fact cover the whole
  diffnote surface, and find the specific subcommand or flag with no equivalent.
- Phase 4: argue that a generated path manifest will be bypassed by at least one
  consumer falling back to a hardcoded default, which is how the five
  derivations arose in the first place.
- Phase 5: argue that a viewer polling files is the same coupling wearing a
  different hat, and identify what makes it different if anything does.
- Phase 6: argue that `lib.optionals` gating drops a module from every profile
  rather than one, and that the `drvPath` gate would not catch it.
- Phase 9: argue that the generated `mise.toml` and the Nix list will drift, and
  that the pre-commit assertion checks the wrong thing.

A critic result is evidence, never approval.

### Round 1, run on the proposal before any code changed

The phase 3 critic returned "refuted" and it was right. It found that the
mapping table claimed a direct equivalence for fields hunk does not document:
`--rationale` has no target and cannot fold into `--summary`, which is reduced
to one line; `--replace` has no upsert, so it would become an unlocked
read-modify-write across processes; `--author` has no field; and
`--agent-context` is viewer-side, so a bare `hunk diff --watch` would show
nothing. It also found that deleting `internal/store` would drop six tested
durability properties with nothing asserting hunk has them, that the claim
"deleting `diffnote` does not weaken the editor" was false, and that the phase
STOP gate `rg -i diffnote modules pkgs` could not pass because `store.go` and
`main.go` contain the string in files the phase keeps.

Decision 2 was rewritten because of it, from "delete diffnote" to "the note file
is ours and hunk reads it". Three claims in the proposal were corrected. The
line figure was wrong for the same reason: 1,281 counted 714 source lines plus
567 of tests.

### Round 2, on phase 2 and phase 4

Two critics ran again on the rewritten tasks. Four results changed the design.

The `$EDITOR` shim was kept and is now deleted. The critic checked the reason
rather than the code and found `modules/home/default.nix:41` sets `EDITOR`
globally, so the shim reaches agent panes only. Section 10 records the reversal.

Task 2.7 claimed that after the deletions "nothing in this repository lets an
agent call `harness.api` at all". That is false: two socket-discovery routes
survive, and the repository documents both. The task now closes them instead of
proving a claim that was not true.

The phase 2 STOP gate could not pass. It required
`rg 'wezterm cli|send-text' modules/home/programs/neovim/config` to return
nothing, which was written for the draft of 2.7 that deleted the wezterm control
surface; 2.7 now keeps it. The gate also could not see nine of the thirteen
wezterm sites, because they use the argv-table form that no `wezterm cli` string
grep matches. It is now a comparison against a recorded set rather than a grep
for zero.

Phase 4 promised a check that no task created. The proposal's behavior list says
one place owns each state path, decided by a check that fails when
`.local/state` appears outside the paths module; the phase gated `ui.lua` alone.
Task 4.3 adds the check. `repo.go:60-65` says in its own comment that its
hardcoded fallback "is the one that runs in practice", which is why a fallback
left in place would make the manifest inert.

Two smaller corrections: phase 4 covered four of the five languages and dropped
`seshy/config.yaml`, and the liveness holes in 4.7 were understated. The reused
pane id is reached by restarting wezterm, not by an edge case, and the
reader-outside-wezterm hole stops being vacuous at task 5.1.

The phase 2 critic's line of attack was overtaken by the owner, who chose to
keep the notification surface and left its form to the author. A hook raising a
system notification satisfies it, and the agent deck stays. What phase 2 removes
is the injected keystroke that answered the prompt, not the signal.

### Round 3, on the new phase 10

Two critics ran on the zmx phase and independently found the same fatal defect,
which is now fixed.

The phase described `agentstate.go` as it reads today, said both the Go writer
and `agent-identity.sh` fall back to the terminal's workspace, and told the
implementer not to delete that fallback. It is true today and false when phase 10
runs. The dependency chain reaches phase 10 only after 2.2, and 2.2 deletes
`paneWorkspace`, its call, and the fallback, and moves that resolution to the
readers. Followed literally, the task restores
`exec.Command("wezterm", "cli", "list", ...)` into `pkgs/sysinit-agent`, fails
2.9's fifth clause, and reverses the phase 2 removal the proposal calls the one
that matters. The writer and the readers now get separate, stated orders.

The wezterm side of the phase was asserted rather than checked. The agent deck
groups by `win:get_workspace()` and never reads the record's `session` field, so
two zmx sessions in one workspace collapse to one group, and that is the case zmx
exists to create. `ui.lua` runs in the mux process and cannot read a pane's child
environment, so this is a decision, not a bug to fix in passing. Task 10.7 forces
it either way and 10.11 checks the surfaces by name rather than by count.

`agent-identity.sh:1-9` forks `wezterm cli list` unconditionally at `:16`. It is
the shell twin of the Go fork phase 2 deletes, and no clause of 2.9 could see it:
clause one greps for `send-text`, `activate-pane`, and `split-pane`, and clause
five is scoped to `pkgs/sysinit-agent`. Task 10.6 gates it behind the two cheaper
sources.

Two fixes for that were wrong before one was right, and both were caught by
checking rather than by reasoning.

The first was to widen 2.9 with a `cli list` pattern. `cli list` matches six files under
`modules/home/programs/llm`, and five fork it correctly and on purpose: `wtrun`
and its skill, which decision 3 makes an owner command, `agent-sessions.sh`,
which task 2.2's repair depends on, `agent-review.sh`, and `agent-focus.sh`. The
pattern is not a signal of the defect, so the clause would have grown from three
files to eight and gated less than before. The instrument was wrong rather than
the scope: 10.6 changes when the fork runs, the gated call and the ungated call
have identical text, and no grep separates them. Task 10.9 checks it by behavior,
with a stub `wezterm` and a marker file, in both directions, so that a gate is
distinguishable from a deletion.

The second wrong fix was where to put that stub. `agent-identity.sh` is never
installed as a program: it is read into a string and concatenated into two
`writeShellApplication`s, both of which list `pkgs.wezterm` in `runtimeInputs`,
and `writeShellApplication` prepends those to `PATH` ahead of the inherited one.
A stub on the caller's `PATH` is therefore unreachable, and the check would have
passed on the ungated fork and failed on a correct implementation, which is the
failure class it was written to avoid. The file is a function library with no
top-level side effects, so the test sources it directly instead.

Four smaller corrections. `si` was named as an edit site and is an fzf picker
that calls `s`, so editing both attaches twice. The seshy and zmx name agreement
was written as set equality and cannot be: a seshy session exists as a directory
with no process. `ZMX_SESSION_PREFIX` was put in the paths manifest for the
reason that it is a state path, which is not true of a namespace string. And the
phase asserted `ZMX_SESSION` inheritance from documentation with no probe task,
which is the standard task 3.1 sets for this change's other third-party
dependency.

### Round 4, the convergence round

Both critics ran to the end and neither found a FATAL. That is the first round
where nothing stopped a task from being completed and no gate could pass on a
wrong change. Recording it plainly, because a review that never converges is not
evidence of rigor.

What both found independently was one class, and it is worth naming because it
outlived every number check. A citation read once and stated in the wrong
direction. `modules/lib/shell.nix:9` was described as keeping `#!/usr/bin/env`
and `# shellcheck disable`; the function is `stripHeaders` and `:10` filters
with the negation, so it removes exactly those two and keeps every other line.
The token phase 4 defines was never at risk, and the line cited as the hazard is
the line that proves it safe. The only real residual is a token appended to a
`# shellcheck disable` line, which goes with it.

Two more of the same shape. Task 8.1 sent an implementer to `hosts/default.nix`
for the `values` schema; `lib/builders.nix:40-44` injects `hostname`,
`user.username`, and `isDesktop`, and the host file supplies two paths, `git`
and `theme`. Task 10.8 offered `desktop.nix:343` as a place to resolve `$sel`;
`:342` binds it from the payload it is handed, so the reconciliation belongs in
`agent-sessions.sh` where the value is built, which also settles the sketchybar
surface reading the same field.

One gate was weaker than it claimed. Task 3.5 asked for a concurrent test in the
shape of `TestConcurrentAddsLoseNoNote`, comparing the export against a rebuild
after concurrent adds. A lost add is permanent, so a post-hoc count catches it.
A stale export is self-healing: every writer republishes and `wg.Wait()` returns
after the last one, so the buggy version passes on every interleaving except the
one where an older read lands last, and nothing forces it. The gate is now an
ordering assertion on the release call, which fires on every call.

Two counts were also refined rather than corrected. The fourteen `values` paths
hold only if the search is scoped to `.nix`, because two Helm filenames in a lua
string match otherwise, and five of the fourteen are open attrsets rather than
leaves, so a schema treating them as leaves pins a shape their consumers never
agreed to.

The standing lesson is smaller than a rule. A fold that changes a gate's
mechanism should grep the artifact for the old mechanism's words before it
lands. Six of these findings were a task describing another task's gate, or a
file's behavior, by a property it no longer had or never had, and no number
check can see that.

## Resolved questions

The owner delegated these four decisions. They are recorded here as decided, not
as owner approval of the change.

### 6. `minimal` is defined, and it IS the non-Nix set

Three profiles, and `minimal` is worth defining for a reason that also settles
what goes on an ephemeral box: they are the same list.

An agent box needs the shell, git, the agent CLIs, and an editor. It does not
need kubernetes, docker, terraform, or four language toolchains. That is exactly
the smallest useful profile. So `bootstrap/tools.toml` is not a second list
derived from the Nix one, it is the `minimal` profile's own manifest, and both
the Nix packages and the generated `mise.toml` read it.

Mapping the existing `packages.nix` groups:

| profile | groups | count |
| --- | --- | --- |
| `minimal` | core unix (`:7-42`), git (`:44-49`), shell (`:66-70`), agent CLIs (`:143-158`), plus `tree-sitter` and `ast-grep` | roughly 65 |
| `dev` | `minimal` plus go (`:72-85`), python (`:87-90`), rust and zig (`:92-94`), node (`:96-102`), lua (`:104-108`), and the language servers and formatters in (`:161-182`) | roughly 120 |
| `workstation` | `dev` plus nix (`:51-64`), kubernetes (`:110-122`), docker (`:124-129`), cloud and IaC (`:131-141`) | all 162 |

This removes the drift risk by construction rather than by a checker. The
generator assertion in task 9.4 stays as a backstop, but there is now only one
list to drift from.

### 7. The neovim config stays in this repository

It qualifies for extraction: zero `/nix/` paths, zero sysinit binary execs, its
own `lazy-lock.json`, and self-contained theming. Once `diffnote` is deleted it
has no sysinit runtime dependency at all.

It stays anyway. The only thing a second repository buys is a smaller clone, and
`bootstrap.sh` gets that with a sparse checkout instead. What it costs is atomic
cross-cutting changes, and those are real here: the twelve adapters under
`config/lua/harness/adapters/` track the same agent CLI list this repository
configures, so a new harness would become a two-repository change.

Commit `878f78300` moved this config INTO the repository three days ago,
reasoning that "one checkout holds the harness and the editor it opens".
Reversing that without new evidence is churn. Revisit only if the adapters stop
tracking this repository's harness list.

### 8. `ui.lua` becomes its own change, after this one

`modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` is 1,799 lines with
`M.setup` spanning `:9-1797` and nineteen nested closures. It is the worst file
here and it is not composability, so it stays out.

It goes second, not first. Phase 2.3 deletes its user-var path and phase 5.1
moves it onto the paths manifest, so decomposing afterwards starts from a file
with one less responsibility and one fewer path derivation. Doing it first would
mean rebasing this change onto it.

Follow-on change: `decompose-wezterm-ui`.

### 9. The `nvim-ctl` drive ops are deleted, not made opt-in

The earlier draft made them opt-in. That was wrong, because the entry point is
not in this repository at all.

- `config/bin/nvim-ctl` is on no PATH. No `.nix` file installs it. It is
  reachable only as `~/.config/nvim/bin/nvim-ctl` through the config symlink.
- The `nvim-walkthrough` skill that drives it is a real directory under
  `~/.claude/skills/`, hand-placed, not a store symlink, and no file in this
  repository generates it.
- Nothing in the repository references it except one document,
  `config/doc/agent-ide-integration.md`.

So this is 348 lines of `harness/control.lua` plus a 4KB script, exposing
thirteen unconfirmed editor-drive operations, reachable only through unmanaged
configuration. Making that opt-in preserves it; the reason to keep it does not
exist. Delete `control.lua` and `config/bin/nvim-ctl`, and remove the `control`
line at `harness/api.lua:199`, which is one line inside `M.setup` at `:196-201`
and not the whole of it: deleting the range breaks `harness.completion`,
`harness.instance`, and `harness.spec_watch`.

Keep `config/doc/agent-ide-integration.md`, which an earlier draft deleted along
with the code. That document is the only place in the repository recording how
an agent finds the editor socket (`:51-55`), and deleting the handler does not
delete the channel. Rewrite it to describe what survives.

If agent-driven editor walkthroughs are wanted later, they come back as a change
with a design, an owner, and a managed entry point.

### 10. The `$EDITOR` shim is deleted, because it has no owner use

Deleting `control.lua` removes the op handler, not the channel.
`nvim --server <sock> --remote-expr 'luaeval(...)'` reaches any lua module in a
running editor, and this repository hands an agent that socket two ways
(`doc/agent-ide-integration.md:51-55`).

The first is `harness/instance.lua`, which publishes the socket to
`$XDG_STATE_HOME/nvim/harness/instances/*.json` (`:6`). Its only reader in the
repository is `bin/nvim-ctl:30`, which section 9 deletes, so the publisher goes
with it.

The second is `EDITOR_WRAPPER` at `utils/wezterm_terminal.lua:46-58`. An earlier
draft kept it, on the reason that the owner runs `git commit` and the shim opens
it in their existing neovim rather than a nested one. That reason is false on
this repository's own evidence. `modules/home/default.nix:41` sets
`EDITOR = "nvim"` for the whole home configuration, and the shim is installed
only by `editor_env` (`:72-87`), which `_spawn` merges into every pane it creates
(`:96`). Every caller of `_spawn` is a harness adapter or `harness/lifecycle.lua`.
The owner's shell never sees the shim. It is installed into agent panes and
nowhere else.

So it is not an asymmetry to justify, it is the composite this change exists to
remove, in one file: `:53` activates the owner's pane, `:54` drives the owner's
editor, and `:55` blocks the caller until the owner writes the buffer. Focus
steal, editor drive, and turn block, all agent-initiated.

The cost is real and belongs in the record. An agent that runs `git commit` with
no `-m` now opens nvim nested inside its own pane, which is worse for the agent.
That is the correct place for the cost to land, because the process that chose to
open an interactive editor is the one that pays. This is the same rule as
decision 3: the fix is where the knowledge sits, not where the pain shows up.
### 11. `zmx` owns session persistence, and nothing else

`zmx` is a session manager whose stated argument against tmux is that windows,
panes, and splits "should be handled by your os window manager". That is the same
line this change draws in every other decision, so it belongs in this change
rather than in one of its own.

It enters under zsh. `s` attaches a named session instead of only changing
directory, seshy and zmx agree on the session name, and `ZMX_SESSION_PREFIX`
carries the namespace. `si` is an fzf picker that calls `s`, so it inherits the
change rather than needing its own.

The agreement runs one direction: every zmx session name is a seshy session
name. It is not set equality. A seshy session is a worktree directory and exists
with no process running, while a zmx session is a live process, so a session
created and not yet entered is in `sy list` alone.

The reason it is worth the dependency is the session key. `agentstate.go` forks
`wezterm cli list` per tool call to learn a pane's workspace, and phase 2 deletes
that fork. `ZMX_SESSION` is in the environment of every process in the session,
so reading it costs nothing and needs no terminal.

The writer and the readers get different orders, because phase 2 already split
them. In `agentstate.go`, `identify` resolves the seshy directory, then
`ZMX_SESSION`, and stops: phase 2 moved workspace resolution out of that binary
and nothing here puts it back. In `runtime/agent-identity.sh` all three sources
stay, ordered seshy directory, `ZMX_SESSION`, then workspace, and the workspace
fork runs only when the first two are empty. That file has readers with no other
way to answer: a pane the owner opened directly has no `ZMX_SESSION`, and neither
does anything on the bare box phase 9 builds, so that branch is the correct
answer there rather than dead code.

Three sources for one fact is a cost, and the fix for it is not to pick a winner.
The agent deck in `ui.lua` groups by `win:get_workspace()` and never reads the
record's `session` field, so it already disagrees with `identify`, and that
predates zmx. `ui.lua` runs in the mux process and cannot read a pane's child
environment in any case.

So the record carries two named fields, a session name and a workspace, and each
surface reads the one it wants. The alternative was to declare the deck
workspace-keyed by design, and its own evidence refutes it: three surfaces read
the record's key and two are not wezterm, the sketchybar menu bar widget and the
waybar module. A workspace key is defensible for a workspace-scoped display and a
global menu bar is not one, so that branch ships a screen where the tab bar and
the menu bar name the same agent differently at the same moment. Decision 4's
task 4.6 already gives the record a schema and a version field, so a second field
is a schema addition rather than new machinery.

What `zmx` does NOT take: `wtrun`, whose worker pane is a surface the owner
watches, and phase 5's viewer. `zmx run` and `zmx tail` could plausibly do both,
and that is a second decision with its own losses, not a consequence of this one.

