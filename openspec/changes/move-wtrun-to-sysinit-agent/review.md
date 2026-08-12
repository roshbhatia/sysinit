Decision: run approved
State: STALLED

The decision above is transcribed from `specutil.review.yaml`, which records
`decision: approved` against base commit `627fbb2c9c4c`. The owner set it with
`specutil review set`; this file mirrors it because `spec-preflight` reads the
decision from here and `specutil check` reads it from there. The author did not make
it.

`STALLED` is the terminal state because the surviving-objection count did not decline
across three rounds: nine, nine, ten. Every objection was fixed in the round that
raised it, so nothing carried forward, and the two items under `Open objections` at
the end of this file are what the loop surfaced and did not resolve.

## Rubric

- `proposal.md` `Behavior`, every WHEN/THEN pair including the seven negative
  scenarios.
- `proposal.md` `Non-goals`, in particular the claim that the tty input buffer
  stays the queue and that removing the bash script is required rather than
  preferred.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines. Two of
  them reject an alternative on measured evidence rather than on judgement, and
  those measurements are the part worth attacking.
- `design.md` `Rollout & Gating`, in particular that phase 2 deletes the working
  implementation in one commit.
- `design.md` `Migration Plan`, whose steps 4 to 6 bracket the only destructive
  operation in the change.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

## Deterministic lint

Run 2026-08-11, before any critic.

| Check | Result |
| --- | --- |
| `specutil check move-wtrun-to-sysinit-agent` | one error remaining, `review-decision-current`, which is the owner decision this file exists to elicit. The section, marker, and word-count rules pass |
| `citelock verify openspec/changes/move-wtrun-to-sysinit-agent` | pass, offline gate, 6 records |

Two lint failures were found and fixed rather than argued with. A leading H1
made `specutil` report `## Why` and `## What Changes` as absent, which is the
same trap recorded for `tasks.md`. `Non-goals` was a bullet list under prose and
had to be a `### Non-goals` heading.

Six records are pinned, all six from the two projects the `Why` compares against.
Every other claim in the two documents is about a file in this repository, an
installed store path, a live state file, or a command's output on this machine.
Those are verifiable by reading the cited path or running the command, and a
critic should do that rather than trust them.

Two claims in `design.md` `Decisions` are measurements taken during authoring and
are the most attackable thing in the change, because they close off a design
direction on the strength of one observation each:

- `wezterm cli list --format json` exposes no field describing whether a pane's
  foreground process is reading input. The field list in the decision is the
  literal key set from this machine's WezTerm.
- macOS `ps -o wchan` prints an empty column, so blocked-on-tty-read is not
  distinguishable from any other interruptible sleep.

If either is wrong, the `waiting` decision is wrong, and `waiting` stops being
opt-in.

## Recommendation

Model critique SHOULD run. The highest-value lens is the second-order effect of
the keying change, not the port itself.

The strongest risk is that keying on the workspace is correct for the orphan and
wrong for something else. One worker per workspace means two panes in the same
repository share one worker, so a caller that starts a long build takes the
worker away from every sibling pane until it finishes. Today's per-pane key gives
each pane its own. The proposal treats this as pure gain and never states the
cost. A critic should construct the case where the old key was the better one and
say whether `WTRUN_SESSION` is a real answer or a footnote.

The second risk is that phase 2 deletes the only working implementation in one
commit, gated on the owner running a single build. One build exercises the reuse
path and the wait path and nothing else. A critic should name what that single
smoke test does not cover, and whether the revert really restores a working state
given that the switch has already been applied by then.

The third risk is the `waiting` mechanism. It requires the run to declare itself
blocked, which means the runs that most need it, an agent waiting on a human, only
work if that agent's harness writes the file. A critic should check whether any
harness in this repository would actually do so, because if none would, phase 3
ships a feature with no producer.

Two risks a critic would NOT catch, which the owner judges:

