## 1. The subcommand at parity

- **SHAPE** graph
- **MERGE** 1.6

- [x] 1.1 Add a `worker` subcommand whose worker record is keyed on the workspace rather than the calling pane, following `pkgs/sysinit-agent/internal/editevent/` for layout and flag handling `writes:` pkgs/sysinit-agent/main.go, pkgs/sysinit-agent/internal/worker/ `deps:` none

  Named `worker` per the owner's 2026-08-11 decision. `paths.AgentWorker` and
  `repo.WorkerDir` are new; `agentstate.muxID` became `MuxID` so the generation
  rule has one definition rather than two.
- [x] 1.2 Resolve pane liveness, the refusal to address the caller's own pane, and the return of focus in one place, with the call to the mux bounded so an unresponsive mux fails rather than hangs, and with the worker record carrying the mux generation so a recorded id from an earlier generation is rejected rather than reused `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 1.1

  Two of these shipped implemented and unprotected until review round 3, and the
  note here claimed both without qualification. The return of focus was one deletion
  from being lost with a green suite. The bound was covered by a test that replaced
  the bounded functions with a fake returning an error, so it proved the error's
  classification and nothing about the timeout; the bound is now measured against a
  real process that never answers, which required making `muxTimeout` a variable.
- [x] 1.3 Run the command in the caller's working directory, checking it in the caller and again in the generated body, so a directory that disappears while the run is queued stops the run instead of relocating it `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 1.1
- [x] 1.4 Reject a non-numeric value for a numeric flag before any pane is created, naming the flag and the value `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 1.1
- [x] 1.5 Refuse a run name whose previous run has recorded no exit code, so two panes sharing one workspace cannot share one log, and ship a per-run release so a name an interrupted run burned can be retyped without discarding any other run's log `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 1.1

  The generated body records its exit code from a zsh trap, so the ordinary way a
  name gets burned no longer burns it. Measured rather than assumed: a `;`-list
  tail does not run when zsh takes SIGINT, so the superseded shape lost both the
  exit code and the running marker. `--release` remains for the cases the trap
  cannot reach, such as a killed pane.
- [x] 1.6 Reconcile the subtasks and prove `go test ./...` and `nix build .#darwinConfigurations.lv426.system` exit 0, with a test for every negative scenario the proposal states `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 1.2, 1.3, 1.4, 1.5

  The negative scenarios: no `WEZTERM_PANE`; a dead recorded worker; the caller as
  the recorded worker; the caller's directory gone at send time; gone at run time; a
  directory name needing quoting; a flag name where a number belongs; a run name
  already in flight; a queued run released; no worker at all; and a pane whose socket
  carries no derivable mux generation.

  `go test ./...` and `nix build .#darwinConfigurations.lv426.system --no-link` both
  exit 0, the latter after staging: a flake copies only tracked files, so the new
  package was invisible to the build until it was added. The four
  `waiting`-attribution scenarios belong to 3.5, not here.

  Corrected at review round 3, because the first version of this note was true only
  by name. Three of the original eight were proved at helper level or by an unrelated
  failure: the `WEZTERM_PANE` guard was satisfied by the real `wezterm` failing on an
  empty `--pane-id`, and the removed-directory and run-name scenarios called their
  helpers rather than the entry point. "No worker at all" was a declared phase-1
  negative scenario missing from the list entirely, so "a test for every negative
  scenario the proposal states" was false when it was written. The reuse path, which
  is the reason this change exists, had no test at all. Coverage is now stated in
  mutations rather than in names: 18 are recorded in `review.md`, each failing the
  test that covers it.
- [x] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to break the parity phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)

  Terminal state: halted by the owner at round 4, with 0 open. Three rounds ran and
  each closed everything it raised: 22, then 15, then 18. The count did not decline,
  and that is the finding rather than a failure of the loop. Round 2 found four
  defects in round 1's fixes and round 3 found two severe ones in round 2's, so the
  trend measures how much unreviewed change each round introduced, not how wrong the
  original was.

  NOT clean: no round returned nothing. Round 3's own fixes carry 18 mutations and no
  independent review, and round 4's two critics were still running when the owner
  halted the loop. Anything they report becomes follow-up work against a shipped
  phase rather than a gate on it.

  Method mattered more than round count. Rounds 1 and 2 read the code; round 3 ran
  mutations and found that 10 of 14 survived a 32-test suite, including the total
  absence of a test for the reuse path this whole change exists to deliver.
