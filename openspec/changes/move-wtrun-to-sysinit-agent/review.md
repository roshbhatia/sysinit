Decision: run approved
State: STALLED

The decision above is transcribed from `specutil.review.yaml`, which records
`decision: approved` against base commit `627fbb2c9c4c`. The owner set it with
`specutil review set`; this file mirrors it because `spec-preflight` reads the
decision from here and `specutil check` reads it from there. The author did not make
it.

That decision went stale once and was re-recorded. On 2026-08-11 the owner renamed
the command from `wtrun` to `worker`, chose no alias, and chose to have the prune
remove the superseded state root whole. Those three answers changed the proposal's
compatibility claim, one design decision, and seven tasks, so `specutil check`
reported the earlier approval as no longer covering the artifacts. The owner
re-recorded `approved` against code `d9515ee4`, with the rename as the note. The
author asked for that decision and did not make it.

It went stale a second time on 2026-08-11, when the phase-1 code review's first two
rounds closed 37 objections and changed all four artifacts. The owner was shown the
hashes and the round-2 record and directed that the same `approved` verdict be carried
forward, against code `31037acb6`. Carried forward, not re-decided: the author asked,
and the author did not make it.

Rounds 1 to 3 review the PLAN, and reached `STALLED`. Task 1.7 reviews the phase-1
CODE, is a separate loop with its own rounds, and is recorded at the end of this file.
The approval above covers the artifacts, not the implementation.

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
- Three claims round 3's correctness lens could not verify. All three are now settled
  by observation on 2026-08-11, so this item is closed rather than carried:
  - A pane created by `wezterm cli split-pane` DOES inherit `WEZTERM_UNIX_SOCKET`.
    Measured: a scratch split pane read `gui-sock-94721`, and the record it wrote
    through `agent-state` carried `"mux":94721`, the parent's generation. The
    mux-generation decision is implementable.
  - A fresh mux DOES allocate pane ids from zero. Measured with an isolated
    `wezterm-mux-server` on its own socket and `HOME`: its first pane is id 0 and the
    next is 1, while the live mux was at 434. So the collision the decision guards
    against is real, and the `pane-0` and `pane-2` records on disk are exactly the
    shape that would collide.
  - A WezTerm user var DOES outlive the process that wrote it. This one needs no new
    experiment: `agent-state` is a short-lived command that writes the OSC and exits,
    and every surface reads the var long afterwards. If it did not outlive the writer,
    no pane would ever show a state, and they do.

## Phase 1 code review (task 1.7), round 1

A separate loop, bound to code rather than to the plan. Three fresh-context read-only
critics were spawned against commits `d9515ee49..6374aecee`, one lens each: parity
against the 167-line script, correctness, and state. Parity returned 10 objections and
correctness returned 12. The state lens never reported, which is recorded as a gap
rather than as a clean lens: two of three lenses ran.

Every objection was verified against the file before it was acted on, and the parity
report was checked against all 167 lines of `wtrun.sh` rather than against its summary
of them. All 22 were upheld. None was discarded, and none was already fixed.

The correctness lens's central finding is that the author overclaimed. A code comment
and the task 1.5 note said the generated body records an exit code however the run
ends. The trap does not cover `SIGKILL`, an `exec`, or a command that clears it, so
the claim was wrong in three ways and the comment now says which.