- Whether the two defects found by using `wtrun` justify a port rather than two
  small fixes to the bash script. Both fixes are a few lines each. The port's case
  rests on the keying and the duplication, not on the defects.
- Whether one live worker per workspace leaking at cutover is acceptable, given
  that the answer chosen is to print a line about it.

## Round 1

Three fresh-context critics, read-only tool set, one lens each: correctness,
ops/rollback, and citation/evidence. None saw the others' findings, and none saw
the author's reasoning. Nine objections raised, nine upheld after the author
verified each against the files. No objection was discarded.

Every claim below was checked before it was acted on. The one correction: the ops
critic cited system generations 297 and 298; the actual profiles are 321 to 324.
The substance holds, since a prior generation exists either way.

| Lens | Finding | Failing scenario | Verdict |
| --- | --- | --- | --- |
| correctness | Three readers of the superseded pane key were listed as unaffected | `watch.go:224` builds `"pane-" + WEZTERM_PANE`; `keybindings.lua:260` hardcodes the prefix and never reads `WTRUN_SESSION`; `SKILL.md:57` promises two runs never share a log. No task touched any of them | upheld |
| correctness | Two panes in one workspace share a run's log and exit-code file | Both run `-n build`. The second truncates the log and removes the rc file; the first's wait reads the second's status. The existing guard reads the `running` marker, which is empty while a run waits in the tty buffer, so no race is needed | upheld |
| correctness | The caller-directory check and the `cd` run in different processes, minutes apart | The body has no error handling. A directory removed while the run is queued leaves `cd` failing, the command running in the worker's directory, and the rc file holding the command's own status. The header, printed before the body runs, names the directory that was not used | upheld |
| correctness | The blocked marker had no owner that clears it | A run declares itself blocked, is answered, exits 0. The marker stays, the pane is alive, so `--status` reports `waiting` forever and every later blocked-wait returns at once. Pruning must keep it, since the proposal forbids removing state under a live pane | upheld |
| ops | `git revert` is not the kill switch on this deploy path | `wtrun` is a store path installed via `skill-tools.nix`, so it changes only at activation, and `sysinit.laurel/flake.nix:5` pins `github:roshbhatia/sysinit`. Recovery needs push, flake update, and a full darwin build, which is the workload `wtrun` hosts. A prior system generation restores it in seconds and was unnamed | upheld |
| ops | The phase 2 gate was guaranteed to report failure on first use | `pane-241/worker-pane` holds `434` and pane 434 is live. After the cutover the new key finds no record, so a second pane appears, which task 2.5 was worded to reject. The explaining report was scheduled for phase 3 | upheld |
| ops | The prune precondition described a directory shape the disk does not have | The wtrun root holds 303 entries in three shapes: four `pane-N/` directories, a root-level `worker-pane` naming dead pane 298, and ~300 flat run artifacts. Step 4 asked the owner to confirm `pane-N` was the only old shape | upheld |
| citation | `cmux-state-from-hooks` did not establish the claim it was attached to | The quote's antecedent is notification rings, badges, and popovers, under a notifications FAQ. cmux's README describes no per-pane state vocabulary. It was the only citation arguing *for* the design's mechanism | upheld |
| citation | "herdr replaces the terminal" was uncited and refuted by a pinned snapshot | The same snapshot reads "runs in whatever terminal you already use" and "tmux-style prefix keys". herdr keeps the terminal and marks pane state, which makes it the nearest analogue rather than the thing to distinguish from | upheld |

The citation lens also reproduced both measurements in the `waiting` decision
exactly, including the 18-key field list character for character, and added the
discriminating `STAT` test the author had not run. Both stand as written.

Its verdict table: five of six records SUPPORT their proposition, two with riders
now fixed in the prose. `cmux-state-from-hooks` was UNRELATED and is dropped.

### Revisions applied