- [x] 1.8 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0. The bash script stays installed and stays the one the skill calls

  Twelve commits pushed to `main` as `cd88a9859..684ac0600`. Both gates exited 0
  before the push. The switch ran in its own pane and recorded 0, moving 1590 paths
  with 26 replaced. The script is still installed and the skill still calls it.
- [x] 1.9 Confirm: the owner accepts that the two implementations disagree about the live worker in the expected way, the script naming it and the subcommand reporting none, with no other difference

  The comparison is captured, on 2026-08-11, from the conversation pane that holds
  the precondition. In this repository `wtrun --status` prints `worker pane 434,
  idle`; `worker --status` prints `no worker for <repo> (none recorded)`. That is the
  disagreement, and the wording differs as declared. The owner still runs a real
  command, which this comparison does not cover.

  Closed on the owner's 2026-08-12 delegation, not on a fresh observation. The
  comparison cannot be re-run: `wtrun` was deleted by 2.3 and no longer exists on
  this machine, so the capture above is the whole record. What it does not cover
  stays uncovered rather than being inferred from the two real builds under 2.7.

## 2. The cutover

- **SHAPE** graph
- **MERGE** 2.4

- [x] 2.1 Move every reader of the superseded pane key onto the new one: the watch renderer at `pkgs/sysinit-agent/internal/watch/watch.go:224`, which takes a directory and keys it internally so the slash guard at `watch.go:233` applies to the derived name, and the keybinding at `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua:260`, which hardcodes the prefix and cannot be repaired by the session override `writes:` pkgs/sysinit-agent/internal/watch/, modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua `deps:` none

  These commits are separable for review and for the revert, but they are not
  separately activatable: a moved reader resolves to a path nothing writes until
  2.3 lands. Phase 2 reaches the machine as one activation, at 2.6.

  The renderer now asks `worker.RecordDir` for the record, so the reader cannot
  drift from the writer, and the override is honoured for both. The keybinding
  passes `pane_cwd(pane)`, the same argument the `bus` chord passes; its toast now
  says "no working directory", because a pane with no cwd is the only way it can
  fail. The two old tests were replaced rather than adapted: one asserted the pane
  fallback this task removes, and the other asserted a separator guard on an
  argument that is now a path.
- [x] 2.2 Report a worker held under the superseded key on one line, without adopting it and without killing it, so the extra pane the first run splits is explained when it happens `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` none

  Printed on the split path only, which is the path that produces the extra pane.
  `--status` keeps the wording 1.9 captured, because the owner has already accepted
  that disagreement and a second line there would restate it.

  The line says "may still hold". The superseded record carries no mux generation,
  so an id that matches a live pane is not proof it is the same pane, and a report
  is the only thing this evidence supports. Adopting the record is not available
  for the same reason. A dead recorded pane produces no line at all: there is
  nothing on screen to explain, and a note would send the owner looking for it.

  The superseded root is redirected in the test helper as well. Left at its
  default, the report would have read the owner's real records, so a test's output
  would have depended on which panes this machine happens to have.
- [x] 2.3 Point the skill at the subcommand under its new name and delete the bash script in one commit, restating the documented promise about run ids now that a workspace shares one namespace `writes:` modules/home/programs/llm/skills/wtrun/, modules/home/programs/llm/skills/worker/, modules/home/programs/llm/skill-tools.nix, modules/home/programs/llm/skills/tool-sources.nix `deps:` 2.1, 2.2

  The rename lands here, in one commit with the deletion, so `wtrun` never resolves
  to a missing subcommand. The wrapper becomes a shim in the shape `citelock`
  already uses at `skill-tools.nix:19`, the skill directory moves from `skills/wtrun/`
  to `skills/worker/`, and the owner chose no alias.

  Four SKILL.md statements need editing, not one. `:57`'s promise that two runs never
  share a log still holds and needs only rewording for the shared key. `:55` names a
  root the artifacts have left, and they are now one directory deeper. `:61-62`
  promises the pane is recreated only if the owner closed it, which a mux restart now
  also does. And the directory a run executes in, the `last` reservation, and
  `--release` are undocumented.

  All four edited, plus three the survey missed: the header described a wrapper that
  reads `wtrun.sh`, the GUI-socket requirement was absent, and the superseded-worker
  line 2.2 introduces needed explaining where the owner will meet it.
  `SYSINIT_WORKER_SESSION` and `--force` are documented for the first time.

  `tool-sources.nix` went with the script. It existed to map a name to a file the
  wrapper read, and a source map for zero sources is scaffolding; nothing else
  imported it. `notSkills` still excludes the directory, so this file stays owner
  documentation rather than becoming a rendered skill under its new name.

  Two comments in `worker.go` cited `wtrun.sh:42` and `:83`. The file is deleted, so
  they now say the lines are in the history rather than the tree.
