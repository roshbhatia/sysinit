## 1. The subcommand at parity

- **SHAPE** graph
- **MERGE** 1.6

- [ ] 1.1 Add a `wtrun` subcommand whose worker record is keyed on the workspace rather than the calling pane, following `pkgs/sysinit-agent/internal/editevent/` for layout and flag handling `writes:` pkgs/sysinit-agent/main.go, pkgs/sysinit-agent/internal/wtrun/ `deps:` none
- [ ] 1.2 Resolve pane liveness, the refusal to address the caller's own pane, and the return of focus in one place, with the call to the mux bounded so an unresponsive mux fails rather than hangs, and with the worker record carrying the mux generation so a recorded id from an earlier generation is rejected rather than reused `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 1.1
- [ ] 1.3 Run the command in the caller's working directory, checking it in the caller and again in the generated body, so a directory that disappears while the run is queued stops the run instead of relocating it `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 1.1
- [ ] 1.4 Reject a non-numeric value for a numeric flag before any pane is created, naming the flag and the value `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 1.1
- [ ] 1.5 Refuse a run name whose previous run has recorded no exit code, so two panes sharing one workspace cannot share one log, and ship a per-run release so a name an interrupted run burned can be retyped without discarding any other run's log `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 1.1
- [ ] 1.6 Reconcile the subtasks and prove `go test ./...` and `nix build .#darwinConfigurations.lv426.system` exit 0, with a test for every negative scenario the proposal states `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 1.2, 1.3, 1.4, 1.5

  The eight scenarios: no `WEZTERM_PANE`; a dead recorded worker; the caller as the
  recorded worker; the caller's directory gone at send time; gone at run time; a
  directory name needing quoting; a flag name where a number belongs; and a run
  name already in flight.
- [ ] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to break the parity phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)
- [ ] 1.8 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0. The bash script stays installed and stays the one the skill calls
- [ ] 1.9 Confirm: the owner accepts that the two implementations disagree about the live worker in the expected way, the script naming it and the subcommand reporting none, with no other difference

## 2. The cutover

- **SHAPE** graph
- **MERGE** 2.4

- [ ] 2.1 Move every reader of the superseded pane key onto the new one: the watch renderer at `pkgs/sysinit-agent/internal/watch/watch.go:224`, which takes a directory and keys it internally so the slash guard at `watch.go:233` applies to the derived name, and the keybinding at `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua:260`, which hardcodes the prefix and cannot be repaired by the session override `writes:` pkgs/sysinit-agent/internal/watch/, modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua `deps:` none

  These commits are separable for review and for the revert, but they are not
  separately activatable: a moved reader resolves to a path nothing writes until
  2.3 lands. Phase 2 reaches the machine as one activation, at 2.6.
- [ ] 2.2 Report a worker held under the superseded key on one line, without adopting it and without killing it, so the extra pane the first run splits is explained when it happens `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` none
- [ ] 2.3 Point the skill at the subcommand and delete the bash script in one commit, restating the documented promise about run ids now that a workspace shares one namespace `writes:` modules/home/programs/llm/skills/wtrun/ `deps:` 2.1, 2.2
- [ ] 2.4 Reconcile the cutover and prove `nix flake check` and `nix build .#darwinConfigurations.lv426.system` exit 0, that the installed wrapper resolves to the subcommand, and that the watch keybinding resolves to a path the subcommand writes `writes:` none `deps:` 2.1, 2.2, 2.3
- [ ] 2.5 Adversarial review (`adversarial-review` skill): critics attempt to break the cutover against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
- [ ] 2.6 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0. Recovery is activating the previous system generation, not a revert, because a revert reaches this machine only through a full build run by the tool being replaced
- [ ] 2.7 Confirm: the owner runs one real build through the new implementation and accepts the exit code, the log tail, and the directory it reported, with the one extra pane explained by the superseded-worker line rather than appearing unannounced
- [x] 2.8 Decide: the owner decided on 2026-08-11 to keep `waiting` and design the clear, having been shown that its only producer is a harness run inside the worker, that such a run holds the shared worker while it waits, and that the bus's `exit` status leaves the user var stale. The three accepted costs are recorded in the design

## 3. Blocked runs and state that does not accumulate

- **SHAPE** graph
- **MERGE** 3.4

- [ ] 3.1 Report `waiting` through the state bus that already exists, so the pane record and the WezTerm user var carry the word the status line, tab title, switcher, session tree, and session script already read, attributing it to a run only when the running marker names that run, and leaving an undeclared run reported as running `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` none
- [ ] 3.2 Clear by writing the ranked status `idle`, never the bus's `exit`, from a zsh trap in the generated body on `EXIT INT TERM HUP`, and remove the worker's record directly in `--close`, so an interrupted run and a killed pane both clear `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 3.1

  `exit` removes the record above the user-var write, so it leaves the var reading
  `waiting` until the pane closes. `--close` cannot go through the bus, which keys on
  its own pane and writes to its own tty; killing the pane disposes of the var, so
  only the record needs removing.
- [ ] 3.3 Return from a wait when the caller's own run reaches `waiting`, under its own flag so `-w` keeps its two outcomes, while an exit still returns the run's exit code and a timeout still names the file to poll `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` 3.1, 3.2
- [ ] 3.4 Remove a record whose WORKER pane no longer exists, reading liveness from `worker-pane` rather than from a `pane-N` directory name, with the scan anchored to the current key shape tested before `^pane-[0-9]+$`, and report the count left untouched, split between override-keyed directories and the legacy flat artifacts, stating whether the two `last.*` symlinks are inside that count `writes:` pkgs/sysinit-agent/internal/wtrun/ `deps:` none
- [ ] 3.5 Reconcile the four subtasks and prove `go test ./...` and `nix build .#darwinConfigurations.lv426.system` exit 0, including tests that pruning cannot remove live state, cannot read a flat run artifact as a key, and that a run which declared itself blocked and then exited reports as neither `writes:` none `deps:` 3.1, 3.2, 3.3, 3.4

  The liveness test MUST construct a record whose caller pane is dead and whose
  worker pane is alive. No such record exists on disk today, so a test written from
  current state passes whichever pane the prune reads and proves nothing.
- [ ] 3.6 Adversarial review (`adversarial-review` skill): critics attempt to break the state phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
- [ ] 3.7 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 3.8 Confirm: the owner accepts that an opt-in `waiting` is the right trade, having seen one blocked run that declared itself and one that did not, that the five existing surfaces agree with `--status` about the worker pane, that the switcher row reads `in wtrun`, and that a session holding a blocked worker reads as `waiting`
- [ ] 3.9 Decide: the owner decides whether the roughly 300 legacy flat run artifacts are deleted by hand, which the prune deliberately does not touch

## 4. Rollout

- [ ] 4.1 Decide whether the roughly 296 legacy flat run artifacts and the dead root `worker-pane` are deleted by hand, which the prune deliberately does not touch
- [ ] 4.2 Apply: `openspec archive move-wtrun-to-sysinit-agent`, gated on `specutil check` and `spec-preflight all` exiting 0

The phase that deleted a duplicated manifest reader from `agent-sessions.sh` is
gone. That reader does not exist: `runtime/paths.sh:3` defines the lookup once and
the runtime prepends it, so the session script is a call site. The only hand-rolled
copy is `wtrun.sh:12-23`, which phase 2 deletes along with the rest of the script.