| Lens | Finding | Failing scenario | Verdict |
| --- | --- | --- | --- |
| correctness | An unanswerable liveness probe split a second worker | The mux stalls for one `wezterm cli list`. `pane()` returns an error, `start()` reads any error as "no worker", splits, and overwrites `worker-pane`. The live worker is now unaddressable: the orphan the change exists to remove, manufactured by the change | upheld |
| correctness | An absent or zero generation marker was treated as current | Two shapes. A record with no `worker-mux` skipped the check entirely. A record written by a process with no `WEZTERM_UNIX_SOCKET` holds `0`, and `0 == 0` matches every later blind process. The proposal requires an absent marker to read as no state | upheld |
| correctness | A marker with no owner burned a run name and neither recovery freed it | The pane is killed with `SIGKILL`, so no trap runs and `worker-running` still names `build`. `--release build` refused, because the marker named the running run. `--close` refused too, because `pane()` failed. The name was unusable with no command-line way back, contradicting the task 1.5 note | upheld |
| correctness | Two callers in one workspace could be handed one run name | `nextRunName` read the counter, incremented, and wrote it back with no exclusion. Two panes in one repository interleave, both get `run7`, and they share one log and one exit-code file. The workspace key is what makes this reachable; the per-pane key could not | upheld |
| correctness | A failed `send` burned the name it had just prepared | The log and header are written, `wezterm cli send-text` fails, the call exits 2 having run nothing. The log with no rc reads as a run in flight, so the name is burned for the whole workspace, and the previous run's exit code has already been removed | upheld |
| correctness | The body's directory-gone exit code collided with an ordinary failure | It was 2, which `make` and `go test` both return for an ordinary failure. A caller branching on `$?` cannot tell a build that failed from a build that never ran | upheld |
| correctness | The key override could forge either shape the phase-3 prune matches | `SYSINIT_WORKER_SESSION=pane-241` or `=myrepo-<16hex>` resolves to a directory indistinguishable from a derived key, so `--close` under that override kills another workspace's worker and the prune's count becomes undecidable | upheld |
| correctness | An invalid override fell back to the shared derived key | A caller asking for a private worker and mistyping the name got the shared one, with a warning on stderr. Its `--close` then killed the pane every sibling was using | upheld |
| correctness | A wait beyond a duration's range expired at once | `time.Duration(seconds) * time.Second` overflows int64 above 9223372036, so the deadline landed in the past and `-w 99999999999` returned 75 immediately | upheld |
| correctness | `-n ''` reached the filesystem unvalidated | The empty string skipped the name check and produced `.log` and `.rc` in the record directory | upheld |
| correctness | `cd -- $dir` was unquoted in the generated body | A sourced `~/.zshenv` setting `SH_WORD_SPLIT` splits a directory name containing a space, so the run lands somewhere else or fails | upheld |
| correctness | The 250 ms settle was a guess about a race the code never observed | A command whose output exceeds what `tee` drains in 250 ms has its tail truncated; a command that leaves a writer running holds the caller for a fixed pause that helps nothing | upheld |
| parity | A bare multi-word command was refused | `wtrun.sh:132` and `:137` use `"$*"`, joining every remaining word. `worker git status` reported a second command and ran nothing. This is the single most common invocation shape | upheld |
| parity | The long flag forms were dropped entirely | `wtrun.sh:53,57,61` accept `--wait`, `--tail`, and `--name`. The Go parser knew only the short forms, so `--wait 900` was an unknown flag | upheld |
| parity | The `--` terminator was dropped | `wtrun.sh:86-89` ends flag parsing, so a command beginning with a dash is runnable. Without it, `worker -- -n hello` fails | upheld |
| parity | The log-name mistake was no longer caught | `wtrun.sh:96-99` detects a bare name followed by a quoted command and prints the corrected invocation. Restoring `"$*"` without this makes `worker build 'nix build'` run `build nix build` | upheld |
| parity | `--close` left a stale record when the pane was unreachable | `wtrun.sh:83` removes the record and the marker unconditionally. The Go version refused and cleared nothing, so a record naming a dead pane survived every recovery | upheld |
| parity | `--close` claimed success on a failed kill, then removed the record | `wtrun.sh:79` prints only on `&&`, but `wtrun.sh:83` removes the record whatever happened, so a live pane became unreachable. Both halves needed fixing, in opposite directions | upheld |
| parity | Four differences were real but undeclared: the error exit code, the `--status` wording, a missing flag value being an error, and mode flags no longer being order-dependent | Each changes observable output. `wtrun.sh:7` exits 1; `:54,58,62` default a missing value; `:65-84` act inside the parse loop, so a later flag is never read. A caller grepping `worker pane 12, idle` finds nothing | upheld |