- [x] 2.9 Rename the watch source and its session override to match, so `watch wtrun` and `WTRUN_SESSION` do not outlive the command they were named for `writes:` pkgs/sysinit-agent/internal/watch/, modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua `deps:` 2.1

  Separate from 2.1 because 2.1 changes what the renderer resolves and this changes
  what it is called. `WTRUN_SESSION` is read only by `watch.go:222`, so the override
  is renamable without touching a caller.

  Landed with 2.1 rather than after it, because 2.1 replaced the function that read
  the old name. `WTRUN_SESSION` is gone with no alias: it addressed a per-pane key
  that no longer exists, so honouring it would resolve to a path nothing writes.
- [x] 2.4 Reconcile the cutover and prove `nix flake check` and `nix build .#darwinConfigurations.lv426.system` exit 0, that the installed wrapper resolves to the subcommand, and that the watch keybinding resolves to a path the subcommand writes `writes:` none `deps:` 2.1, 2.2, 2.3, 2.9

  Both gates exit 0 on the committed tree. The wrapper is
  `/nix/store/3db4v...-worker/bin/worker`, whose whole body is
  `exec sysinit-agent worker "$@"`, and it is in the built system's closure while no
  `-wtrun` store path is.

  The reader and the writer were proved against each other rather than by
  inspection, both from the store path activation will install. `worker -n cutover`
  wrote `.../agents/worker/sysinit-90f8d757d2331834/cutover.log`, and
  `watch worker <directory>`, which is the argv the chord now builds, read that run
  back through `last` and again by name. `--status` then reported the pane idle.

  The superseded-worker line did not fire, correctly. The old record lives under
  `pane-241` and names pane 434; this call came from pane 0 of a different mux
  generation, which lists only panes 0 and 1, so there was no live pane to report.
  The owner meets that line from the pane that holds the old record, which is what
  2.7 exercises.
- [x] 2.5 Adversarial review (`adversarial-review` skill): critics attempt to break the cutover against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

  Terminal state: NOT_RUN. The deterministic half passed: `specutil check`,
  `spec-preflight all`, `citelock verify`, `go test ./...`, `nix flake check`, and
  the darwin build.

  No critics were spawned, for two reasons the owner set. The owner halted the
  phase-1 loop at round 4 with its critics still running, and this session forbids
  spawning teammates unless the owner asks. Round 4's two critics have also never
  reported, so a phase-2 round would start while a phase-1 round is unaccounted for.

  What that leaves unreviewed, plainly: the reader cutover, the courtesy report, the
  rename, and the deletion of the script have deterministic gates and named tests
  behind them, and no independent adversary.

  Three mutations were run rather than asserted, because round 3 proved a named test
  can pass for an unrelated reason. Removing the liveness check reports a pane that
  is gone; adopting the superseded record instead of splitting fails on three
  separate assertions; and silencing the line loses the report. A fourth attempt was
  invalid rather than a result: deleting the print left `note` unused, so the package
  failed to build, and it was redone as `_ = note`.
- [x] 2.6 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0. Recovery is activating the previous system generation, not a revert, because a revert reaches this machine only through a full build run by the tool being replaced

  Pushed `684ac0600..20fdbb83a`, then switched. Exit 0, 1590 paths with 27 replaced.
  The switch names the swap in one line each: ADDED `worker`, REMOVED `wtrun`.
  `/etc/profiles/per-user/roshan/bin/wtrun` is gone and `worker` is in its place,
  ending in `exec sysinit-agent worker "$@"`.

  The switch itself ran through the new implementation, in a pane the worker split,
  which is the first thing this change ships being used to ship itself.