1. `waiting` now publishes through `agentstate`, the bus `agentstate.go:231` already
   writes and five surfaces read, instead of a new file. This was the most
   consequential finding: the first draft added a state writer to a change whose
   case rests on removing duplicated readers.
2. A decision added for clearing the marker when the run ends, at any status.
3. The `cd` is checked twice, in the caller and in the body, and the body stops
   before the command. Two negative scenarios added for the queued and quoting
   cases.
4. A decision and a requirement added for refusing a run name still in flight.
5. The three superseded-key readers are named in `Impact` and moved in phase 2.
6. The kill switch is the previous system generation; the revert is the durable fix
   applied after.
7. The superseded-worker report moves from phase 3 to phase 2, and phase 1 gains an
   apply so migration step 1 can compare both implementations on live state.
8. The prune's scope is decided: the two key shapes only, with the count left
   untouched reported. The legacy flat artifacts become an owner decision.
9. `cmux-state-from-hooks` dropped, `herdr-runs-in-your-terminal` captured, and the
   herdr comparison corrected.

Surviving-objection trend: round 1, nine raised, nine fixed, zero open.

Deterministic lint after the revisions: `specutil check` reports only
`review-decision-current`, which is the owner's, and `citelock verify` passes with
six records whose ids match the six `[cite:]` references exactly.

The rubric above describes the artifact as round 1 received it and is left
unchanged, so the round's scope stays readable. The revisions moved two of its
counts: `Behavior` now states nine negative scenarios rather than seven, and the
`Migration Plan` runs to seven steps rather than six. A round 2 binds to the
revised artifact.

## Round 2

Bound to the revised artifact, not the one round 1 read. Three critics were spawned,
one lens each: scope, correctness, and data/migration.

All three lenses reported, but not together. `critic2-scope` returned first with
three objections, which were verified and fixed. `critic2-correctness` and
`critic2-migration` reported after that revision, three objections each. An earlier
draft of this record said those two lenses had gone silent; they had not, and this
paragraph replaces that claim.

Nine objections, all nine verified against the files or against live disk state
before anything was changed, all nine upheld. No objection was discarded.

Six of the nine were caused by round 1's own fixes. That is the important number in
this round, and it is treated as one below rather than as six unrelated defects.

| Lens | Finding | Failing scenario | Verdict |
| --- | --- | --- | --- |
| scope | The duplication argument for porting rests on a false premise | `runtime/paths.sh:3` defines `sysinit_path` once and the runtime prepends it, so `agent-sessions.sh:2,4` are call sites. `wtrun.sh:12-23` is the only hand-rolled copy, and only because `skill-tools.nix:14` reads the script raw. Prepending the library there is a two-line fix that needs none of this change | upheld |
| scope | Phase 4 was a no-op costing five tasks | It deleted a reader that does not exist. The phase carried a review round, a push, a switch, and an owner confirm for nothing | upheld |
| scope | Phase 3 builds `waiting` with effectively no producer | `SKILL.md:18` documents the worker as the place for builds, switches, test suites, and `nix` evaluations, none of which declare a state. The only producer is a harness run in the worker, at `sysinit-notify.ts:78`, and such a run holds the shared worker for the whole workspace while it waits | upheld |