The parity lens also corrected the author's stated reason for giving the override a new
name. The author's reason was collision, which cannot happen: the two implementations
read different roots. The real reason is that `watch.go:222` reads `WTRUN_SESSION` and
resolves it under the OLD root, so honouring that name here would aim the watcher at a
path nothing writes, silently. Task 2.9 repairs the watch side. The comment now gives
the sound reason and says the weak one is not it.

One finding the author raised against their own work before any critic reported: the
design commits at `design.md:491` to an explicit key override, and the implementation
had none. Added as `6374aecee`.

### Revisions applied

All 22 are closed in commit `2470058f0`, which rewrote the file rather than patching it
17 times.

1. An unanswerable probe returns a distinguishable `errProbe`, and no caller reads it as
   absence. `start` refuses rather than splitting, `--status` says it cannot report, and
   `--close` keeps the record.
2. An absent, empty, or `0` generation marker is "not current", never "current". A caller
   with no generation of its own refuses rather than guessing, because splitting would
   split again on every later invocation.
3. `--close` clears a record it has proved unusable, and says which marker it reclaimed.
   `--release` clears a marker whose run no pane can be running. A failed kill keeps the
   record.
4. Run names are claimed by creating the log with `O_CREATE|O_EXCL`, so the filesystem
   decides a race. The counter is a hint, not a reservation.
5. A failed send rolls back the log, the rc file, and the body.
6. The directory-gone code is 78, beside the 130, 143, and 129 the body records for
   signals.
7. The override refuses a name shaped like either prune key, and refuses an invalid name
   outright rather than substituting the shared one. An empty value still means "no
   override", which is what `${WTRUN_SESSION:-<derived>}` meant.
8. The wait clamps to one year of seconds, `-n` is validated before use, and the body
   quotes its `cd`.
9. The settle became an observed drain: wait for the log to stop growing, 20 steps at
   most, so a large tail is not truncated and a leftover writer cannot hold the caller.
10. The parser joins every remaining word, accepts the long forms and `--`, restores the
    log-name heuristic with its corrected invocation, refuses a mode flag combined with a
    command, and gained a usage synopsis and `-h`.
11. The four undeclared differences, plus three more the author found while declaring
    them, are stated in `proposal.md` as seven smaller deliberate differences. The
    `agentWtrun` path is no longer listed as unaffected, which was false from the rename.

Four mutations, one per new check, each fails the test that covers it: reading `errProbe`
as absence, accepting an absent generation, dropping `O_EXCL`, and removing the record on
a failed kill. `go build`, `go vet`, `gofmt -l`, `go test ./...` across all 13 packages,
and `nix build .#darwinConfigurations.lv426.system --no-link` all exit 0 on the commit.

Surviving-objection trend: phase-1 round 1, 22 raised, 22 fixed, zero open. Two of three
lenses reported.

## Phase 1 code review (task 1.7), round 2

Bound to the code as round 1 left it, not to the plan. Three lenses: parity, correctness,
and the state lens that had gone silent in round 1, prompted to report and given the new
revision. All three reported. 15 distinct objections, all verified against the files
before anything was changed, all 15 upheld, zero open.

The state lens opened by WITHDRAWING five findings the rewrite had closed, naming the
line that closed each. That is the only lens in this review to do so, and it is what
keeps a loop from churning.

Two objections arrived from two lenses independently: the queued-release defect was
raised by both parity and state. It is counted once.