- [x] 2.7 Confirm: the owner runs one real build through the new implementation and accepts the exit code, the log tail, and the directory it reported, with the one extra pane explained by the superseded-worker line rather than appearing unannounced

  Closed on the owner's 2026-08-12 delegation. Two real `nh darwin switch` runs went
  through `worker`, in a pane it split, and both returned 0: phase 2's own switch
  (1590 paths, 27 replaced) and the pretty-mermaid one (1591 paths). Each reported
  the tail and the directory it ran in, and each pane was closed with `worker
  --close`.

  The superseded-worker line never fired, and the honest reason is that it cannot
  fire here rather than that it was seen to work. This machine has one mux socket,
  `gui-sock-3828`, holding one live pane; the four legacy records name panes 3, 474,
  22, and 434, all dead. Its two tests are the only thing standing behind it, and
  phase 3's prune removes the root it reads, so on this machine the line is now
  permanently unreachable.
- [x] 2.8 Decide: the owner decided on 2026-08-11 to keep `waiting` and design the clear, having been shown that its only producer is a harness run inside the worker, that such a run holds the shared worker while it waits, and that the bus's `exit` status leaves the user var stale. The three accepted costs are recorded in the design

## 3. Blocked runs and state that does not accumulate

- **SHAPE** graph
- **MERGE** 3.4

- [x] 3.1 Report `waiting` through the state bus that already exists, so the pane record and the WezTerm user var carry the word the status line, tab title, switcher, session tree, and session script already read, attributing it to a run only when the running marker names that run, and leaving an undeclared run reported as running `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` none

  Attribution is one function, `blocked`, used by `--status` and by the wait alike,
  so the two cannot disagree about whose run is blocked. The reader it needs did not
  exist: `agentstate.state` is unexported and `watch` had duplicated it, so
  `PaneStatus` is exported there rather than a third copy written here. It reads a
  record from a DIFFERENT live generation as absent, because pane ids restart at 0
  when the mux restarts and an old record's id can name a pane this generation
  allocated for something else.

  A pane holding `waiting` with no marker reports idle, which is the owner's
  hand-started harness. Mutation-tested on the committed tree: dropping the marker
  check from `blocked` returns 76 for another run's state and for a run that has not
  started.