| correctness | The clearing decision names a place that does not exist, and no place survives a signal | `wtrun.sh:129-133` writes a three-line body with no `rm`. The `rm -f running` is the tail of the interactive line sent at `wtrun.sh:140`, so the decision names the body and points at a `;`-list. Ctrl-C on the foreground group makes zsh abandon the rest of that line, so neither `echo $? > rc` nor the `rm` runs. `--close` kills the pane and touches nothing under the agents path | upheld |
| correctness | The bus has no clear that keeps the record and the user var in agreement | `agentstate.go:58-62` handles `status == "exit"` by removing the record and returning, above the `emitUserVar` call at `agentstate.go:84`. WezTerm holds a user var until the pane closes and `panes.lua:59-66` prefers the var, so a cleared run leaves `--status` saying idle while the var still reads `waiting` | upheld |
| correctness | Publishing to the shared bus answers the Open Question the design defers | `agent-sessions.sh:121-139` loops every `*.json` with pane liveness as its only filter, groups on `.session`, and takes the max rank. A worker declaring `waiting` flips its harness's session to `waiting` in the status line, which `design.md` lists as a non-goal | upheld |
| migration | The prune's liveness predicate does not say which of two panes it reads | A `pane-N` name is the caller (`wtrun.sh:25`); `worker-pane` holds the worker (`wtrun.sh:29`). `pane-241/worker-pane` holds `434` and both are alive, so the branches agree today. When caller 241 closes, the name branch deletes the record while worker 434 is on screen, taking a 288 KB log from today and silencing the report phase 2's gate reads | upheld |
| migration | The run-name refusal is a third compatibility break and the list names two | `wtrun.sh:110` is an unconditional `rm -f "$rc"`, so bash reuses any name. An interrupted run leaves a log and no `.rc`: three such names are on disk, including `phase4-build2` from today, one run in eight. The plan offered no release, and the workspace key widens the scope from one pane to the workspace | upheld |
| migration | Override-keyed state can never be pruned, while the override stays supported | `WTRUN_SESSION=build` writes `<root>/build/`, matching neither the keyed shape nor `pane-N`. The 297 flat artifacts are the same failure with an empty name. The design claimed state does not accumulate while keeping a documented hatch that accumulates | upheld |

The correctness lens also confirmed, against attack, the one thing the round-1 fix
got right: the pane identity works. The worker pane has its own `WEZTERM_PANE`, the
body runs in the worker's shell, `wtrun.sh:140` redirects only stdout and stderr so
the OSC reaches the worker's tty, and `--status` can read the record because it
learns the worker id from `worker-pane`. The bus is reachable. Every failure it found
is in the clearing and in what the other readers do with the record.

The scope lens's third objection about the phase 2 reader moves split into two
claims, checked separately. The `keybindings.lua:260` half holds: a moved reader is live at
activation and resolves to a path nothing writes until 2.3, so the design's claim
that each move is "independently correct" was wrong. The `watch.go` half holds for a
different reason than the critic gave: the `/` guard at `watch.go:233` does not
reject the derived `basename-digest16` key, but `repo.Workspace` returns a directory
path, and `newBus` at `watch.go:302` takes a directory. The renderer therefore has
to resolve and key internally, which nothing in the artifact said.

Two findings the author raised against their own round-1 fix, before the critics:

- Publishing `waiting` through `agentstate` gives the worker pane a rendered pane
  record. `switcher.lua:95` builds an attention row from any record ranked at
  `working` or above, so the worker appears as an agent session. `Impact` still
  listed `switcher.lua`, the status line, and the pane record schema as unaffected.
- `ui.lua:179` and `ui.lua:182` hardcode `$HOME/.nix-profile/bin` for `agent-notify`
  and `agent-focus`. That directory holds only `specutil` on this machine; both
  commands are in `/etc/profiles/per-user/roshan/bin`. This is the same defect fixed
  in the four notify bridges as `881d2e6d0`, and it is the last live instance. It
  means one of the five surfaces the `waiting` decision relies on has never
  notified. Fixed with `utils.get_nix_binary`, which `keybindings.lua:212` already
  uses, and staged as its own change outside this proposal's scope.

### Revisions applied

1. The duplication claim is corrected in `proposal.md` `Why` and `design.md`
   `Context`: one hand-rolled reader, not two, and the port's case is now stated as
   tests over a 167-line script rather than deduplication.
2. Phase 4 is deleted and `Rollout` renumbered. The design says why it is gone, so
   the removal is not read later as an oversight.