| Lens | Finding | Failing scenario | Verdict |
| --- | --- | --- | --- |
| correctness | A caller with no mux generation of its own split a new worker on every invocation | `WEZTERM_UNIX_SOCKET` unset or malformed makes `MuxID` return 0. The refusal was a plain error, which `start` reads as absence, so it split, wrote another unverifiable `0`, and split again next call. `--close` could then reach none of them. The code's own comment promised the opposite | upheld |
| correctness | `--close` from inside the worker pane deleted the record of a live pane | `pane()` returned a plain error for "the record names the calling pane", which is a statement about who is asking. `closePane` read it as stale and cleared the record without attempting a kill. The next call split a second worker beside the live one | upheld |
| correctness | `--release` from inside the worker pane discarded a RUNNING run | Same root cause. The guard fell through, so the log was unlinked while `tee` kept writing to the unlinked inode: the exact harm the guard's own message names | upheld |
| correctness | Two callers passing the same `-n` could both hold the name | The reuse branch removed the log and then created it, so the second caller removed the log the first had just created. Reproduced by the critic at 2 rounds in 400, and later by a test here at 2 callers in 4 | upheld |
| state | `-n last` destroyed the aliases and made the run's own log unreadable | `last` passed validation, `inFlight` followed the `last.log` symlink to the previous run and read it as finished, the reuse path deleted both aliases, and `linkLast` then removed the run's own log and pointed the symlink at itself. Measured: every read returns ELOOP, so the command reported its exit code with its entire output gone | upheld |
| state | A failure between the claim and the send burned the name permanently | Rollback covered the send only. A full disk, or the record directory removed by hand mid-call, left a log with no exit code, which reads as a run in flight and burns the name for every pane in the workspace | upheld |
| state | `--close` silently burned the name of the run it killed | The killed run's log has no `.rc`, so the name reads as in flight. The output said "reclaimed a marker", which reads as cleanup finishing | upheld |
| state | A live record grows without bound, and the prune is specified never to look inside one | Measured on the live superseded record: 41 entries and 816 KB over five days, 13 of them dead `.cmd` bodies. The old per-pane key aged a record out with its pane; the workspace key keeps one per repository, and the negative scenario guarantees it survives pruning | upheld |
| state | A read-only query created the keyed directory | `MkdirAll` ran before the dispatch, so `--status` minted an empty record. The migration plan has the owner run `--status` for the two-implementation comparison, so reading perturbed the baseline step 5 compares against | upheld |
| parity + state | `--release` on a QUEUED run deleted the body the pane was about to run | The guard keyed on the running marker, and a queued run's marker still names its predecessor, because the body writes the marker when the previous command finishes. The release removed the body; the pane then failed to open its own script; the name was burned a second time by the release | upheld |
| parity | The run-name declaration misdescribed bash. Bash refused too | `wtrun.sh:124-126` refuses a name the marker holds, and an interrupted run leaves the marker set. The declaration said bash reused any name, which is the thing a reader would check. It also cited `:110` as what made reuse work, when `:110` is what made bash's own message unfollowable: it deletes the `.rc` it then says to wait for | upheld |
| parity | The missing-flag-value declaration misdescribed bash on both halves | It said `wtrun -w` waited forever and `wtrun -n` ran an unnamed run. Measured: bash's `shift 2` with one argument left refuses to shift and returns non-zero, and the script sets no `-e`, so the loop re-enters with `$1` still `-w` and spins. Neither ran anything | upheld |
| parity | The line every ordinary invocation prints gained a field, and only the log header was declared | Bash printed `pane <id>  <name>  log <path>`; the new form inserts `in <dir>`. Anything anchored between the name and `log ` breaks | upheld |
| parity | Four more reporting strings changed and none was declared | `worker pane <id>, idle`, `no worker pane` for both `--status` and `--close`, and `closed pane <id>`. `no worker pane` is the exact literal a wrapper would test for and now appears nowhere. `--close` also exits 2 on a failed kill where bash exited 0 | upheld |
| parity | The record's file list was declared exhaustive and was already wrong | `worker-mux` is a new file in a record, added by round 1's own generation fix, and the "not affected" list written in round 1 omitted it. `design.md` also described the comparison as reading the pane record's `Mux` field, when it reads a separate file | upheld |