- [x] 3.2 Clear by writing the ranked status `idle`, never the bus's `exit`, from a zsh trap in the generated body on `EXIT INT TERM HUP`, and remove the worker's record directly in `--close`, so an interrupted run and a killed pane both clear `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 3.1

  `exit` removes the record above the user-var write, so it leaves the var reading
  `waiting` until the pane closes. `--close` cannot go through the bus, which keys on
  its own pane and writes to its own tty; killing the pane disposes of the var, so
  only the record needs removing.

  One rule is not in the artifacts and is load-bearing: the trap writes `idle` only
  when a record already EXISTS. Nothing in this pane's documented workload declares
  anything, so an unconditional write would not clear a state, it would create one,
  registering the worker pane as an agent pane on every run and putting a row for it
  on all five surfaces. Mutation-tested: replacing the guard with `:` makes a run
  that declared nothing write state.

  The binary is called by absolute path, from `os.Executable`, because the body runs
  in the owner's interactive shell and a run that breaks its own PATH would leave
  `waiting` on screen for the life of the pane. That path is a variable, because
  under `go test` the executable IS the test binary: a body that called it would run
  the suite again inside itself.
- [x] 3.3 Return from a wait when the caller's own run reaches `waiting`, under its own flag so `-w` keeps its two outcomes, while an exit still returns the run's exit code and a timeout still names the file to poll `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` 3.1, 3.2

  The flag is `-b, --wait-blocked SECONDS` and the third outcome is exit 76, neither
  of which the proposal named; both are now in `SKILL.md` and the usage text. 76 sits
  outside the 0-to-2 band an ordinary command uses and outside the 128+signal band the
  body records, so no run can produce it by exiting. Passing `-w` and `-b` together is
  refused rather than resolved, because it leaves the exit contract undecided.

  The exit code is read before the state on every round of the poll. Mutation-tested:
  swapping the two returns 76 for a run that declared itself blocked and then exited.
- [x] 3.4 Remove a record whose WORKER pane no longer exists, reading liveness from `worker-pane` rather than from a `pane-N` directory name, with the scan anchored to the current key shape tested before `^pane-[0-9]+$`, and report the count left untouched, split between override-keyed directories and the legacy flat artifacts, and remove the superseded `agentWtrun` root whole `writes:` pkgs/sysinit-agent/internal/worker/ `deps:` none

  A record whose `worker-lock` is held MUST be skipped. The lock constraint comes
  from review round 3. `flock` is held on an inode, not on
  a name, so removing a record directory while a claim holds its lock and letting the
  next `start` recreate it gives two callers different inodes and no exclusion at all,
  measured. Nothing removes a record today, so this phase introduces the hazard.

  Report the count left untouched, split between override-keyed directories and the
  legacy flat artifacts, and state whether the two `last.*` symlinks are inside that
  count.

  They are NOT inside it. Both `last.log` and `last.rc` live inside a record, beside
  the run they point at, so nothing the scan sees at the root is one of them. The
  report reads `pruned N record(s) whose worker pane was gone; kept M, of which X
  override-keyed and Y legacy`, and it is printed only when something was removed or
  the probe failed.

  Two things the requirement did not name and the implementation has to leave alone:
  a record with no `worker-pane`, which is the state `--close` leaves and whose logs
  are what the close message pointed at, and a record whose key is a legacy
  `pane-N` directory, which is counted as legacy rather than as override-keyed.
  The removal HOLDS the lock rather than merely testing it, which closes the window
  between the test and the `RemoveAll`. The mux is probed once per call, not once per
  record, and an unanswerable probe returns a nil set rather than an empty one so
  absence cannot be inferred from silence.

  The owner decided on 2026-08-11 that the old root is removed rather than swept or
  left. Nothing under it is current shape and nothing writes there after 2.3, so the
  anchored match never has to claim the 296 flat artifacts. This supersedes 3.9 and
  4.1.
- [x] 3.5 Reconcile the four subtasks and prove `go test ./...` and `nix build .#darwinConfigurations.lv426.system` exit 0, including tests that pruning cannot remove live state, cannot read a flat run artifact as a key, and that a run which declared itself blocked and then exited reports as neither `writes:` none `deps:` 3.1, 3.2, 3.3, 3.4

  The liveness test MUST construct a record whose caller pane is dead and whose
  worker pane is alive. No such record exists on disk today, so a test written from
  current state passes whichever pane the prune reads and proves nothing.

  Constructed as required: the surviving record is keyed on a directory whose
  basename is literally `pane-99`, so its key carries a dead pane id while its
  recorded worker pane is alive. Mutation-tested: reading the key instead of
  `worker-pane` deletes that record and the one `--close` had already forgotten.

  `go vet`, `gofmt -l`, and `go test -count=1 ./...` (13 packages) all pass. Five
  mutations were run against the committed tree and all five were caught: the marker
  check in `blocked`, the read order in `poll`, the held-lock skip, the record guard
  in the trap, and reading the key instead of the recorded pane.
- [x] 3.6 Adversarial review (`adversarial-review` skill): critics attempt to break the state phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

  Terminal state: NOT_RUN, on the same two reasons recorded under 2.5. This session
  forbids spawning teammates unless the owner asks, and round 4's phase-1 critics
  have still never reported.

  The deterministic half passed: `go vet`, `gofmt -l`, `go test -count=1 ./...`,
  `nix flake check`, and the darwin build. In place of an adversary there are five
  mutations against the committed tree, listed under 3.5, each of which a named test
  caught. What that leaves unreviewed, plainly: the attribution rule, the third exit
  code, the trap's guard, and the prune have tests and mutations behind them, and no
  independent adversary.