3. `waiting`'s single producer and its conflict with one worker per workspace are
   stated in both documents, with a negative scenario for an undeclared run. Whether
   phase 3 ships it becomes an owner Decide at 2.8, before the phase is built.
4. A decision pins the watch renderer: take a directory, key it internally, guard
   the derived name.
5. The design stops claiming the phase 2 reader moves are independently correct, and
   `tasks.md` 2.1 records that phase 2 reaches the machine as one activation.
6. `Impact` no longer lists the switcher and status line as unaffected, and phase 3
   MUST show the owner the worker's switcher row before it is accepted.
7. The prune reads liveness from `worker-pane`, never from a `pane-N` name. The shape
   match is anchored and tests the current shape first, because a workspace named
   `pane-3` keys to `pane-3-<16hex>`. Task 3.5 MUST build a record whose caller is
   dead and whose worker is alive, since no such record exists on disk.
8. The run-name refusal is declared as the third compatibility exception, with the
   evidence, and it MUST ship with a per-run release that clears one run's artifacts.
   A new negative scenario covers a name an interrupted run burned.
9. Override-keyed state is stated as exempt from the prune, the exemption goes in the
   skill, and the reported count separates override directories from the 297 legacy
   files.
10. The command is `sysinit-agent agent-state`, per `main.go:28`. Both documents
    called it `agentstate`.

The three correctness objections were open for one turn, because closing them needed
a scope decision that is not the author's. The owner made it on 2026-08-11: keep
`waiting`, design the clear. All three are now closed, and what follows records what
they said and what the answer cost.

- The clear has no correct implementation on the existing bus. `exit` removes the
  record without updating the user var, so the two publications diverge, which is
  precisely why the wtrun-only state file was rejected in round 1. Writing a ranked
  status instead keeps them in agreement and leaves the worker permanently registered
  as an agent pane.
- Nothing clears the state when a run is interrupted or when `--close` kills the
  pane, so the permanent over-report the design says cannot happen has a
  one-keystroke reproduction.
- Publishing to the shared bus makes a build's sudo prompt indistinguishable from an
  agent blocked on the owner, in the status line the design lists as a non-goal. And
  `ui.lua:172` treats the user var as a suppression signal, so a worker that
  publishes its own state never notifies at all.

The owner was shown all three and chose to keep `waiting`, so the three revisions
below are what keeping it requires:

11. The clear writes the ranked status `idle` and MUST NOT use `exit`. This is the
    finding that mattered most in the round: `exit` reproduces the divergence that
    round 1 rejected a wtrun-only state file to avoid.
12. The clear has three owners, not one: a zsh trap in the body on `EXIT INT TERM
    HUP`, an explicit record removal in `--close`, and an accepted inert residue under
    a pane the owner closed by hand. The trap is what survives Ctrl-C; the tail of an
    abandoned input line does not.
13. The worker publishes with the agent name `wtrun`, which `switcher.lua:34-56`
    renders. Three costs are accepted in writing rather than mitigated: the session
    rollup cannot distinguish a blocked build from a blocked agent, the worker stays
    registered as an agent pane, and a published state suppresses its own
    notification at `ui.lua:172`. The Open Question about `agent-sessions.sh` is
    answered rather than deferred, since reading the worker's state needs no schema
    change.

Surviving-objection trend: round 1, nine raised, nine fixed, zero open. Round 2, nine
raised, nine fixed, zero open.

The count did not decline, and six of the nine were caused by round 1's own fixes.
That is the skill's churn signal, and it is recorded rather than smoothed over: the
`waiting` mechanism generated defects in two consecutive rounds. It survives on an
owner decision made with the defects in front of them, not because the objections
weakened. A round 4 on this lens would be justified only if round 3 finds the clear
specified above is also wrong.

Deterministic lint after the revisions: `specutil check` reports only
`review-decision-current`, which is the owner's, and `citelock verify` passes with
six records.

Round 3 was spawned on correctness and data/migration before those two round-2
reports arrived, and read the revised artifact independently.