The parity lens also confirmed, against attack, what the rewrite got right: the C-u prefix,
`clear`, `--no-paste`, `--bottom --percent 40`, the 1s settle and the return of focus, the
tail separator, exit 75 and its message, the `-t` default, the `last.*` symlinks, the
counter's name and contents, and the `"$*"`-style join are all preserved verbatim. The
correctness lens separately cleared the `errProbe` call sites, the first-run path, the
generated zsh's quoting including a single quote in a path, and `drain`.

Two defects found here rather than by a critic:

- An auto-allocated name reused a FINISHED run's name, deleting its log. The counter
  lives in the same directory as the runs it numbers, so a pruned or truncated counter
  restarts at 1. Only an explicit `-n` reuses now.
- The first fix for the reuse race was WRONG, and a test caught it rather than review.
  Moving the old log aside instead of removing it does not serialize anything: the
  winner recreates the log, so the next caller's rename succeeds against the fresh one
  and both hold the name. No ordering of remove and exclusive-create fixes this. The
  allocation now runs under `flock` on a per-record lock file.

### Revisions applied

All 15 are closed across three commits: `a759e7159`, `31037acb6`, and the doc edits.

22. A caller with no generation of its own returns `errProbe` and refuses, checked
    before the record is even read. Ordering was load-bearing: testing the RECORDED
    value first left the split-forever loop reachable whenever both were blind, which
    the test caught after the first attempt.
23. The self case gets its own sentinel. `--close` and `--release` refuse on it and
    keep the record; `start` still splits, which is correct, because the caller needs a
    worker other than itself and its own pane is not orphaned by losing the role.
24. Run-name allocation runs under `flock` on `worker-lock`. The exclusive create stays
    as an inner check.
25. `last` is reserved, and a name containing a line break is refused, because the
    reported counts are line-oriented.
26. Every failure between the claim and a successful send rolls the name back, not just
    the send.
27. `--close` records exit 129 for a run it killed, which is what the body's own HUP
    trap would have written, and says which run it ended.
28. The record directory is created by `start` alone, so a query writes nothing.
    Verified against the live root: the two directories my own earlier `--status` runs
    created were removed, and a query now leaves the root absent.
29. The generated body deletes itself once its exit code lands. Measured safe twice
    before relying on it: zsh completes a 300-line script deleted mid-run, and a trap
    can remove the file it runs from. Named literally, not as `$0`, because zsh sets
    `FUNCTION_ARGZERO` and `$0` inside a function is the function's name.
30. Six documentation defects fixed: the run-name declaration, the missing-value
    declaration, the start line, the four reporting strings plus `--close`'s exit code,
    the record's file list, and the design's description of the generation comparison.
    Accumulation is now stated rather than implied by a section title, with the measured
    numbers and with logs named as out of scope.
31. Task 2.3 records four SKILL.md statements to edit rather than one.

Seven mutations, one per new check, each fails the test that covers it: reading a blind
caller as absence, collapsing the self case into absence, letting `--close` burn the
name, creating the record from a query, allowing `-n last`, keeping the body after the
run, and removing the lock. `go build`, `go vet`, `gofmt -l`, `go test ./...` across all
13 packages, `nix build .#darwinConfigurations.lv426.system --no-link`, and `nix flake
check` all exit 0.

One process failure worth recording, because it has now happened twice in this
repository. Reverting a mutation with `git checkout --` discarded the uncommitted lock
implementation, and the test then failed for a reason that looked like a design flaw in
the lock. The lesson already written down is to mutate only a committed tree. It was not
followed, and roughly twenty minutes went into re-deriving a fix that was already
correct.

Surviving-objection trend: phase-1 round 1, 22 raised, 22 fixed. Round 2, 15 raised, 15
fixed. Zero open after both.

Terminal state: hit K=2 with zero open objections. The count declined, so this is not
non-convergence, and every objection is closed. It is NOT clean: no round of this loop
has ever come back with nothing, and round 2's own fixes have not been reviewed by
anyone. Roughly 8 of the 15 were caused by round 1's fixes, and one round-2 fix was
wrong on its first attempt, so a round 3 has real expected value rather than nominal
value. Whether to spend it is the owner's call.