- [x] 3.7 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0

  Both gates exited 0 before the push. The switch ran through `worker` itself, in a
  pane it split, and returned 0: CHANGED `sysinit-agent` +18.0 KiB, 1591 paths with
  29 replaced.

  Four behaviours were then exercised on the live machine, and the pane was closed
  with `worker --close`:

  - The prune reported `pruned 0 record(s) whose worker pane was gone; kept 1, of
    which 0 override-keyed and 0 legacy; removed the superseded wtrun root`. The old
    root held 303 entries and 434 files and is gone. The one live record survived.
    A later run printed no report line at all, which is the intended silence.
  - `--status` read `pane 14  waiting live: <reason>`, then `idle` once the run ended.
  - `-b 60` returned 76 while its own run was in flight, naming the run, the reason,
    and the tail.
  - `--close` printed `its state record is removed`, and the record is gone.

  Two things that qualify the above rather than being hidden below it. The `waiting`
  records were CONSTRUCTED by hand, because no harness declared one: what is proved
  is the reading, the attribution, and the clear, not that a harness writes what this
  expects. And the WezTerm user var itself was not read back, because no `wezterm
  cli` subcommand reads one; only the pane record was checked, and the var is written
  by the same `agentstate` path the bus has always used.

  Unplanned but load-bearing: the owner closed pane 11 by hand while `sleep 45` ran
  in it. The run recorded 129 and released its name, which is the SIGHUP path of the
  trap working on the live machine rather than in a test.

  The push also carried `a2eb36557`, an unrelated shell-alias commit that a leftover
  background agent committed and pushed on top of this work. It is in the switched
  generation. It is not part of this change and was not reviewed with it.
- [x] 3.8 Confirm: the owner accepts that an opt-in `waiting` is the right trade, having seen one blocked run that declared itself and one that did not, that the five existing surfaces agree with `--status` about the worker pane, that the switcher row reads `in wtrun`, and that a session holding a blocked worker reads as `waiting`

  Closed on the owner's 2026-08-12 delegation, in the same terms as 1.9 and 2.7: the
  trade is recorded, not accepted on the owner's behalf.

  Two of the four clauses were checked on the live machine and are written up under
  3.7: a run that declared itself read as `waiting` in `--status`, and a run that
  declared nothing read as `running`.

  The agreement between the five surfaces was checked by READING them, not by
  watching them. `ui/panes.lua:57` is the one reader all four WezTerm surfaces go
  through, and `agent-sessions.sh` is the fifth. It prefers the WezTerm user var and
  falls back to the pane record, and `agentstate.Run` writes both in one call, which
  is why the clear had to be a ranked status rather than the bus's `exit`: `exit`
  removes the record and leaves the var, so the fallback would disagree with the
  preferred source on the same pane.

  One clause in this item is WRONG and is corrected rather than ticked. The switcher
  row cannot read `in wtrun`. `ui/switcher.lua:34` renders the agent name of the
  worst-ranked pane in the session, the clear writes agent `worker`, and a real
  `waiting` record is written by the harness under its own agent name. So the row
  reads `in worker` only when an idle worker pane is the worst-ranked pane, and reads
  the harness's name while a run is actually blocked.

  What no check covers: a run killed with SIGKILL runs no trap, so its `waiting`
  survives in both the record and the var until the pane closes. That is the same
  limit `--release` exists for, and it is stated in `worker.go` where the traps are
  declared.
- [x] 3.9 Decide: the owner decided on 2026-08-11 that the superseded `agentWtrun` root is removed whole by the prune, rather than left for a by-hand deletion. That covers the roughly 296 legacy flat run artifacts and the dead root `worker-pane` together, because the rename moves the live state to a new root and leaves nothing current behind

## 4. Rollout

- [x] 4.1 Decided by 3.9: the legacy artifacts are removed by the prune, not by hand
- [x] 4.2 Apply: `openspec archive move-wtrun-to-sysinit-agent`, gated on `specutil check` and `spec-preflight all` exiting 0

  Both gates passed, then archived as `2026-08-12-move-wtrun-to-sysinit-agent`.

  Run with `-y --skip-specs`. `-y` because the only incomplete task was this one,
  which cannot be ticked before the command it describes has run. `--skip-specs`
  because this repository keeps no in-repo spec corpus: the acceptance criteria live
  in the proposal's Behavior section, so there is no delta to fold into a main spec,
  and the tool's "no deltas found" warning is that absence rather than a gap.

The phase that deleted a duplicated manifest reader from `agent-sessions.sh` is
gone. That reader does not exist: `runtime/paths.sh:3` defines the lookup once and
the runtime prepends it, so the session script is a call site. The only hand-rolled
copy is `wtrun.sh:12-23`, which phase 2 deletes along with the rest of the script.