## Round 3

Two lenses, both reported: correctness on the `waiting` decision, data/migration on
the plan and the prune. Ten objections, all ten new, all ten verified before anything
was changed, all ten upheld.

The migration lens re-derived round 2's caller-versus-worker ambiguity and the
unprunable `WTRUN_SESSION` hatch independently, then confirmed the round-2 fixes close
both, and confirmed the anchored current-shape-first match is decidable against
`repo.keyed`. That is the first independent corroboration any fix in this review has
had. It also corrected a count of mine: removing `pane-241/` takes 31 sibling entries,
not 34.

| Lens | Finding | Failing scenario | Verdict |
| --- | --- | --- | --- |
| correctness | The pane record cannot attribute `waiting` to a run | Fields are Version, Mux, Pane, Session, Repo, Branch, Dirty, Worktree, Agent, Status, Reason, Since (`agentstate.go:29-42`), keyed on the pane. Pane B's run sits in the tty buffer having executed nothing; B's blocked-wait reads the record, sees pane A's harness `waiting`, and returns naming a run that never ran a line | upheld |
| correctness | Anything in the worker pane produces `waiting`, including what wtrun never launched | `wtrun.sh:116` splits with no program argument, so the worker is an ordinary shell the owner can type into. A harness started there writes the record, and `--status` reports a blocked wtrun run while wtrun has none. Five of nine pane records on this machine name panes that no longer exist, one carrying `working` | upheld |
| correctness | The blocked return has no exit code, and the deferral was falsified | `-w` has two outcomes: the command's status (`wtrun.sh:167`) and 75 (`wtrun.sh:160`). A third on the same flag is a code a caller branching on `$?` reads as the build's result. The Open Question called this a naming choice that does not change the mechanism | upheld |
| correctness | Both records are generation-blind, and the workspace key removes the collision that hid it | Reaching stale worker state used to need the caller's id AND the worker's id to recur; keyed on the workspace it needs only the worker's. A `worker-pane` holding a low id passes `pane_alive` against an unrelated new pane. `reapDeadMuxes` cannot help: it runs only on a write and `agentstate.go:289` skips `Mux == 0`, which five live records carry | upheld |
| migration | Step 5's invariant is satisfied by every possible prune | The prune enumerates directories and no flat entry is a directory, so "the flat artifacts are unchanged" is true even of a prune that deletes all four records including the one naming live pane 434. Step 4 recorded counts, which cannot say which record went | upheld |
| migration | Nothing defines what an unanswerable liveness probe means | `wtrun.sh:35-36` pipes to `jq -e`, so an unreachable mux makes the existing idiom treat a worker as absent. Carried into a prune, absent means delete, and step 5 passes for that reading and for the opposite one | upheld |
| migration | Step 5's "Prune" is not invocable, and step 4's baseline is destroyed by task 3.7 | The prune is a side effect of running a command, and `nh darwin switch` runs through wtrun on this machine: `citelockfix-switch.cmd` holds `cd .../sysinit.laurel && nh darwin switch . --update`. So each Apply step is a wtrun invocation, and pruning perturbs the listing step 5 diffs | upheld |
| migration | The dead root `worker-pane` falls through every step, and the one exact count closes only by swallowing it | It holds `298`, a dead pane, under the same filename the prune reads liveness from, but at the root, so the prune never considers it. It is not a `.cmd`/`.log`/`.rc`, so step 6's hand deletion leaves it. The stated `297` is reachable only by counting it, which the design excludes three lines earlier | upheld |
| migration | Step 1's precondition is held by the pane running this session | The only superseded record naming a live worker is keyed on pane 241, the conversation pane. If it closes before step 1, both implementations report no worker, which is the one outcome the step tells the owner is not expected, and task 1.9 accepts only the disagreement | upheld |
| migration | "At most one live worker per workspace" is not the bound, and no old record names a workspace | The old key is per caller pane, so the bound is per caller pane that ever ran wtrun. Phase 1 keeps the bash script minting records until the cutover, so two live workers in one workspace is reachable, and step 3 read N>1 as failure. No `pane-N` record stores a directory, and `wtrun.sh:136-137` prints no directory in the log header, so the report cannot attribute a leaked pane to a workspace | upheld |

### Revisions applied

14. The blocked wait attributes `waiting` by correlating the record with the
    `worker-running` marker, and returns only for the caller's own run. Three negative
    scenarios cover another run's block, a run still in the tty buffer, and a state the
    worker pane holds that wtrun did not produce.
15. The blocked wait gets its own flag, so `-w` keeps its two outcomes and the
    exception list stays at three. The Open Question is answered rather than deferred.
16. The worker record carries the mux generation, reuse rejects another generation, and
    an absent or zero marker is treated as no state rather than as current.
17. The prune removes nothing when the liveness probe does not answer, and says so.
18. The migration plan gains step 0, a baseline captured from a plain shell before
    phase 3 activates, recording each directory's name, its recorded worker, and that
    worker's liveness. Step 5 asserts set equality against it. The prune gains a
    report-only form, because the prune itself is not invocable.
19. Step 1 establishes its own precondition and states that agreement on "no worker"
    means the precondition lapsed rather than a defect.
20. Step 6 names the dead root `worker-pane`. The counts are corrected throughout: 296
    regular run artifacts, 298 with the two `last.*` symlinks, and the report states
    which reading it used rather than repeating a fixed number.
21. The leak risk is restated as one live worker per caller pane that ran wtrun, the
    report enumerates every superseded record whose worker is live, the gate accepts N
    extra panes when N are named, and the final confirm states that a superseded record
    carries no directory.

Surviving-objection trend: round 1, nine raised, nine fixed. Round 2, nine raised, nine
fixed. Round 3, ten raised, ten fixed. Zero open after each round.

Terminal state: STALLED. The count has not declined across three rounds, which is the
skill's non-convergence condition, and it is reported as a hand-back rather than as a
pass. Every round has found real defects in text the previous round left, and none has
found nothing.

What the trend says, offered as the author's reading and not as a verdict: three
lenses over three rounds have each broken a different part, and the parts that broke
are the six behavioral changes rather than the port. The keying fix, the
caller-directory fix, and the numeric-flag fix drew one objection between them across
three rounds. `waiting` drew seven. The prune and the migration plan drew nine. A
re-scope that ships the port with the three cheap fixes, and takes `waiting` and the
prune as their own change, is the option the evidence supports. That is the owner's
call, and no round of this loop can make it.

Deterministic lint after the revisions: `specutil check` reports only
`review-decision-current`, and `citelock verify` passes with six records.

## Open objections

Neither is a defect in the text. Both are things three rounds surfaced and no round
could close, carried here rather than dropped.

- Whether the change should be re-scoped before phase 1 starts. Across three rounds the
  keying fix, the caller-directory fix, and the numeric-flag fix drew one objection
  between them; `waiting` drew seven, and the prune and migration plan drew nine. The
  evidence supports shipping the port with the three cheap fixes and taking `waiting`
  and the prune as their own change. The owner approved the change as written, so this
  stays open rather than resolved, and phase 2's review round is where it lands again if
  the pattern holds.
- Three claims round 3's correctness lens could not verify, and neither could the
  author without changing the system: that a pane created by `wezterm cli split-pane`
  inherits `WEZTERM_UNIX_SOCKET`, that a fresh mux allocates pane ids from zero, and
  that a WezTerm user var outlives its pane's foreground process. The mux-generation
  decision rests on the first two, and the clear-writes-idle decision rests on the
  third. Task 1.2 and task 3.2 MUST establish each by observation before their phase's
  Confirm, not by reasoning from the code.
