## 1. Record the baseline

- **SHAPE** graph

- [x] 1.1 Act: stand the baseline up. Two deliverables, because the second is
      what produces half of the first: a committed baseline holding the two host
      drvPaths, one line per host carrying the attribute path and the drvPath,
      plus a sorted derivation-path file per host; and the CI job that evaluates
      the `x86_64-linux` half. This is Act and not Gather for that reason. The owner
      records `lv426` locally and takes the `arrakis` line from the job's output.
      Commit the file rather than leaving it in the working tree, because the
      Linux half of every later gate runs in CI on a different machine, and CI
      can only compare against a referent that is in the repository.
      Record the attribute path and not just the hash. This is the only task in the
      change that names an attribute path, and the two shapes differ in a way an
      implementer will not guess; 2.12, 3.14, 6.5, 10.12, and 11.1 all say only
      "the two host drvPaths" and would otherwise reconstruct the command from
      memory. Task 3.10 sets the standard: a gate needs an artifact rather than a
      memory, and a hash with no attribute path beside it is exactly that. Two hosts, not
      three, and two different attribute paths, because `hosts/default.nix:47,49`
      defines exactly `lv426` and `arrakis`. An earlier draft said
      `nix eval --raw .#darwinConfigurations.lv426.system.drvPath` "and the same
      for `arrakis` and `nostromo`", which is wrong three ways: `nostromo` does not
      exist anywhere in this repository, `arrakis` is a `nixosConfiguration` and
      not a `darwinConfiguration`, and one attribute path cannot serve both. Use
      `.#darwinConfigurations.lv426.system.drvPath` and
      `.#nixosConfigurations.arrakis.config.system.build.toplevel.drvPath`. The
      third `darwinConfigurations` entry, `bootstrap` (`flake.nix:130`), is an
      installer configuration and not a host; leave it out of every gate.
      The `arrakis` half needs an `x86_64-linux` machine, and this task adds a CI
      job rather than making the owner configure a builder. On the owner's
      `aarch64-darwin` machine the evaluation fails with "Required system:
      'x86_64-linux'" before it prints a hash, because the module set imports from
      a derivation.
      State the evidence at its real strength, because an earlier draft said "the
      `arrakis` half runs in CI" in the present tense and nothing in CI touches
      `arrakis` today. `build-cache.yml:74` builds
      `.#packages.<system>.cacheBundle`, which is a `symlinkJoin` at
      `flake.nix:174`, and `check.yml:37-42` has exactly one job on
      `macos-latest`. What the evidence does establish is enough: a Linux runner
      is reachable and proven to install Nix, because `build-cache.yml:32-33`
      declares `os: ubuntu-latest` under `system: x86_64-linux` and the installer
      at `:51` runs on all three matrix cells. So no local builder is needed once
      this task adds the job. The job is new work, not an existing thing to point
      at.
      Put it in its own workflow, `.github/workflows/closure-baseline.yml`, on
      `workflow_dispatch` alone, with both hosts as a matrix. Do NOT add it to
      `check.yml`. An earlier implementation put the steps in the `verify` job and
      that was wrong in a way worth recording, because the reasoning for it was
      superficially good: `check.yml` deliberately carries no path filter, so it
      sees every change. But `verify` is the required check on main, and
      `update-sources.yml:5` opens a `nix flake update` PR on a six-hourly cron.
      Every such PR moves thousands of derivation paths, so none of them could
      ever go green, and `auto-merge-dependabot.yml:23-26` records that its
      `--auto` needs `verify` required on main. The gate would have stopped the
      repository's dependency automation for eleven phases. It would also have
      made every intermediate commit of a multi-task phase red by construction,
      since phase 2 re-records only at 2.12. A change-scoped gate does not belong
      in a permanent required check. `workflow_dispatch` is what these gates
      actually are: per phase and owner-invoked, run with
      `gh workflow run closure-baseline.yml` at a phase boundary.
      Every gate that evaluates for `x86_64-linux` splits the same way, Darwin
      locally and Linux in CI: 2.12, 3.14, 6.5, 9.9, 10.12, and 11.1, plus 6.6,
      and 7.3, whose whole-closure form spans both hosts and is the only form
      reaching `nixos/desktop/greetd.nix` and `nixos/home/desktop.nix`, and also
      8.3, which builds `.#homeConfigurations.dev-x86_64-linux` and is a Behavior
      criterion of its own. An earlier draft said "every drvPath gate", whose
      wording excludes 8.3. Task 8.4 already sends the owner to a Linux box for
      the switch, so phase 8 knows the boundary exists; 8.3 is the task CI takes
      off the owner's machine. Each of those tasks carries the split in its own
      words rather than relying on this one, because a constraint stated once and
      read at eight sites is the memory this task's own first paragraph refuses.
      No gate here realizes a host closure, and that is a decision rather than an
      accident. An earlier draft used `nix store diff-closures`, which needs two
      realized closures in one store. The `lv426` system closure measures 17.5 GiB
      and `check.yml:86-90` already records that a runner has roughly 14 GB free
      and that `nix build` of a host fails on disk there, so two of them fit on no
      runner, and holding both as GC roots across eleven phases is a 35 GiB charge
      on the owner's machine for a comparison that never needed the bytes.
      Use `nix derivation show -r <attr>` instead, and compare the set of
      derivation paths in the graph excluding the root. That is pure evaluation:
      measured here at 7441 derivations and 3278 distinct names in 9.9 seconds for
      `lv426`, materializing nothing. It answers the question these gates actually
      ask, which package appeared or disappeared, and it beats `diff-closures` on
      two counts. It is NOT order-insensitive, and an earlier draft claimed it
      was on the reasoning that a set of paths has no order. The set has no
      order, but its membership changes, because a `buildEnv`'s own derivation is
      computed from the order of its `paths` and input-addressed hashes propagate
      upward. Verified: two graphs differing only in `paths = [hello jq]` versus
      `[jq hello]` hold 572 derivations each and differ on two, the root and the
      `-env.drv`, so excluding the root leaves the other. That node is interior
      in the real graph, not the root, which is why the class is present: 20
      `-env.drv` entries for `lv426` and 70 for `arrakis`. So order preservation
      is a requirement on 6.2 and 9.4 rather than a nicety, stated in both. What
      the set does buy over a bare hash is a readable failure: only `-env.drv`
      nodes moving is a reorder, a missing package is a dropped module, and a
      hash cannot tell those apart. It covers
      build-time dependencies, which `diff-closures` cannot see. And it needs no
      GC root, so nothing in this change pins a closure. The cost is real and
      small: it compares identity, not size, so a package that changed size
      without changing identity reads as unchanged. Task 6.6 keeps
      `nix path-info -S` for the one place a number is the point.
      Two things about the CI job itself, both because the file it joins
      establishes the opposite convention. It must fail rather than skip when a
      precondition is missing. `build-cache.yml:53-63` gates its push on a secret
      so the job stays green without one, and `:28` sets `fail-fast: false`; that
      skip-when-absent shape is what 3.13 moved a check out of the pre-commit hook
      to avoid, and it is worse here because the owner looks at CI less often. And
      it runs at every phase boundary, not once at the end, for the same reason
      the last paragraph of this task gives.
      `check.yml:42` stays on `macos-latest` and is not the place for this; its
      comment records why, that `nix flake check` builds only the current system's
      checks and Darwin is what the owner experiences.
      Accept the cost this imposes and name it here rather than leaving an
      implementer to meet it at the first phase boundary. A gate that lives in CI
      cannot be run before committing. Passing 3.14 means pushing a branch,
      waiting on a runner, and reading a result, eleven times. That inverts the
      property 3.13 and the phase 10 STOP were written to protect. It is accepted
      because the alternative is a second machine the owner maintains out of band,
      which is the same defect phase 4 exists to remove, a fact held somewhere
      other than the repository. The Darwin half of every gate still runs locally
      in about ten seconds, so the wait applies to the `arrakis` half alone.
      Building on `arrakis` itself at pull time was the other option and is not a
      substitute. These gates are per phase and exist to catch a module silently
      dropped during the refactor, so a check that runs after all eleven phases
      land reports the loss with no signal about which phase caused it. Keep it
      as a final confirmation, not as the gate.
      An earlier draft offered a second branch, recording that `arrakis` is ungated
      and that every gate covers one host. Three tasks refuse it: 6.5 checks "the
      two drvPaths", 9.9 requires "an empty diff for both hosts", and 11.1 compares
      "the two host drvPaths". Under that branch all three name a referent nothing
      recorded. It also quietly changes what this change proves: `arrakis` is the
      only Linux host and the only consumer of `modules/nixos/`, so dropping it
      removes Linux from the profile split, from theming, and from standalone home
      configurations. Phase 7 is the sharpest case, since
      `nixos/desktop/greetd.nix` and `nixos/home/desktop.nix` are two of the twenty
      modules 7.2 guards and neither is reachable without it. Ungating Linux is a
      scope decision for the owner and a proposal edit, not a footnote in this
      task.
      Record the derivation-path set beside each host's drvPath, as a sorted file
      per host from `nix derivation show -r <attr>` with the root drv removed.
      Those two files are what 2.12, 3.14, 6.5, 7.3, 9.9, 10.12, and 11.1 compare
      against, and they are text, so they commit and diff like text. An earlier
      draft instead built each host with `nix build --out-link`, named
      `-o result-lv426` and `-o result-arrakis` so the second would not drop the
      first host's GC root, and recorded the output paths. Every line of that is
      now dead: no gate realizes a closure, so there is no root to hold, no
      `./result` collision to avoid, and no store path worth recording. It was
      also unbuildable for `arrakis`, whose out-link would have named a path in a
      runner's store that ceases to exist with the job. Task 3.10 already sets the
      standard this follows, that a gate needs an artifact rather than a memory,
      and a committed text file meets it where a GC root did not. This is the
      baseline for 11.1's enumeration clause alone. An earlier draft called it the
      baseline for phases 6, 7, and 8, which three tasks contradict: 3.14 says
      "Phases 6 through 9 compare against this recording, not against 1.1", 6.5
      says the same in its own words, and 9.9 diffs against the 3.14 build. No
      phase from 6 to 9 anchors here. It is NOT a whole-change gate. Phases 2 and 3 change the
      closure on purpose, because they delete and rename packaged code, so an
      equality gate spanning them can only fail. Each of those two phases
      re-records the baseline as its last step, and states in one line what
      moved and why it was intended. Capture `owner-wezterm-sites.txt` here too,
      which task 2.9 compares against: the literal output of
      `rg --sort path --no-line-number '"wezterm"|wezterm cli'` over
      `modules/home/programs/neovim/config` with `-g '!**/doc/**'`, minus the four
      lines phase 2 removes. Run it without line numbers, and with `--sort path`,
      which is load-bearing rather than tidy. `rg` walks files in parallel and
      does not order its output otherwise: five consecutive runs of the unsorted
      command here produced five different checksums, so 2.9 would compare a
      committed file against a differently ordered live capture and fail on every
      correct implementation. Both sides must use the same command. 2.8 deletes 41 lines
      above `wezterm_terminal.lua:100`, which shifts five surviving sites in that
      file, so a positional artifact fails on a correct implementation. The set is
      `path:matched-text` pairs. 31 lines today, minus 1 for `doc/`, minus 4 for
      the removed lines, is 26. It has to be recorded before the edits, or the
      gate compares the edited tree against a snapshot of itself. `deps:` none
- [x] 1.2 Verify: the CI job 1.1 adds re-evaluates the `lv426` line and its
      output matches what the owner recorded locally. Exercise the job here,
      against an answer already known, rather than letting 2.12 be the first thing
      that runs it. Nine gates depend on this job and none of them tests it, so a
      failure at 2.12 would be ambiguous between "phase 2 dropped a module" and
      "the job is wrong", which is the exact signal phase 1 exists to make
      unambiguous. Task 9.2 states this repository's rule for it: write the gate
      before the thing it judges, so the gate is not authored by the thing it
      judges. Use `lv426` and not `arrakis` because only `lv426` has an
      independently known answer; this proves the checkout, the installer, the
      attribute path, and the output format end to end, and costs one runner
      minute. `deps:` 1.1
- [x] 1.3 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on whether the baseline captured is the right one, since
      every later STOP gate compares against it. `deps:` 1.2

## 2. Stop the agents pushing

Ordered first because it is the owner's stated complaint, it is independently
revertable, and it does not depend on any refactor below.

- **SHAPE** graph

The line is who initiates, and into which stream. An agent may write to an
output stream about itself. It may not write to an input stream, and it may not
move a surface the owner did not ask it to move.

The rule has one named exception: what the owner chose to keep. The retained
notification at `agent-prompt.sh:111-121` is agent-initiated and moves a surface
the owner did not ask for at that moment, so clause two forbids it and the owner
overrode that, recorded in the proposal. A rule without its exception written
down is one a later reviewer uses to delete what the owner asked for. Two items
also sit outside the rule and are removed on other grounds: the `spec_watch`
auto-open, where nobody writes a stream, and the per-tool-call fork in 2.9,
which is a cost rather than a coupling.

An earlier draft called this "self-report against remote control", which does
not survive its own phase. `agent-prompt.sh:136` sends into `$WEZTERM_PANE`,
the agent's own pane, so a target test would acquit the change's headline
removal. And `:130` activates a pane, which is remote control, and 2.1 keeps it
because the owner clicked. Task 2.4 already states the correct rule in its own
words: the defect was never the pane, it was an agent opening one.

- [x] 2.1 Act: in `runtime/agent-prompt.sh`, delete the `Accept)` and `Deny)`
      arms of the `case` at `:125`, the `send-text` block at `:135-137`, the
      `approve_keys` and `reject_keys` tables at `:50-59`, and
      `--actions "Accept,Deny"` at `:115`. Do not delete by line range: `:128-132`
      is the `@CONTENTCLICKED` focus branch and `:133` is the `esac`, both of
      which stay, so a range delete leaves an unterminated `case`. Re-gate the
      rich alerter at `:64-70`, which currently keys on `approve_keys` being
      non-empty and would otherwise be decided by a table that no longer exists.
      The agent deck stays. The notification says an agent needs you, and
      clicking it puts you in the pane, where you answer. `deps:` 1.1
- [x] 2.2 Act: keep the OSC `SetUserVar` write in `internal/agentstate`. An
      earlier draft deleted it. That was wrong twice over: a program reporting
      its own status to its own terminal is self-report, not remote control, and
      `archive/2026-07-08-surface-agent-session-state/design.md:49-59` already
      chose it over a per-pane file for a reason this change does not answer. A
      user var dies with its pane. A file does not. Claude wires
      `agent-state ... exit` (`claude/default.nix:236`) and so does pi, through
      `state("exit")` on `session_shutdown`
      (`pi/extensions/sysinit-notify.ts:51-53` into `:26-28`). Codex and
      opencode do not, so they leave a record reading `working` forever, and a
      crash does the same for all four. Record the reversal in `design.md`.
      In the same file, delete the workspace lookup: `paneWorkspace`
      (`agentstate.go:321-346`), its call at `:288`, and the workspace fallback at
      `:296-298`. That is the per-tool-call fork of `wezterm cli list`, which the
      proposal calls the terminal coupling that matters, and an earlier draft left
      it in 2.9's justification prose with no Act task and no `deps:` edge, so it
      could survive the phase with the gate green. Repair the reader in the same
      task rather than leaving it to a later one: `agent-sessions.sh:63-66` falls
      back to `sess="default"` on an empty session, so removing the writer's
      workspace without changing the reader collapses the deck to one group.
      Resolve it live there from the `wezterm cli list` the script already runs at
      `:38`. `ui.lua` already resolves it live (`:357`, `:731`) and needs nothing.
      `deps:` 1.1
- [x] 2.3 Act: leave `pane_agent_state` at `wezterm/lua/sysinit/pkg/ui.lua`
      alone. An earlier draft deleted `:330-348` as "the user-var path". That
      range is the whole function, and `:342-346` is the agent-deck fallback,
      which is the only status source for the seven harnesses that fire no
      hooks. `deps:` 2.2
- [x] 2.4 Act: stop exposing `wtrun` to agents. Remove it from the rendered
      skill set so it is an owner command only. Do not reimplement it as a child
      process. `skills/wtrun/SKILL.md:47-56` documents five guarantees, and a
      child of an agent's tool call keeps none of them. It also loses four
      properties, and those are not all in one section: a tty for
      `nh darwin switch` to prompt on and queueing through the worker shell are
      under Notes at `:58-66`, a lifetime past the tool call with a later `.rc`
      read is at `:40-42`, and something to watch is not documented as a
      guarantee anywhere. An earlier draft cited `:58-70` for all four, which
      overruns a 66-line file. The defect was never the pane. It was an agent
      opening one. `deps:` 1.1
- [x] 2.5 Act: make `spec_watch.lua` opt-in by deleting the unconditional
      auto-start at `spec_watch.lua:123`. The `:HarnessSpecWatch` command
      already exists at `:120-122` with its toggle at `:106-117`. That is not the
      whole edit, and an earlier draft said it was. `:124-130` registers a
      `DirChanged` autocmd whose callback is `M.stop()` then `M.start()` with no
      guard, so deleting `:123` alone means the watcher restarts itself on the
      first directory change, including one the owner toggled off. Gate that
      callback on `M.is_active()` (`:58-60`) so it restarts only what was
      running. The criterion in the proposal cannot catch this on its own: a
      fresh editor that never changed directory passes with the defect present.
      An earlier draft also cited `:19-27`, which is the `watchable(path)`
      filename predicate and not the watcher. `deps:` 1.1
- [x] 2.6 Act: delete `neovim/config/lua/harness/control.lua` and
      `neovim/config/bin/nvim-ctl`. In `harness/api.lua`, delete only the
      `harness.control` line at `:199`. Do not delete `:196-201`: that range is
      the whole of `M.setup`, and removing it breaks `harness.completion`,
      `harness.instance`, and the `harness.spec_watch` that 2.5 is editing in
      this same phase. Do NOT delete `config/doc/agent-ide-integration.md`, which
      an earlier draft did. `:51-55` is the only place in the repository that
      documents the two ways an agent discovers the editor socket, and deleting
      it in the same phase that decides what to do about those routes destroys
      the evidence the decision rests on. Rewrite it instead to describe what
      survives 2.7 and 2.8. Decided in
      design.md section 9: the entry point is a hand-placed skill this
      repository does not generate. The strongest reason is `ops.command` at
      `control.lua:297`, which runs an arbitrary `vim.cmd` on request.
      `deps:` 1.1
- [x] 2.7 Act: cut the agent's route into the editor's pane-driving code, and
      leave the owner's. An earlier draft deleted the wezterm control surface in
      `harness/preview.lua`, `utils/wezterm_terminal.lua`,
      `harness/adapters/claudecode.lua`, and `harness/lifecycle.lua` outright.
      That was wrong by this phase's own rule. `plugins/harness.lua:13-27` binds
      fourteen keymaps the owner presses, and ten of them reach the code that
      draft deleted: `<leader>ja`, `jc`, `jf`, `jr`, `jb`, and `js` through the
      send path, `jj`, `jx`, and `jJ` through spawn and kill, and `jp` through
      preview. An owner pressing a key is asking. The rule is who initiates.
      An earlier draft then claimed that after 2.6 and 3.6 nothing in this
      repository lets an agent call `harness.api` at all, and made proving that
      the whole remaining work. The claim is false, and
      `doc/agent-ide-integration.md:51-55` says so: deleting `control.lua`
      removes the op handler, not the channel.
      `nvim --server <sock> --remote-expr 'luaeval(...)'` reaches any lua module
      in the running editor, and the repository hands the agent the socket two
      ways. Close both. Route two is `harness/instance.lua`, which publishes the
      socket to `$XDG_STATE_HOME/nvim/harness/instances/*.json` (`:6`). Its only
      reader in the repository is `bin/nvim-ctl:30`, which 2.6 deletes, so delete
      `harness/instance.lua` and its `require("harness.instance").setup()` call
      at `api.lua:198` with it. Route one is the environment export, which 2.8
      closes.
      The rest of the task is the enumeration, and it must be complete or the
      module stays alive behind the parts that are removed. Fourteen sites drive
      wezterm from this tree: `harness/preview.lua:61`, `:74`, `:211`, `:237`;
      `harness/adapters/claudecode.lua:170`; and
      `utils/wezterm_terminal.lua:5`, `:31`, `:35`, `:53`, `:57`, `:104`, `:138`,
      `:165`, `:169`. Nine of those are the argv-table form
      (`vim.fn.jobstart({ "wezterm", "cli", ... })`), which no `wezterm cli`
      string grep can see. An earlier draft called the total thirteen and then
      listed fourteen, which matters because 2.9 compares line for line. Name the consumers too, since deleting functions and
      leaving callers leaves a live control module: `harness/lifecycle.lua:22`
      and `:25-64`, `harness/adapters/opencode.lua:17`,
      `plugins/claudecode.lua:18`, and `plugins/opencode.lua:15`. Confirm each
      entry point is owner-initiated and delete any that is not. Do not record
      the surviving set here, which two earlier drafts tried in this task and in
      2.8. Task 1.1 owns it, because an expectation sampled after the edits
      cannot fail when an edit is wrong. `deps:` 2.6
- [x] 2.8 Act: fix the orphan and decide the `$EDITOR` shim. `plugins/harness.lua:25`
      binds `<leader>jC` to `harness.api.walkthrough_clear()`, which calls into
      the `control.lua` that 2.6 deletes, so that keymap and its api entry go
      too. Separately, `utils/wezterm_terminal.lua:54`, inside the
      `EDITOR_WRAPPER` heredoc at `:46-58`, runs
      `nvim --server ... --remote-expr` naming a lua module inside the running
      editor. That is the same construct as `internal/nvimlink`, which this
      change deletes and design.md calls Feature Envy across a process boundary.
      An earlier draft kept it, on the reason that the owner runs `git commit`
      and the shim is what makes it open in their existing neovim. That reason
      does not survive its own evidence. The owner's shell never sees the shim:
      `modules/home/default.nix:41` sets `EDITOR = "nvim"` for the whole home
      configuration, and the shim is installed only by `editor_env` at
      `wezterm_terminal.lua:72-87`, which `_spawn` merges into every pane it
      creates at `:96`. Every path through `_spawn` spawns an agent CLI into a
      new pane, so the shim reaches agent panes and nothing else. An earlier draft
      said every caller is a harness adapter or `harness/lifecycle.lua`, which is
      false and contradicts 2.7's own consumer list: `plugins/claudecode.lua:26`
      and `plugins/opencode.lua:17` are neither. `harness/preview.lua` never
      reaches `_spawn` at all, having its own inline split at `:61`, so
      `<leader>jp` never gets the shim. There is no owner path to it.
      It is a pure agent route, and it is the composite this phase exists to
      remove: `:53` activates the owner's pane, `:54` drives the owner's editor,
      and `:55` blocks the caller until the owner writes the buffer. Delete
      `EDITOR_WRAPPER` at `:46-58`, `editor_wrapper_path`, `editor_env`, and the
      merge at `:96`. Also delete `utils/remote_editor.lua`, whose only caller is
      that heredoc. Record the consequence rather than hiding it: an agent that
      runs `git commit` with no `-m` now opens nvim nested inside its own pane,
      which is worse for the agent and is the point, because the cost lands on
      the process that chose to open an editor. Record the decision in
      `design.md`. `deps:` 2.7
- [x] 2.9 Verify: no agent-reachable path drives a terminal or an editor, EXCEPT
      the one this phase does not own, which is named below rather than left for
      a reader to notice.
      The second clause is a grep for a named set and NOT for zero, and an
      earlier draft made it zero: it required any nvim socket or msgpack
      reference under `pkgs/` to return nothing. No correct implementation of
      phase 2 can satisfy that, because the reference that remains is
      `internal/nvimlink`, and deleting it is task 3.6 in the next phase.
      `diffnote.go:195` calls `nvimlink.ShowNotes(root)` and `diffnote` is a
      subcommand agents run, so this genuinely is an agent-reachable path into
      the owner's editor and it is genuinely still open when phase 2 ends. Say
      that plainly. Phase 3 owns it because nvimlink dies as part of the diffnote
      responsibility split, not as a coupling fix, and 3.4 removes the call sites
      before 3.6 removes the package. So the clause is: `rg -l` for
      `nvim\.Dial|go-client/nvim|nvimlink` over `pkgs` must return exactly three
      files, `internal/nvimlink/nvimlink.go`,
      `internal/nvimlink/nvimlink_test.go`, and `internal/diffnote/diffnote.go`.
      A fourth hit is a NEW socket route and fails the gate. After 3.6 the same
      command returns nothing, and that is where the zero form belongs.
      The first clause is a grep for a named set, not for zero.
      `rg -n 'cli send-text|cli activate-pane|cli split-pane'` over
      `modules/home/programs/llm pkgs` must return exactly three files:
      `skills/wtrun/wtrun.sh` (`:102`, `:107`, `:128`), which 2.4 makes an owner
      command; `runtime/agent-focus.sh` (`:20`, `:31`), which is the `$focus_exe`
      the owner-clicked branch calls and which 2.1 keeps; and the prose comment
      at `harnesses/pi/extensions/diff-review.ts:7`, which 3.8 rewrites in the
      next phase. Any fourth hit fails the gate. An earlier draft named
      `agent-prompt.sh` in the surviving set and read its `@CONTENTCLICKED`
      branch as the reason. That branch holds no `cli activate-pane`: it calls
      `"$focus_exe" "$pane" "$session"` at `:128-132`, and the file's only hit is
      `:136`, which 2.1 deletes. So the old form demanded a hit that a correct
      implementation removes. Note the pattern is `cli send-text` and not
      `wezterm cli`: `agent-prompt.sh:136` invokes it as `"$wz" cli send-text`,
      so a `wezterm cli` pattern does not see the phase's headline removal.
      The third clause cannot be a grep for nothing, and an earlier draft made it
      one. It required
      `rg 'wezterm cli|send-text' modules/home/programs/neovim/config` to return
      nothing, which was written for the draft of 2.7 that deleted the wezterm
      control surface. 2.7 now keeps it on purpose, so that command returns hits
      in files the phase decides to keep and the gate could never go green. A
      gate that cannot pass gets waived, and a waived gate gates nothing. Replace
      it with a comparison against an expectation derived BEFORE the edits, not
      after them. Task 1.1 records `owner-wezterm-sites.txt` from
      `rg --no-line-number '"wezterm"|wezterm cli'` over
      `modules/home/programs/neovim/config` with `-g '!**/doc/**'`, minus the four
      lines this phase removes (`bin/nvim-ctl:140` and `:142` by 2.6,
      `utils/wezterm_terminal.lua:53` and `:57` by 2.8). 31 lines today, minus 1
      for `doc/`, minus 4 removed, is 26. An earlier draft said 27, subtracting the
      removed lines but not the `doc/` line the same sentence excludes. Exclude
      `doc/` because 2.6 rewrites `agent-ide-integration.md` and its new text is
      not predictable inside an exact comparison. Run it without line numbers: 2.8
      removes 41 lines above `wezterm_terminal.lua:100` and five surviving sites in
      that file sit below the cut, so a positional artifact fails on a correct
      implementation. Two earlier drafts also had the recording inside the phase:
      2.7's was written before 2.8 edited two of its lines, so it could never
      match, and 2.8's snapshotted the post-edit tree and compared it to itself, so
      a site left behind would be recorded as correct and the gate could not fail.
      Run it from the repository root, with the tree as an argument, exactly as
      1.1 writes it. This is not pedantry: `rg` prefixes each line with the path
      as given, so running the same pattern from inside
      `modules/home/programs/neovim/config` emits `./lua/harness/preview.lua`
      where the baseline holds
      `modules/home/programs/neovim/config/lua/harness/preview.lua`. All 26
      matched texts are then identical and all 26 lines still differ, so the gate
      fails on a correct implementation and the diff reads as total drift.
      Observed while running this gate.
      At 2.9 the live command must equal that 26-entry set exactly. That fails when a site is left
      behind and it fails when a new one appears, which a grep for nothing does
      neither of once the answer is not zero. It must match the argv-table form,
      since nine of the fourteen sites are written that way and only five are
      string-form: `wezterm_terminal.lua:53`, `:57`, `:104`, `:165`, and
      `preview.lua:61`. An earlier draft said the old pattern saw four, a number
      left over from the draft that called the total thirteen; it returns eight
      lines over the config.
      The fifth clause is `rg -n '"wezterm"' pkgs/sysinit-agent` returning
      nothing, which is what proves 2.2 deleted the per-tool-call fork. Clause
      one cannot see it: the fork was
      `exec.Command("wezterm", "cli", "list", "--format", "json")`, so no
      `wezterm cli` string pattern matches it, and an earlier draft left the fork
      with no clause at all. Match the quoted word and not the bare word. An
      earlier draft required `rg -n 'wezterm' pkgs/sysinit-agent` to return
      nothing, which no correct implementation can satisfy, because 2.2 KEEPS
      the OSC `SetUserVar` write and that code says in its own doc comment which
      terminal reads it. Eight prose hits survive a correct 2.2:
      `agentstate.go:1`, `:6`, `:26`, `:232`, the four comment lines where the
      removed fork is explained, and `agentstate_test.go:141`. A gate that
      cannot pass gets waived, which this task says twice about other clauses.
      The quoted form is the executable one: Go spells the argv head as a string
      literal, so `"wezterm"` matches the fork and no comment.
      The fourth clause is that the config still loads:
      `nvim --headless -c 'lua require("harness.api").setup()' -c qa` exits 0.
      It must call `setup()` and not merely require the module: every reference
      to the affected modules sits inside a function body (`harness.control` at
      `api.lua:181` and `:199`, `harness.instance` at `:198`,
      `harness.spec_watch` at `:200`), so a bare require loads the file and runs
      none of them, and a missed edit throws on every editor start while the gate
      reads green. Nothing else in this phase
      would catch a lua file broken by 2.5, 2.6, 2.7, or 2.8. The neovim config
      is an out-of-store symlink, so nix never evaluates it and the
      derivation-path comparison at 2.12 cannot see it.
      Two earlier forms of this gate could not pass. One grepped for strings that miss
      `agentstate.go:329`, which forks `wezterm cli list` on every tool call.
      That fork must go, but NOT by substituting `WEZTERM_PANE`: it sits inside
      `paneWorkspace` and returns the pane's workspace, not its id, and the id
      is already in hand at `:60`. The workspace becomes `id.session` at `:296`
      for every pane outside a seshy session directory, and
      `agent-sessions.sh:66` groups the whole rollup by that field, so dropping
      it collapses the deck to `default`. Do not cache it in the record either:
      a cached workspace is a per-pane fact under a bare pane id, so a reused id
      serves the previous occupant's value, and `ui.lua` reads the workspace
      live on every tick (`:357`, `:731`) while `agent-sessions.sh` would group
      by the cached one, giving one pane two session names with nothing
      comparing them. Stop resolving the workspace in `agent-state` altogether.
      The record carries the pane id and the seshy-derived session when the
      directory supplies it (`agentstate.go:292-295`), and a reader that needs
      the workspace fallback resolves it live, which `ui.lua` already does and
      `agent-sessions.sh` can do from the `wezterm cli list` it already runs at
      `:38`. That removes the fork rather than amortizing it.
      The other spanned `modules` whole, which matches
      `zsh/integrations/seshy-wezterm.zsh:57`, `plugins/smart-splits.lua:2`, and
      `utils/terminal.lua:78`, none of which is agent-reachable and none of
      which this change touches. Each command is scoped to a tree this phase
      owns, so "reachable from an agent" is no longer a human judgment. This is
      the STOP gate for the phase. `deps:` 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8
- [x] 2.10 Verify: `wtrun` still passes its own contract unchanged, since 2.4
      changes who may call it and not what it does. `wtrun -w 0 'false'` exits 1,
      `wtrun -w 1 'sleep 5'` exits 75, and the `sleep` is still running when it
      does. `deps:` 2.4
- [x] 2.11 Confirm: owner uses an agent for one session and reports whether
      anything they relied on is now missing. The owner directed on 2026-08-08
      that this be tested mechanically instead, so record what was and was NOT
      covered rather than claiming the session happened. Exercised: the whole
      `lv426` system builds; the full neovim config starts with no error; all 13
      surviving harness keymaps resolve and `<leader>jC` is gone; the three
      deleted lua modules no longer resolve and the seven kept ones still load;
      `spec_watch` is off at startup and a `DirChanged` does not resurrect it;
      `agent-state` writes a record and `agent-sessions` groups it under the
      live workspace with no fork; the OSC user var still decodes to
      `status|reason|since|agent`; an alerter answering `Accept` drives no pane
      and `--actions` is no longer passed; click-to-focus still fires; `gemini`
      now reaches the rich alerter that the deleted keystroke table used to gate;
      the built system ships the `wtrun` binary and no `wtrun` skill.
      NOT covered, and this is the residue the owner still carries: whether
      daily use turns up something none of those probes name. That surfaces on
      the next `nh darwin switch`, not here. Record, rather than claim absence,
      that agent paths to a pane survive this phase. `wtrun` stays on `PATH` by
      construction because 2.4 makes it an owner command
      (`skill-tools.nix:31-34`, independent of `skills/render.nix`), and what
      2.4 removes is the description and the `allowed-tools` grant at
      `skills/wtrun/SKILL.md:3`. The allowlist default is ask, not deny
      (`lib/allowlist.nix:296`, `:300`, `:305`), so an agent that types it gets
      a prompt. Under pi it gets nothing: `harnesses/pi/default.nix:487` sets
      `yoloMode = true` and `lib/allowlist.nix:289-290` emits no entries at all.
      And any harness with a Bash tool can call `wezterm cli split-pane`
      directly, which this repository cannot prevent. Removing the
      advertisement is the largest reduction available and it is not a fence.
      `deps:` 2.9
- [x] 2.12 Verify: re-record the two host drvPaths and the two derivation-path
      files, as 1.1 does, because 3.14 compares against this recording. This phase
      changes them on purpose, so name each difference and its cause by diffing
      the derivation-path sets against 1.1's, rather than the hashes alone. Name
      the referent: an earlier draft said only "name each difference", and a diff
      whose second operand is unstated cannot be checked by a reviewer. The
      `lv426` half runs locally and the `arrakis` half runs in the CI job 1.1
      adds, which is where every gate from here on gets its Linux side.

      Recorded 2026-08-08. Both hosts moved by exactly the same shape, which is
      itself the result: `lv426` 7440 to 7438 and `arrakis` 14848 to 14846.
      Nothing APPEARED on either host. Two derivations DISAPPEARED on each, and
      they are the same two, `skill-amp-wtrun-SKILL.md.drv` and
      `skill-claude-wtrun-SKILL.md.drv`: task 2.4 took `wtrun` out of the
      registry and both harnesses had been rendering it. 29 derivations MOVED on
      each host with their names unchanged. Every one traces to two edits.
      `agent-prompt.drv` is 2.1. `agent-state.drv`, `agent-sessions.drv`,
      `sysinit-agent-0.1.0.drv`, and its `-go-modules` are 2.2. The remaining 24
      are ancestors: the `writeShellApplication` wrappers over `sysinit-agent`
      (`citelock`, `diffnote`, `claude-statusline`, the three guards), the
      generated settings that name those wrappers by store path
      (`claude-code-settings.json`, `hm_.agentshooks.json`, `hm_devinhooks.v1.json`,
      `codex-config`, `hm_.codexAGENTS.md`), and the profile and activation roots
      above them.
      The neovim edits are absent from both sets on purpose. That config is an
      out-of-store symlink, so nix never evaluates it, which is the same fact
      2.9's fourth clause exists to compensate for.
      The CI job reproduced the local `lv426` recording byte for byte, so 1.2's
      property still holds after the phase-2 edits. Both jobs failed against the
      committed phase-1 baseline before it was replaced, which is the gate
      working: the closure moved and the gate said so.
      `deps:` 2.11
- [x] 2.13 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on whether 2.2's self-report line is a real distinction
      or a rationalization, on whether 2.4 leaves any agent path to a pane, and
      on whether 2.7 leaves any agent route into `harness.api`, and on the
      `$EDITOR` shim kept in 2.8. `deps:` 2.12

## 3. The note file is ours, hunk reads it

- **SHAPE** loop
- **STOP** `nix flake check` exits 0; `go test ./...` under `pkgs/sysinit-agent`
  passes with all ten store-discipline tests of the writer still present and
  asserting the same behavior; `review` displays a note written while no viewer
  was running AND a note written while it was running behaves as 3.10 recorded;
  and `rg -n 'nvim|neovim|diffnote\.lua|CodeDiff' pkgs/sysinit-agent` returns no
  hit. The last clause covers `go.mod` and `go.sum`, so it fails unless 3.6
  re-vendors, and it fails on the stale comment at `repo.go:63` until 3.6
  corrects it. An earlier form cited 3.5 for both, which 3.6 owns, and used the
  pattern `nvim|neovim`, which misses the two package comments this phase
  strands: `repo.go:3` and `diffnote.go:4` both name `lua/harness/diffnote.lua`,
  which 3.7 deletes, and neither string matches
- **MAX-ITERS** 3
- TERMINAL: CAPPED at 3 iterations, or STALLED after 2 iterations with the same
  hunk command failing. On either, stop and report which presentation behavior
  hunk does not cover, and leave that behavior out rather than rebuilding it.

- [x] 3.1 Gather: probe the `hunk` binary, not its README. It is not installed
      on this machine and 3.2, which installs it, depends on this task, so probe
      it with `nix run github:modem-dev/hunk -- ...`, which needs no repo change.
      An earlier draft said "the installed binary" and was completable only by a
      route it did not name. Record the
      schema `hunk diff --agent-context` expects, with a file it accepts and one
      it rejects, AND which systems its flake provides packages for, since 3.13's
      check is instantiated on three, AND what it does with a path that does not
      exist, AND whether
      `--watch` re-reads that file when it is REPLACED
      BY RENAME, which is how it will actually change. An in-place append is a
      false positive: `store.Publish` writes a temp, fsyncs, and calls
      `os.Rename` (`store.go:124-144`), installing a new inode, so a viewer
      holding a descriptor keeps the old one and a viewer watching the file
      rather than its directory loses the watch. The renderer being deleted knew
      this and watched the directory (`diffnote.lua:286`, `:298`). If a
      directory watch is what it takes, name the directory. Task 3.10 asks the
      same question through the real writer, so where they disagree, 3.10
      governs. The second half is the live workflow: if `--watch` only re-diffs the
      working tree, then the way to see a new note is to re-run `review`, and
      the design must say that rather than claim a watch covers it. This is the
      load-bearing probe and an earlier draft omitted both halves. If that flag
      expects hunk's own `filePath`/`newLine` vocabulary, then
      "the note file is ours" is only true with an explicit adapter, and the
      adapter has to be named. Also record, for `session comment add`, `apply`,
      `list`, `clear`, and `session get`, every accepted flag and whether a
      comment carries any field beyond a file, one line selector, and a summary.
      Record the result in the change folder, because decision 2 rests on it.

      Recorded 2026-08-08 in `hunk-probe.md`, against hunk 0.18.0. It overturned
      decision 2's stated reasoning, which is why this task says probe the binary
      and not its README. All three of that reasoning's claims are false:
      `rationale` and `author` are first-class fields on both hunk surfaces, and
      the sidecar annotation carries an optional `id`, which is an upsert key.
      The sidecar also takes a line RANGE, not one line selector. design.md
      decision 2 is corrected; its conclusion survives on a different reason.
      Four answers this task asked for, all favorable. The `--agent-context`
      schema is `src/core/agent.ts`, undocumented in the bundled skill and
      published only as an example; `summary` is the only required annotation
      field. `rationale` is a plain string with no newline handling, so 3.5 has
      no flattening loss to record. A path that does not exist FAILS, exit 1 with
      `ENOENT`, which settles 3.3's open choice: omit `--agent-context` when there
      is no export rather than passing the missing path through. `--watch` DOES
      survive replace-by-rename, because hunk groups watch targets into
      parent-directory groups rather than watching the file, so 3.5's
      republish-inside-the-lock design works with no adapter and no re-run. The
      one trap is `--agent-context -`, which returns a null watch plan, so
      `review` must pass a real path. And the flake provides exactly
      `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux`, which is
      `cacheSystems` exactly, so 3.13 needs no gating; 3.2's reason for pinning
      is unaffected and separate.
      `deps:` 2.9
- [x] 3.2 Act: add the `hunk` flake input back, pinned to its own nixpkgs. Do
      not make it follow ours: its build enumerates `perSystem.x86_64-darwin`,
      which nixpkgs-unstable dropped. Restore `programs/hunk.nix` from
      `878f78300^` and re-derive its theme from stylix, but do NOT restore its
      `core.pager` setting. `archive/2026-08-06-quiet-pi-sidebar-and-diff-review`
      removed that deliberately, and routing every `git diff` and `git log`
      through a reviewer is a second decision this change is not making.
      Also restore the `hunk` line in `overlays/inputs.nix`, which
      `878f78300^:overlays/inputs.nix:20` had and today's does not. Neither the
      input nor `programs/hunk.nix` puts `hunk` into the overlaid package set:
      the home module supplies its own package
      (`878f78300^:modules/home/programs/hunk.nix:44`), and `flake.nix:181-187`
      passes checks only `{ lib, system, pkgs }` with no `inputs` and no `self`.
      So without the overlay entry there is no route to `hunk` from `checks/`,
      and 3.13 cannot be written. `deps:` 3.1
- [x] 3.3 Act: ship `review`, a command that runs
      `hunk diff --agent-context <notes>` for the current repository. Do not
      ship a wrapper named `hunk`. An earlier draft did, and it broke the
      change's own non-goal at `proposal.md:187-188`: a script named `hunk` that
      wraps `hunk` is one name for two things, it collides with `pkgs.hunk` on
      `bin/hunk` in a single home profile, and it leaves `which hunk` unable to
      say which ran. A separate verb composes instead of shadowing. `review`
      passes its arguments through, so `review --watch` reaches `hunk` with the
      context flag still applied. It fails loudly when `sysinit-agent` is
      missing, because silence there is indistinguishable from "no notes" and
      that is the ordinary case on the non-Nix path phase 9 builds. It must fail
      the same way when the record exists and the export does not, naming 3.5's
      rebuild verb in the message. That state is not hypothetical: it is the
      state every box is already in the moment this change lands, because a
      record written before it has no export. Nothing calls the rebuild on its
      own, and the phase STOP does not catch this, because its clause writes a
      note first and writing a note republishes the export.
      A repository that never had a note is a different case and must not fail.
      There is neither record nor export, and that is the ordinary state of a
      clean repository, so `review` shows the diff with no context and exits 0.
      That matches the repository's own precedent: `cmdList`
      (`diffnote.go:549-561`) treats an absent store as success and prints an
      empty document. `review` distinguishes the two cases by stating our own
      files, which it can do without help. What 3.1's probe of a nonexistent path
      decides is how the no-notes branch is implemented: pass the missing path
      through, omit `--agent-context`, or synthesize an empty export.

      Shipped as `runtime/review.sh`, installed by `runtime/default.nix` as
      `noteReview`. It takes the probe's answer and omits `--agent-context`
      when there is no export. All four branches were exercised against the
      real `sysinit-agent` and a recording stand-in for `hunk`: a clean
      repository runs `hunk diff --watch` and exits 0; a record with no export
      exits 1 naming `sysinit-agent note rebuild`; after that rebuild the flag
      is applied and `--watch` still reaches `hunk` behind it; and an absent
      `sysinit-agent` exits 1 saying so rather than looking like "no notes".
      `deps:` 3.2
- [x] 3.4 Act: rename `internal/diffnote` to `internal/note` and remove only the
      neovim paths from it. Keep `add`, `apply`, `list`, `clear`, and `path`,
      and keep `--rationale`, `--author`, and `--replace`: task 3.1 establishes
      that hunk has no field for them, so deleting them loses data. Delete
      `--no-open` and every call into `nvimlink`. Keep `internal/store` byte for
      byte.

      Done as `git mv`, so the history follows. The command is `note` now, on
      the binary and on the `runtime/default.nix` shim, which 3.8's allowlist
      has to match. `showNotes`, `DIFFNOTE_NO_OPEN`, and the `nvimlink` import
      are gone; `--rationale`, `--author`, and `--replace` all stayed.
      `internal/store` is untouched, including its one pre-existing gofmt
      misalignment at `store.go:44-47`, which this change does not repair
      because "byte for byte" says not to. `deps:` 3.3
- [x] 3.5 Act: add the hunk-shaped export as a derived file the writer
      maintains, not as a one-shot command. Every `add`, `apply`, and `clear`
      republishes it inside the same store lock that publishes the record, so
      the two cannot disagree. Its path derives from the repo root by the same
      digest as `repo.NoteFile`, so it has an address both ends compute and two
      `review` runs in two panes share one file. An earlier draft made it a
      command `review` ran once, which froze the viewer's input at start: a note
      written afterward changed our record and never reached the file hunk
      re-reads, so the "recoverable by re-read" argument that justified deleting
      the mirror was false. This is still not a push. The writer writes files
      and nobody calls the viewer. Preserve structure across the boundary:
      `rationale` keeps its newlines through `store.Clean` if the schema has a
      multi-line field, and if it has none, record that loss in the design
      rather than flattening into a one-line field, because `store.go:182`
      records that a newline there once forged an extra row. Keep `author` a
      field if the schema has one. `--replace` matches on our record and not on
      the export, so its match key is unaffected. Four things the lock does not
      give, which this task states rather than implies. Two renames cannot be
      atomic together, so one file leads, and the rule is the harm rather than
      the direction of a size change. Never fabricate: the export must not show
      a note the record never had. Record first satisfies that for every verb,
      because it only ever leaves the export holding notes the record used to
      have, which is staleness the rebuild verb repairs. So record first, with
      one exception. `clear` publishes the export first, because there the harm
      is not fabrication but a documented kill switch appearing not to have
      taken effect: record-first would empty the record and leave every note on
      display (`diffnote.go:656-657`).

      An earlier draft keyed this on whether the note set grew or shrank. That
      is undecidable for `add --replace`, which calls `dropMatching` and then
      appends inside one `publishDoc` (`diffnote.go:277-288`, `:319-334`): with
      one matching note the cardinality is unchanged and the contents differ, so
      there is no branch to take. Both orders also violate a strict
      never-show-a-difference invariant there, which is why the rule names the
      asymmetric harm instead. Under the harm rule `--replace` takes record
      first and the window holds a note the record just dropped.

      The lock serializes our own writers and confers nothing
      on hunk, which never takes it, so "cannot disagree" is true only of our
      writers. Give the export its own validator and the same publishing
      discipline as the record, since `store.Publish` calls `Validate`
      unconditionally at `store.go:112` and a plain `os.WriteFile` could reach
      the zero-byte absorbing state `store.go:85-100` exists to prevent. And add
      a verb that rebuilds the export from the record without writing a note:
      `cmdClear` returns early on an absent or zero-byte store
      (`diffnote.go:656-661`, a documented kill switch) and would otherwise
      strand it, and `store.go:27-29` says the record is the owner's to
      hand-edit, so without a rebuild a hand-edit leaves `review` showing the
      pre-edit state with no indication. The rebuild takes the same lock as the
      writers: without it, it can read the record, lose a race to a concurrent
      `add`, and publish an export derived from the pre-add state, which is the
      lost update `TestConcurrentAddsLoseNoNote` catches for the record and
      nothing yet catches for the export. Publish the export inside the lock and
      before the explicit `release()` that `cmdAdd`, `cmdApply`, and `cmdClear`
      each call, because a second publish added after that line reads naturally
      and lands outside it. Add a test that catches the wrong version, and assert
      the ordering rather than the end state. Assert that at the moment
      `release()` is called the export on disk already equals a rebuild from the
      record, through a seam on the EXPLICIT release calls at
      `diffnote.go:292`, `:398`, and `:706`. Name those three line numbers,
      because each of the three commands releases twice and the two are not
      interchangeable. `cmdAdd` takes the lock at `:267` and has `defer release()`
      at `:271` as well as the explicit call at `:292`; `cmdApply` is `:378`,
      `:382`, `:398`; `cmdClear` is `:678`, `:682`, `:706`. `store.go:67-68`
      confirms the pair is deliberate, guarding against a double release. Bound to
      the explicit call the assertion is deterministic, because the lock is still
      held and no other writer is in the critical section, and it fires on every
      invocation including single-threaded ones. Bound to the `release` variable
      it also fires at function return with the lock dropped, where another
      process may have written the record, so it fails on correct work. The seam
      needs no refactor and does not touch `internal/store`: `store.go:52`
      documents that `Lock` returns the release function, so `release` is a local
      closure in `diffnote`, and a package-level hook called immediately before
      each explicit call is one `var` and three lines. One path is vacuous rather
      than false and that is correct: `cmdClear`'s kill-switch return at
      `diffnote.go:658-661` happens before `s.Lock()` at `:678`, so the seam never
      fires there.
      An earlier draft asked instead for a concurrent test in the shape of
      `TestConcurrentAddsLoseNoNote`, comparing the export against a rebuild
      after concurrent adds. That shape does not transfer, and the reason is a
      real asymmetry. A lost add is permanent, so the post-hoc count at
      `diffnote_test.go:533-557` is a sound instrument for it. A stale export is
      self-healing: every writer re-reads the record and republishes, and
      `wg.Wait()` returns only after the last publish, which read a record already
      holding every note. So the buggy version passes except on the one
      interleaving where an older read lands last, and nothing in the test forces
      that interleaving. Keep the concurrent test, because it does add real
      detection, but do not call it the gate. The STOP is `nix flake check` plus
      `go test ./...`, and an implementer who publishes after `release()`, which
      this task itself calls the reading that comes naturally, passes both unless
      the ordering assertion is there. 3.13 gates the export schema
      against what `hunk diff --agent-context` accepts, which is a different
      property, and 3.15 hands the rest to a critic, which 4.3 rules out as a gate.
      The STOP already runs `go test ./...`, so the wiring costs nothing. Mark the export as derived in the file itself. That
      is advisory and not enforcement: nothing compares the export against the
      record, so an owner edit is still overwritten silently and the marker only
      changes what they can learn afterward. Do not also put it in the skill,
      because agents never open the export and the owner who stumbles on it is
      not reading an agent skill. The marker must be a key hunk's parser sees,
      since the export carries hunk's schema and JSON has no comments, so 3.1
      also records whether `--agent-context` tolerates an unknown top-level key
      and 3.13's accepted fixture is the marked file rather than a bare one. Rebuild fails on a malformed
      record because `readDoc` refuses one (`diffnote.go:147-160`); that is a
      loud failure and `clear --yes` stays the documented escape.

      Shipped as `internal/note/export.go`. `repo.ExportFile` shares
      `noteBase` with `repo.NoteFile`, so the two addresses cannot drift.
      Order is record-then-export in `add` and `apply` and export-then-record
      in `clear`, each inside the lock and before the explicit `release()`.
      The seam is `beforeRelease`, one package-level `var` and three call
      sites, exactly as this task specified. `rebuild` takes the same lock.
      The ordering assertion was mutation-tested: moving the export publish
      after `release()` in `cmdAdd` fails
      `TestAddPublishesTheExportBeforeReleasingTheLock` and leaves every other
      test green, which is the case the task said a post-hoc comparison would
      miss. The derived marker rides in the root `summary`, which the parser
      reads and the viewer displays; an unknown key would have been dropped
      silently. A multi-line rationale crosses intact, so there is no loss to
      record in the design. `deps:` 3.4
- [x] 3.6 Act: delete `internal/nvimlink` and the `neovim/go-client` dependency,
      then re-vendor. Keep `internal/repo`. An earlier draft deleted it on the
      true premise that its callers are all in the note writer and the false
      conclusion that the writer dies: 3.4 keeps the writer, and with it
      `repo.Root` and `repo.NoteFile` at `diffnote.go:171-183` and
      `repo.RelativeToRoot` at `:256`, `:371`, `:570`, and `:672`. It is not a
      path-derivation package a manifest can replace. `Root` scrubs `GIT_DIR`,
      `GIT_WORK_TREE`, and `GIT_INDEX_FILE` so a hook-invoked agent does not
      inherit the triggering repository, and `RelativeToRoot` is a containment
      check that resolves symlinks because macOS `/tmp` is one. The phase 4
      manifest owns the `agents/diff-notes/` prefix; `repo` owns the per-repo
      digest under it. Correct the stale references in the package comment at
      `repo.go:3-6`, which names `lua/harness/diffnote.lua` that 3.7 deletes, and
      in the `StateHome` comment at `repo.go:63` while here, or the phase STOP
      gate cannot go green.

      It was the module's last dependency, so `go mod tidy` emptied `go.sum`
      and the file is deleted rather than left empty. `overlays/sysinit-agent.nix`
      takes `vendorHash = null` to match: a hash there would name an empty
      derivation the build never fetches. `repo.go` keeps `Root`,
      `RelativeToRoot`, `NoteFile`, and `ExportFile`; the three stale comments
      are corrected. The phase STOP's
      `rg -n 'nvim|neovim|diffnote\.lua|CodeDiff' pkgs/sysinit-agent` returns
      nothing. `deps:` 3.4
- [x] 3.7 Act: delete `neovim/config/lua/harness/diffnote.lua` and its callers
      in `plugins/codediff.lua`. Delete the five `harness.diffnote` call sites at
      `:69-71`, `:87`, `:102`, `:121`, and `:128`, and the two keymap entries
      that contain them. Do not delete `:69-128` as a span: the file is 142
      lines, that range ends inside the `<leader>dN` entry and leaves an orphan
      `end,` tail, and it also swallows the `CodeDiffFileSelect` wrapper, the
      `CodeDiffClose` restore, and the `<leader>dd` and `<leader>dH` keymaps,
      none of which is diffnote. This removes inline virtual text, the
      `<leader>dn` quickfix list, the `<leader>dN` float, and the fs watcher.
      That loss is the decision, not an oversight.

      Removed by call site, not by line span, exactly as this task warned.
      `codediff.lua` is 117 lines from 142 and keeps `CodeDiffFileSelect`, the
      `CodeDiffClose` restore, and `<leader>dd`, `<leader>dH`, and `<leader>dh`.
      Two `vim.schedule` bodies now hold only `apply_diff_winopts`, and the
      `pcall` wrappers around them went with their contents. `deps:` 3.6
- [x] 3.8 Act: replace `skills/diffnote/` with a skill that wraps
      `hunk skill path` for reading, and documents `sysinit-agent note add` for
      writing. Update the five `diffnote` allowlist entries at
      `llm/lib/allowlist.nix:202-204` and `:208-209`, and the registration in
      `pkgs/sysinit-agent/main.go`. The pi extension needs more than its prompt
      rewritten: `diff-review.ts:32` sets
      `VIEWER_COMMAND = ["nvim", "-c", "CodeDiff"]`, one line above the range an
      earlier draft named, and after 3.7 that view renders no notes, so pi would
      open an editor that cannot show the notes its prompt then asks for. Point
      it at `review` and rewrite the premise at `:34-35` that the CodeDiff view
      watches the file. Four more sites in that file are stale for the same two
      reasons and an earlier draft named none of them: `:4` and `:117` name
      neovim as the viewer, which stops being true when this task re-points it;
      `:120-121` repeats the false premise of `:35`, that the editor watches for
      notes, which stops being true after 3.7; and `:7` is the
      `wezterm cli split-pane` prose that task 2.9 hands to this task by name.
      A fifth sits inside the prompt range: `:37` says "A neovim CodeDiff review
      of the working tree is now open beside this session", which names the viewer
      this task re-points and which the `:36-44` rule below does not reach,
      because that rule is about command names. Rewrite all five.
      Verify the new allowlist entries match what the new skill tells agents to
      type, character for character. That check belongs to the skill alone, where
      both sides are literal. Do not extend it to the pi prompt, which an earlier
      draft did: `allowlist.nix:208-209` are globs (`"diffnote add *"`) and
      `diff-review.ts:36-44` is prose joined with spaces at `:44`, so there is
      nothing to compare character for character. The stated consequence is also
      false for pi, which consults no allowlist at all:
      `harnesses/pi/default.nix:487` sets `yoloMode = true` and
      `allowlist.nix:289-290` then emits no entries. A stale command name there is
      not a downgrade to a prompt, it is a command that does not exist. Check the
      pi prompt against the rule that applies instead: every command name in
      `:36-44` must be a subcommand `sysinit-agent note` provides after 3.4. For
      the skill, a mismatch fails nothing and silently downgrades every note write
      to a prompt, which reads as friction rather than as a defect.

      The skill is `skills/note/`. Every command it names resolves to an
      allowlist entry except `clear`, which is left off deliberately and the
      skill says so: it is the owner's kill switch and it deletes their notes
      too. `allowed-tools` is `Bash(sysinit-agent:*)` alone, because
      `render.nix:130` accepts only a single lowercase word inside `Bash(...)`,
      so `Bash(sysinit-agent note:*)` is not expressible. `hunk` is off that
      list on purpose: `hunk skill path` is on the read-only allowlist, and
      every other `hunk` verb opens a viewer that is the owner's to open.

      One thing this task did not name and the apply decided: the `diffnote`
      shim in `runtime/default.nix` is DELETED rather than renamed. A bare
      command named `note` on PATH is a generic word with no caller left, since
      the skill and the allowlist both spell the full `sysinit-agent note`. That
      is the same one-name-one-thing rule 3.3 applies to `review`.

      All six pi sites are rewritten. `VIEWER_COMMAND` is `["review",
      "--watch"]`: without `--watch` the pane would open before the annotate
      prompt runs and would never show the notes it then asks for. `:71` was a
      seventh stale `CodeDiff` reference that no draft named. `deps:` 3.7
- [x] 3.9 Verify: a note carrying a multi-line rationale and an author, written
      with no `hunk` process running, is readable from the RECORD afterward with
      both fields intact. That half is unconditional. What `review` displays
      depends on 3.1: if the schema has no multi-line field, 3.5 permits the
      loss in the export, and then this task asserts only that the design says
      so. The record is the contract; the display is what the probe allows.

      Run with zero `hunk` processes alive. A note with a three-newline
      rationale and `--author pi` reads back from the record with both fields
      byte-identical, newlines included. The conditional half turned out
      unconditional too: 3.1 established the sidecar `rationale` is a plain
      string with no newline handling, and the export carries the same three
      newlines, so there is no loss for the design to permit.
      `deps:` 3.7
- [x] 3.10 Verify: a note written AFTER `review --watch` is already running
      either reaches the viewer within 5 seconds or does not. Run it as an
      experiment, not as a disjunction an edit to `design.md` can satisfy:
      confirm the note is absent in the running viewer first, write it without
      touching any tracked file so a working-tree re-diff cannot be mistaken for
      a context re-read, and bound the wait. A miss at 5 seconds is not an
      absence: re-observe at 60 seconds and after a focus change before
      concluding, or a poller on a long interval gets recorded as never and the
      design tells the owner to re-run `review` for nothing. Write the outcome
      to a file in the change folder, because the phase STOP cites it and a STOP
      clause needs an artifact rather than a memory. Make `design.md` match. Every earlier draft wrote the note before the
      viewer started, so the one property the no-push decision rests on was
      asserted in prose and checked nowhere.

      It does not reach the viewer. The artifact is `watch-observation.md` in
      this folder. Absent at 5, 15, 30, and 60 seconds, after a focus change
      into and out of the pane, and after keystrokes sent to it.

      The control fails too, which changes how the result may be stated. A
      tracked-file edit does not reach the running viewer either, so `--watch`
      auto-reloaded for nothing in this environment. The narrow claim "the
      sidecar specifically is not re-read" is therefore unsupported and is not
      made. The supported claim is broader: nothing reaches a running viewer on
      its own.

      A previous attempt reported the same absence and was discarded for
      failing its own control. Three things separate this run. `session get`
      reads live daemon state, proved by an explicit `session reload` moving the
      reported diff from `+1 -1` to `+3 -3` in the same session. The seed note
      IS reported by the same instrument in the same session, so a positive
      reading is reachable. And `--watch` was confirmed on the process command
      line with `ps` rather than inferred from the wrapper. The first run of
      this session was itself thrown away: a `session reload` issued DURING the
      observation dropped the agent context and every later reading was zero for
      that reason instead of the one under test.

      One finding with no workaround, which is why the design cannot just say
      "reload". `hunk session reload -- diff` picks up the working tree AND
      drops the agent context to zero, trading a stale note view for no notes.
      Re-running `review` is the only remedy.

      This contradicts 3.1's source reading, and 3.1 named the tie-break in
      advance, so 3.10 governs. Four artifacts said the opposite and are
      corrected: `design.md`, the `sysinit-agent note` usage text, the `note`
      skill, and the pi extension. The pi extension needed more than prose:
      `VIEWER_COMMAND` was `["review", "--watch"]` and the flag's entire stated
      reason was this behavior, so the flag is dropped and the notify line tells
      the owner to re-run `review`. 3.5's republish-inside-the-lock design is
      untouched: it is what keeps the export correct on disk for the next
      `review` to read. `deps:` 3.5
- [x] 3.11 Verify: `go test ./...` passes under `pkgs/sysinit-agent` with all
      ten store-discipline tests of the writer still present and asserting the
      same behavior: `TestZeroByteStoreIsNotAbsorbing`,
      `TestMalformedStoreIsRefusedNotOverwritten`,
      `TestFailedProducerDoesNotPublish`, `TestSymlinkedStoreIsRefused`,
      `TestWriteIsRefusedWhileTheLockIsHeld`,
      `TestLockIsReleasedAfterEveryWrite`,
      `TestApplyRejectionsLeaveTheStoreByteIdentical`,
      `TestApplyRejectionDoesNotCreateAStore`, `TestConcurrentAddsLoseNoNote`, and
      `TestRelativePathResolvesThroughASymlinkedCwd`. An earlier draft gated on
      `./internal/store/...` alone. That package is kept byte for byte, so its
      tests cannot fail, and they assert the property exists rather than that
      the writer still uses it. Dropping the `Lock` call in 3.4 would have
      passed the old gate clean. A package rename may change their package
      clause, and 3.4 deletes `--no-open`, so the shared helper's
      `t.Setenv("DIFFNOTE_NO_OPEN", "1")` at `diffnote_test.go:46` and its stale
      comment at `:44-45` go with it, as do two more comments the STOP pattern
      does not match: `:183` names `diffnote list`, which 3.4 renames, and `:464`
      names "a store the editor filters", whose editor half 3.7 deletes. Nothing
      else may change. Naming that
      exception matters because literal compliance would otherwise keep dead code
      that no STOP pattern matches.

      All ten are present and green. Every named exception was taken and
      nothing else in the test file changed: the `DIFFNOTE_NO_OPEN` setenv and
      its comment are gone with `--no-open`, `:183` says `note list`, and
      `:464` no longer names an editor. `internal/store` and its tests are
      untouched. `deps:` 3.5
- [x] 3.12 Verify: `neovim/config/lua/` has no remaining reference to any
      sysinit binary or state path, so the config is standalone. Scope this to
      the whole lua tree, not `harness/` alone: 3.7 edits
      `plugins/codediff.lua`, which an earlier draft's scope excluded, and three
      of its call sites sit inside `pcall` (`:68-72`, `:86-88`, `:101-103`), so
      a missed one fails silently on every CodeDiff open rather than throwing.
      Load the config headlessly here, since no other gate in the phase does.

      Clean on both halves, over the whole lua tree. No sysinit binary name
      appears: not `sysinit-agent`, `agent-state`, `agent-notify`,
      `agent-focus`, `agent-prompt`, `agent-sessions`, `agent-refine`,
      `agent-identity`, `agent-busy-panes`, `diffnote`, `nvim-ctl`, `wtrun`,
      `loop-gate`, `sy-gate`, or `worklog`. No state path appears either:
      neither `.local/state`, `XDG_STATE_HOME`, `agents/diff-notes`, nor
      `agents/panes`. Every shell-out in the tree goes to a third-party tool,
      `git`, `wezterm`, `tmux`, `go-grip`, or `open`.

      The `pcall` hazard this task named needed more than a headless load, so
      both were run. The load is clean and exits 0. Then `:CodeDiff` itself was
      exercised headlessly, which is what reaches the three wrapped call sites:
      it opens 2 tabpages and 3 windows on a `CodeDiff Explorer` buffer, with an
      empty message log. The surviving normal-mode `<leader>d` keymaps are
      exactly `dd`, `dh`, `dH`, and `dr`. `dn` and `dN` are gone, which is 3.7's
      stated loss observed rather than assumed, and `dr` belongs to
      `review.nvim` and predates this change. `deps:` 3.7
- [x] 3.13 Act: add a `checks/` assertion that the export schema still matches
      what `hunk diff --agent-context` accepts, using the accepted and rejected
      fixtures 3.1 produces. Put it in `checks/` and not in `.githooks/pre-commit`,
      which an earlier draft chose. That hook's established idiom is
      skip-when-absent (`:11`, `:22`, `:31`), so a branch written in it is a
      no-op on any box without `hunk`, and `hunk` is not installed on this one.
      A guard that silently skips is the failure the task exists to catch.
      `nix flake check` is already in the phase STOP and 3.2 makes `hunk` a flake
      input, so under `checks/` the tool is present by construction and the check
      cannot skip. Scope it by system. `flake.nix:181-187` instantiates checks
      over `cacheSystems` (`:109-113`), which is `aarch64-darwin`, `x86_64-linux`,
      and `aarch64-linux`, so a `nativeBuildInputs = [ pkgs.hunk ]` forces that
      attribute at eval on both Linux systems. If hunk's flake does not provide
      them, `nix flake check` fails at eval, and that is the phase STOP's first
      clause. 3.2's own reason for pinning, that hunk's build enumerates
      `perSystem.x86_64-darwin`, is evidence its system coverage is unusual, and
      `cacheSystems` does not include `x86_64-darwin` at all. Restrict the check
      to the systems 3.1 records hunk as providing, or have 3.2 gate the overlay
      entry the way the other platform-specific entries are gated. The `mise.toml` generator in phase 9 guards the
      same shape of drift. Republishing on every write makes a schema mismatch
      silent and continuous rather than surfacing once: the writer keeps
      producing a file hunk ignores, and `review` shows empty context with no
      error on either side. Do not pin the watch behavior in the same assertion. An
      earlier draft did, and it contradicts 3.10, which states that "a miss at 5
      seconds is not an absence: re-observe at 60 seconds and after a focus
      change before concluding". No automated check has a focus or 60 seconds per
      run, so a shorter bound fails on a change that is correct. Assert the
      `hunk` node's `locked.rev` in `flake.lock` instead, which is a
      deterministic string, and re-run 3.10 by hand when it moves. It is in the
      lock and not in `flake.nix`: `878f78300^:flake.nix:108-111` pins hunk's
      nixpkgs and leaves `url = "github:modem-dev/hunk"` unpinned. The risk is the same one: an input
      bump can turn a poll into a file watch silently. Also assert that the replacement review skill
      appears in a rendered harness instruction block: `hunk skill path` resolves
      at runtime while the skill tree renders at build time, and the design's
      claim that it reaches all eleven harnesses through existing machinery has
      no verify today. Name the route for that clause, because a rendered block
      lives inside an evaluated home configuration and `checks/` receives only
      `{ lib, system, pkgs }` (`flake.nix:181-187`), so it has no handle on
      `self` or on any configuration. Assert two things, not one,
      because the skill reaches the eleven harnesses two different ways. Only
      codex gets an inlined list: `instructions.nix:93` includes the `skills`
      section only for a harness in `harnessesWithoutSkillLoader`, and that list
      is codex alone (`:32-34`). So
      assert three things, enumerated by destination
      rather than by harness, because `rg` over `llm/default.nix` for a skills
      destination returns a closed list of four roots.
      One: the skill name appears in the block `makeInstructions` returns for
      codex. Two: the `allSkills` render installs the file at `.claude/skills/`
      (`render.nix:197`, `llm/default.nix:12`), which is also the root the six
      harnesses with no copy of their own read through `skillsRoot`
      (`instructions.nix:40`, `gemini/default.nix:63`, `cursor/default.nix:37`).
      Three: the `ampSkills` render installs it at the three roots it feeds,
      `.config/amp/skills/` (`llm/default.nix:95`), `.config/devin/skills/`
      (`:111`), and `.copilot/skills/` (`:127`). Three is a separate assertion
      because `renderSkillsFor "amp"` (`render.nix:193`) is a separate evaluation
      that can fail on its own, and an assertion on `.claude/skills/` alone stays
      green while amp, devin, and copilot lose the skill. Two earlier drafts got
      this wrong in opposite directions: one asserted the block for all eleven
      when only codex has it, and one asserted one file path for ten when the
      answer is one root for six, another for three, and a block for one.
      `nix flake check` is this phase's first STOP clause, so a wrong grouping
      fails on correct code.
      The check imports `skills/render.nix` for `localSkillDescriptions`
      (`render.nix:195`, exported at `:210`), which is a required argument of
      `makeInstructions` (`instructions.nix:37-42`) and has no other producer, and
      passes it in. What it must not do is assert against `render.nix`'s output
      alone, which an earlier draft did: that proves membership in the description
      set, not presence in a rendered block. The clause was written for the
      pre-commit hook, which could grep the store, and it did not survive the move
      unchanged.

      Shipped as two files rather than one, because the two properties fail
      independently and a shared derivation would hide which one broke.
      `checks/hunk-agent-context.nix` carries the schema fixtures and the
      `locked.rev` assertion; `checks/llm-skill-destinations.nix` carries the
      three destination assertions. Both are wired into `checks/default.nix`,
      which takes `lib` now.

      Both were mutation-tested rather than accepted on a green run, because a
      check that reaches nothing also passes. Dropping `summary` from the
      accepted fixture fails with `hunk refused the document the note writer
      publishes`, which proves the check reaches hunk's parser and that the
      no-TTY build sandbox does not short-circuit it. That was the live risk:
      hunk opens a full-screen viewer, so the exit code cannot separate accepted
      from refused, and the check reads the refusal literal on stderr instead.
      Renaming the skill fails with `does not appear in the instruction block
      makeInstructions renders for codex`.

      Two things this task asked to decide, both now observed rather than
      argued. The system scoping needs no gate: `nix eval` resolves both checks'
      `drvPath` on all three of `aarch64-darwin`, `aarch64-linux`, and
      `x86_64-linux`, so `pkgs.hunk` is reachable everywhere `cacheSystems`
      instantiates. And the destination reproduction is guarded against
      `llm/default.nix` rather than trusted: the check greps that file for each
      of the four root strings, so re-pointing a root there without updating the
      check fails instead of passing against a path nothing writes to.
      `nix flake check` exits 0. `deps:` 3.5, 3.8
- [x] 3.14 Verify: re-record the two host drvPaths and the two derivation-path
      files, as 1.1 does, since 9.9 compares against this recording across phases
      4 through 9. This phase changes them on purpose, so name each difference and
      its cause against the 2.12 recording, by diffing the derivation-path sets
      rather than the hashes alone. Phases 6 through 9 compare against this
      recording, not against 1.1. The `lv426` half runs locally and the `arrakis`
      half runs in the CI job 1.1 adds.

      `lv426` re-recorded. The root moved, `ci75cnxg` to `zj581hwl`, and the set
      went 7438 to 9717 with the root excluded: 2310 added and 31 removed. Both
      numbers are explained and neither is a surprise.

      The 2310 are almost entirely one cause, which the drvPath alone could not
      have told apart from a runaway. Task 3.2 pins hunk to its own nixpkgs
      rather than making it follow ours, because its build enumerates
      `perSystem.x86_64-darwin`, which nixpkgs-unstable dropped. A second
      nixpkgs instantiation carries a second toolchain, and that is what the set
      shows: duplicate `bootstrap-stage2-stdenv-darwin`, `apple-sdk-14.4`,
      `clang-wrapper-21.1.8`, `perl-5.42.0`, and the autotools and python build
      hooks, 114 `source.drv` among them. Eleven nodes name hunk directly. The
      cost is the price of 3.2's decision, recorded here rather than rediscovered
      in phase 9.

      The 31 removed are this phase's own deletions and renames, and each is
      accounted for: `diffnote.drv` and the two `skill-*-diffnote-SKILL.md.drv`
      leave, the four `guard.drv` and the harness config nodes move because
      `sysinit-agent` itself changed, and `review.drv` plus the two
      `skill-*-note-SKILL.md.drv` arrive to replace them.

      `arrakis` is NOT re-recorded here and its two files are unchanged, which
      this task already anticipated by assigning that half to CI.
      `hack/host-baseline.sh arrakis` cannot run on this box: it hits an
      import-from-derivation that needs an `x86_64-linux` builder, and fails with
      `required system or feature not available`. CI owns it. `deps:` 3.8
- [x] 3.15 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on the claim that no behavior was lost silently, on the
      derived export as an artifact that can go stale against its record, and
      on the loopback daemon as an unauthenticated local listener.

      Terminal state: `not run`. `specutil check` passes. No critic ran, per the
      owner directive. The review decision was re-stamped after the phase-3
      edits restaled it.

      Two of the three open questions moved during the apply, which is worth
      recording since no critic will now press them.

      On behavior lost silently: two losses were found by running things rather
      than by reading them, and both were real. `hunk` hides agent notes by
      default (`agent_notes = false`), so `review` loaded the sidecar, paid the
      read, and displayed nothing; `--agent-notes` is now passed explicitly. And
      deleting the `diffnote` shim in 3.8 left `sysinit-agent` on no PATH at
      all, so every command the new skill and the allowlist tell an agent to
      type did not exist. `pkgs.sysinit-agent` is now in `home.packages` under
      its own name. Neither was caught by any gate in this phase, which is the
      honest answer to the question as asked.

      On the export going stale against its record: unchanged and still true by
      design. `rebuild` is the repair, the marker is advisory, and nothing
      compares the two. 3.10 added a neighbouring staleness the design had not
      named: a running viewer is stale against the export as well, with no
      remedy but restarting it.

      The loopback daemon question is untouched. `hunk` runs one, this change
      did not audit it, and phase 3 did not need to. `deps:` 3.14

## 4. One owner per fact

- **SHAPE** graph

- [ ] 4.1 Act: add `modules/shared/options/paths.nix` owning every state path.
      Generate a JSON manifest from it that Go, shell, lua, python, and YAML
      read, so the five derivations become one. All five: an earlier draft named
      four and silently dropped `seshy/config.yaml:5`, which the proposal counts
      among the derivations. YAML cannot read a manifest at runtime, so generate
      that file from the manifest at build time instead. The manifest must
      supply an absolute path rather than a variable to expand, and it is
      produced from one checked-in layout template whose only substitution is
      `$HOME`. One producer matters at the phase boundary: 9.7 has to write this
      manifest on a box with no Nix, so without a template it would author the
      same paths a second time in shell, which makes the five derivations two
      rather than one and reintroduces the defect this phase removes. It would
      also fail 4.3's check, because the template is a second producer of paths
      and carries no consumer's documented default. 4.3 exempts it alongside
      `paths.nix`, and those two entries are its whole producer set. An earlier
      draft described that check as a two-file allowlist over every occurrence,
      which 4.3 replaced: the allowlist now covers unmarked occurrences only.
      Have 9.7 expand the template rather than author paths, and let 9.8 compare
      the expanded file against it. The absolute path
      is required because
      `repo.go:63-64` records that nvim launched from a mux server inherits no
      session variables, so `XDG_STATE_HOME` is unset exactly where the fallback
      runs. That comment is about nvim; treat it as the demonstrated case rather
      than as proof for every consumer, and confirm the same for the shell and
      python readers while implementing. Allow each consumer exactly one default marked with the bare token
      `sysinit:documented-default` in a comment on the same line or the line above,
      keyed to
      the manifest being absent, and no other. An earlier draft banned defaults
      outright and cited that same comment, which does not support the ban and
      contradicts this change's own criterion that the agent runtime installs
      without Nix: phase 9 builds a box with `go install` and no Nix, so no
      manifest exists there and a consumer with no default cannot resolve a path
      at all. Task 9.7 owns installing it on that box; this task owns making the
      default reachable only when it is missing. Call this one the paths manifest
      everywhere, and leave "manifest" unqualified for `bootstrap/tools.toml`,
      which phase 9 already uses the word for. One word, one meaning is this
      change's own rule, and an earlier draft had the word naming two artifacts
      across a phase boundary.
      `deps:` 2.9
- [ ] 4.2 Verify: the `XDG_STATE_HOME` divergence at `ui.lua:296`, `:312`,
      `:564`, and `:1735` is fixed, decided by launching wezterm itself with
      `XDG_STATE_HOME` set to a non-default value and seeing the status bar read
      the record `agent-state` wrote there. Exporting the variable in a shell
      proves nothing: `modules/home/default.nix:34` sets it as a home-manager
      session variable, which reaches shells and not GUI processes, and
      `repo.go:62-65` records that a process launched from a mux server inherits
      no session variables at all. The pair that actually diverges is
      `agentstate.go:65`, which honours the variable, against `ui.lua:296`,
      which does not. An earlier draft cited `ui.lua:187` as the other half; that
      line writes a different file in the same process and cannot diverge from
      `:296`. `deps:` 4.1
- [ ] 4.3 Verify: the behavior this phase promises is that one place owns each
      state path, decided by a check that fails when `.local/state` appears
      outside the paths module. 4.2 covers `ui.lua` alone, and the promise has no
      other gate, which leaves the phase's own stated failure mode undetectable.
      Add the check as a pre-commit assertion over the whole tree, counting
      occurrences per file rather than banning the string outside two files. One
      occurrence carrying the `sysinit:documented-default` token 4.1 defines
      passes; a second in the same file, or any unmarked occurrence, fails. An
      earlier draft said "the documented-default marker" and no task made one, so
      the check could not be built as specified. The token is bare rather than a
      comment form because 4.1 spans five languages whose comment syntax differs,
      `//` in Go, `#` in shell, python, and YAML, `--` in lua. The token survives
      into generated scripts, and the one placement that loses it is worth
      stating. `modules/lib/shell.nix:3-12` is `stripHeaders`: `:9` builds
      `isHeaderLine` from the two prefixes, then `:10` filters with the negation,
      so it removes the shebang line and the `shellcheck disable` line and keeps
      every other line, ordinary comments included. An earlier draft
      read `:9` alone and said the function keeps those two, which inverts what it
      does and sends an implementer looking for a stripping hazard that is not
      there. The real residual is narrow: a token written on a line that begins
      with `# shellcheck disable` goes with that whole line. Put the token on its
      own line or at the end of the code line, never appended to a shellcheck
      directive.
      A two-file allowlist cannot work, and an earlier draft used one. Task 4.1
      requires each consumer to keep "exactly one documented default, keyed to the
      manifest being absent", because phase 9 builds a box with `go install` and no
      Nix where a consumer with no default cannot resolve a path at all, and 9.7
      depends on that clause. So the check would fire on all twenty-four consumers
      this task lists, every one of them correct. 4.1 is load-bearing and cannot be
      the side that moves. The allowlist survives for unmarked occurrences only,
      and its two entries are `modules/shared/options/paths.nix` and the layout
      template 4.1 defines, which 9.7 expands on a box with no Nix. Those two are
      the
      producer; everything else is a consumer. Derive the site list from
      the tree rather than from a hand-written set: an earlier draft named eight
      and the real count is over twenty. A literal grep for `.local/state`
      outside tests and outside the `ui.lua` sites 4.2 owns returns
      `modules/home/default.nix:24`, `seshy/config.yaml:5`,
      `skills/wtrun/wtrun.sh:13`, `config/render-skills.sh:6`,
      `worklog-hook.py:253` and `:327`, `runtime/agent-identity.sh:18`,
      `agent-review-suffix.sh:7`, `sy-gate.sh:43`, `agent-busy-panes.sh:6`,
      `agent-notify.sh:73` and `:83`, `agent-sessions.sh:1`, `agent-refine.sh:1`
      and `:2`, `worklog-query.sh:4`, and `bin/nvim-ctl:30`, which 2.6 deletes.
      `worklog-query.sh:4` is executable code and belongs in the site list even
      though `:17` in the same file is prose. The Go sites do not
      match that literal at all, because they build the path with
      `filepath.Join(os.Getenv("HOME"), ".local", "state")`:
      `agentstate.go:51` and `:292`, `repo.go:71`, and `statusline.go:104`. The
      check must catch both forms or it misses every Go consumer, which is the
      half the proposal's divergence claim rests on.
      Give the check a scope that excludes prose, or it fires on documentation
      describing a default: `skills/worklog/SKILL.md:25` and `:129`,
      `skills/feature-based-session-manager/SKILL.md:20` and `:74`, the usage
      text at `worklog-query.sh:17`, and the comment at `repo.go:61`. A consumer that keeps its hardcoded fallback
      is otherwise invisible, and 4.9 asking a critic to argue about it is not a
      gate. `deps:` 4.1
- [ ] 4.4 Act: enumerate the hand-kept lists first, and write the enumeration
      into the change as a file with one `path:line` per list. The proposal's
      count of fourteen is an estimate, so the enumeration replaces it and the
      enumeration is what the next task tests. A list qualifies when adding a
      harness requires editing it; a site that branches on one harness name does
      not qualify. Start from what
      `rg -n '"(claude|codex|opencode|crush|goose|gemini|cursor|devin|amp)"'`
      reports over `modules/`, and record for each site which of the two it is.
      Do not carry a count into this task: an earlier draft said 24 sites in nine
      files and the command returns 127 matches across 31 files, which is the
      point of enumerating rather than counting.
      Then add one harness registry replacing the qualifying lists, and delete
      the seven `throw` assertions that existed to police them
      (`llm/default.nix:190` and `:192`, `runtime/default.nix:64`, `:73`, `:75`,
      `lib/instructions.nix:145`, `harnesses/pi/default.nix:75`).
      `deps:` 4.1
- [ ] 4.5 Verify: every list in 4.4's enumeration now reads from the registry,
      checked site by site against that file rather than against a count. Then
      test the property the lists existed to hold: add a throwaway harness to the
      registry alone, build, and confirm it appears in every surface the
      enumeration named, with no other file edited. Also confirm the registry and
      `neovim/config/lua/harness/registry.lua` agree, which they do not today.
      `deps:` 4.4
- [ ] 4.6 Act: give the pane record a written schema and a version field. Its
      own comment at `agentstate.go:33-34` already calls it "a published
      interface", and it has neither. Three readers exist today and phase 5 adds
      more, each reproducing rules nothing states: `pane` is a JSON number when
      numeric and a string otherwise (`agentstate.go:247-252`), and `|` is
      stripped from the reason for a field separator that only the OSC form
      uses. Publish the schema next to the writer, keep the `|` rule since 2.2
      keeps the OSC channel, and make the readers cite it. Do not describe
      `ui.lua` as a user-var reader only. It is both: `pane_agent_state` at
      `:333-339` reads `p:get_user_vars()`, and `read_pane_git` at `:294-296`
      opens the record file, so the authority table must give it two rows or it
      describes half the file. 10.7 depends on that second half being there. A fact with several
      readers and no owner is the same defect this phase exists to fix.
      Two encodings now carry one fact: base64 of a pipe-delimited line at
      `agentstate.go:86-89` and JSON at `:95-107`, with `ui.lua:333-339`
      preferring the first and `agent-sessions.sh:63-70` reading only the
      second. Derive both from one value in one place and add a test that they
      agree, or two surfaces can show different statuses for one pane with
      nothing comparing them. The two also differ in lifetime, which the schema
      must state: the user var dies with its pane and needs no liveness rule,
      the file outlives it and needs 4.7, and they disagree precisely inside the
      window 4.7 covers. Say which is authoritative for which reader, since
      `ui.lua:333-339` prefers the var and `agent-sessions.sh:63-70` reads only
      the file. `deps:` 4.1
- [ ] 4.7 Act: give the pane record a liveness rule at read time, and do not
      make it a time bound. The archived change chose user vars partly because a
      file "reintroduces exactly the stale-entry pruning problem"
      (`archive/2026-07-08-surface-agent-session-state/design.md:49-59`), and
      claude and pi wire `agent-state ... exit` and codex and opencode do not,
      so a crashed or exited codex reads `working` forever. But an age bound reaps the wrong records first.
      `since` is republished on every tool call, so it is a heartbeat only while
      tool calls happen, and `waiting` and `done` are turn-terminal: nothing
      rewrites them until the owner acts. A bound would expire the two states
      the deck exists to show while a long `working` build kept refreshing.
      Do not record the writer's pid either. `agent-state` is a one-shot:
      `agentstate.go:104-108` publishes and returns, so its pid is dead
      microseconds later and every record would read absent. That fails closed
      on the common path, which is worse than the stale record it replaces. The
      parent pid is no better, being a transient shell for claude and codex and
      the long-lived runtime for opencode and pi, so the field would mean two
      things.

      Use pane existence. Both readers already answer it: `ui.lua` walks panes
      in process at `:355-361`, and `agent-sessions.sh:37-40` already forks
      `wezterm cli list` once per invocation to prune. State the two limits
      rather than inventing a mechanism for them. A reader outside wezterm
      cannot answer it, and there is no such reader today. A reused pane id
      inherits the previous occupant's record, which pane existence cannot
      detect, so carry a per-pane generation marker if the mux exposes one and
      record the hole if it does not.

      Both holes are larger than an earlier draft implied, so state them at their
      real size. The reused pane id is reached by restarting the terminal, not by
      an edge case: the state directory is under `XDG_STATE_HOME`
      (`agentstate.go:65`) and outlives the mux, nothing clears it at mux start,
      and codex and opencode never clear on exit. Run codex, quit wezterm, reopen,
      and a fresh mux reassigns the low pane ids, so the new pane inherits
      yesterday's `working` record and pane existence returns true because the
      pane does exist. Confirm the id recurrence by observation rather than by
      argument: restart wezterm and read the first pane's `WEZTERM_PANE`. If the
      mux exposes no generation marker, clear the state directory at mux start,
      which is the smaller fix and closes the routine trigger.
      The reader-outside-wezterm hole is vacuous today and stops being vacuous one
      phase later. It is vacuous because `agentstate.go:60-63` returns early
      without `WEZTERM_PANE`, so no record exists outside wezterm. Task 5.1 then
      adds `sysinit-agent watch`, a Go reader of the same bus, and answering pane
      existence from Go means forking `wezterm cli list`, which is the fork 2.9
      just removed. Carry that constraint into 5.1 rather than leaving it to be
      rediscovered there. `deps:` 4.6
- [ ] 4.8 Act: delete the dead `utils` specialArg from all thirteen sites, nine
      threaded and four forwarding into `extraSpecialArgs`, plus `mkUtils` in
      `templates/discrete/flake.nix:53`, which is a published flake output, and the
      unused `sysinit = ../..` arg. `deps:` 4.1
- [ ] 4.9 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on the generated manifest, where a consumer silently
      falling back to a hardcoded path defeats the whole phase, and on whether
      4.7's liveness bound can be stated without a clock the readers disagree
      about. `deps:` 4.8

## 5. One viewer, one contract

- **SHAPE** graph

- [ ] 5.1 Act: add `sysinit-agent watch`, which renders a wtrun log, the
      agent-state bus, or a transcript, and tails it. It reads its paths from the
      phase 4 manifest. Name the resolution key per source rather than saying it
      resolves from the current directory, which an earlier draft did and which
      works for one source of three. The agent-state bus does key by directory,
      since the record carries `Repo` and `Worktree` (`agentstate.go:36-39`).
      wtrun keys by pane: `skills/wtrun/wtrun.sh:12-13` sets
      `session="${WTRUN_SESSION:-pane-${WEZTERM_PANE}}"` and nothing under that
      directory records a repository, so a viewer spawned into a new pane by 5.2
      resolves its own empty directory. The transcript keys by harness session
      id, per 5.3's `<harness>/<session>.jsonl`. Take the wtrun name from
      `WTRUN_SESSION` or an explicit argument, and have 5.3 record the repository
      next to the session so the transcript is reachable by directory; 5.3
      carries that clause in its own body, since an implementer working 5.3 does
      not read 5.1. The phase is called one viewer, one contract, and the
      contract is what this task writes down.
      Reading the agent-state bus makes this the first Go reader of it, which
      lands the hole 4.7 records as vacuous today: answering pane existence from
      Go means forking `wezterm cli list`, and 2.9 removed exactly that fork.
      Do not reintroduce it. Show the record's own state and mark it unverified
      when this command cannot answer liveness, rather than guessing.
      `deps:` 3.4, 4.1
- [ ] 5.2 Act: add a wezterm chord that spawns the viewer in a new pane the
      owner asked for. `deps:` 5.1
- [ ] 5.3 Act: mirror the native transcript into
      `agents/transcripts/<harness>/<session>.jsonl` for claude only. Claude is
      the one harness whose hook payload carries `transcript_path`. An earlier
      draft named four, which the evidence does not support: opencode's payload
      is typed `{ type, properties: { sessionID, status } }`
      (`plugins/sysinit-notify.ts:28-35`), pi's handlers carry `toolName` and
      `input` and no transcript reference
      (`extensions/sysinit-notify.ts:31-53`), and codex's three hooks are fixed
      argv that read no stdin (`harnesses/codex.nix:151-186`). Codex, pi, and
      opencode join the uncovered set, making it ten of eleven. If that is worth
      changing, the fix is a probe in the shape of 3.1: run codex with a hook
      that dumps its stdin and record what is actually there. Do not assert it.
      Record the repository next to the session, so 5.1's viewer can resolve a
      transcript from the current directory. Without it the transcript is
      reachable only by harness session id, which the owner does not know.
      `deps:` 5.1
- [ ] 5.4 Verify: the ten uncovered harnesses are recorded in the
      proposal as uncovered, with no scraping added. `deps:` 5.3
- [ ] 5.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on whether a viewer that polls files reproduces the
      coupling it replaced. `deps:` 5.4

## 6. The profile layer

- **SHAPE** graph

- [ ] 6.1 Act: add `modules/shared/options/profiles.nix` defining
      `sysinit.profiles.<minimal|dev|workstation>.enable`, each implying the one
      below. `deps:` 4.6
- [ ] 6.2 Act: split `packages.nix` into named groups behind the profiles,
      keeping every current package. `deps:` 6.1
- [ ] 6.3 Act: gate the 34 imports in `programs/default.nix` on the profile.
      The selector must NOT be the option 6.1 declares. `imports` is resolved
      before `config` exists, so reading `config.sysinit.profiles.*.enable` from
      an `imports` list is infinite recursion, and `lib.mkIf` inside each module
      still evaluates it and defeats the point. Pass the profile through
      `specialArgs` and `home-manager.extraSpecialArgs` instead, and let 6.1's
      option read from it so a host still sets one value in one place.
      `deps:` 6.1
- [ ] 6.4 Act: set every host in `hosts/` to `workstation`. `deps:` 6.2, 6.3
- [ ] 6.5 Verify: the two drvPaths are unchanged against the baseline as
      re-recorded at the end of phase 3, not against 1.1. Phases 2 and 3 moved
      it on purpose. This phase must not move it at all: it only reorganizes
      which module is selected, so any difference is a module silently dropped
      from a profile. This task covers phases 4, 5, and 6, since 3.14 is the last
      recording before it, and 9.9 leans on that span. The diagnosis above names a
      phase-6 cause because that is the likely one, not the only one: if phase 4 or
      5 moved the closure, this is where it surfaces. The `lv426` half runs
      locally and the `arrakis` half runs in the CI job 1.1 adds. `deps:` 6.4
- [ ] 6.6 Verify: `nix path-info -S` on `minimal` is smaller than on
      `workstation`, and the `minimal` and `workstation` drvPaths differ from
      each other. Both clauses are the STOP gate, not 6.5 alone. `drvPath` is
      input-addressed, so a gate that only checks `workstation` equality passes
      when the profile layer was never wired: an `optionals` expression that
      yields the same list for every profile is identical to no profile layer,
      and 6.5 cannot tell them apart. This is the one gate that keeps
      `nix path-info -S`, because a size is the point here rather than a set of
      names, and it is also the one gate that needs realized paths. Run both
      profiles for `lv426` locally, where the closures already exist.

      Both sizes are measured at the same instant, and there is deliberately no
      third clause comparing `minimal` against a size recorded back in phase 1.
      Phase 1 tried that and the artifact was dropped, because a cross-time
      absolute size cannot carry the claim. `update-sources.yml` runs
      `nix flake update` every six hours, so nixpkgs moves under the measurement
      between phase 1 and phase 6, and phases 2 through 5 move it again. A red
      cross-time clause would be ambiguous between "the split did not shrink
      anything" and "nixpkgs grew", which is the ambiguity task 1.2 exists to
      keep out of these gates. The same-instant comparison has no such
      confound: one nixpkgs, one evaluation, two profiles.

      Measuring the home closure specifically does not rescue it either. The
      home-manager activation package for `lv426` measures 17.0 GiB, within
      noise of the whole system closure at 17.5 GiB, so it is dominated by
      derivations no profile split touches. The home `profile` output is the
      discriminating 790 MiB of it, and that is what both sides of this
      comparison should measure. `deps:` 6.5
- [ ] 6.7 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on the gating, where a mis-scoped `optionals` silently
      drops a module from every profile. `deps:` 6.6

## 7. Decouple theming

- **SHAPE** graph

- [ ] 7.1 Gather: list the 20 modules referencing `stylix` and note what
      each sets. `deps:` 6.5
- [ ] 7.2 Act: add `sysinit.theme.enable`, default true, guarding each.
      `deps:` 7.1
- [ ] 7.3 Verify: with the flag true, every theme file the guarded modules
      generate is byte-identical to today, with the file list derived from 7.1's
      enumeration rather than named here. Simplest sufficient form: compare the
      whole derivation-path set with the flag true against the 3.14 recording,
      which is the value in force at the end of phase 6, since 6.5 asserts
      equality against it and phase 6 makes no recording of its own. The `lv426`
      half runs locally and the `arrakis` half runs in the CI job 1.1 adds, which
      is what reaches the two `nixos/` modules below. An earlier draft said "the phase 6
      recording", which names nothing. It covers
      all twenty at once in 6.5's shape.
      An earlier draft named wezterm and neovim and stopped, gating two of the
      twenty modules 7.2 guards. The proposal's Behavior criterion is unscoped and
      says theme files, and several unguarded-by-this-gate modules generate them:
      `sketchybar/default.nix`, `omp.nix`, `fastfetch.nix`, `fzf.nix`,
      `firefox.nix`, `zoxide.nix:34-38`, `llm/harnesses/pi/default.nix:104-106`
      with `:518`, `nixos/desktop/greetd.nix`, and `nixos/home/desktop.nix`. That
      list is illustrative and the gate does not depend on it, which is why it is
      worth stating what an earlier draft got wrong in both directions:
      `helix.nix:4` and `vivid.nix:4` were listed and generate nothing, each being
      a single line toggling a stylix target and consuming no colors, while
      `zoxide.nix` and the pi harness both read `config.lib.stylix.colors` and were
      missing. `borders.nix` and `zsh/default.nix` produce service arguments and
      environment variables rather than files, so they are excluded here. A guard at the
      wrong nesting level in any of them changes the true branch, which is what the
      owner looks at daily, and the old gate passed. Handing the residue to 7.5 is
      not a substitute: 4.3 already states this repository's position, that a
      critic asking about it is not a gate. `deps:` 7.2
- [ ] 7.4 Verify: with the flag false the home modules evaluate without the
      stylix module present. `deps:` 7.2
- [ ] 7.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on guards placed at the wrong nesting level, which would
      change the true branch too. `deps:` 7.4

## 8. Standalone home configurations

- **SHAPE** graph

- [ ] 8.1 Act: add a `mkHome` builder supplying the specialArgs the home tree
      expects without going through nix-darwin. Name them, because a missing one
      fails only in the modules that read it, which is the failure 8.5 describes
      and cannot catch. `modules/darwin/home-manager.nix:13-15` and
      `modules/nixos/home-manager.nix:14-16` both pass
      `inherit utils values inputs`. Supply `values` and `inputs` and drop
      `utils`: no `.nix` file dereferences it, confirmed by a `utils.` search over
      `modules`, `lib`, `hosts`, and `flake.nix` returning nothing, and the
      proposal already counts its removal.
      `values` is the hard one, because it is read by path. Derive the list from
      the tree by command rather than writing it by hand, in 4.4's shape, and
      scope the search to `.nix`. It is fourteen paths today, from `values.darwin`
      through `values.user.username`. Unscoped it returns sixteen, because
      `neovim/config/after/lsp/helm_ls.lua:14-15` holds `values.yaml` and
      `values.lint.yaml`, which are Helm filenames in a lua string and not this
      specialArg.
      Five of the fourteen are not leaves and the schema has to say so, or it
      describes the wrong shape. `values.git`, `values.llm`, and `values.theme`
      (`darwin/home-manager.nix:34,35,38`), `values.darwin` (`home/colima.nix:9`),
      and `values.environment` (`home/default.nix:48`) are open attrsets that the
      consumer either indexes further or forwards whole. Treating them as leaves
      pins a shape their consumers do not agree to.
      Then say which paths `mkHome` defaults and which it takes as arguments.
      `values.hostname` and `values.user.username` have no standalone answer.
      Read that from `lib/builders.nix:40-44`, not from `hosts/default.nix`. The
      builder injects `hostname`, `user.username`, and `isDesktop` on top of the
      host's own `values`, taking `hostname` from the attribute name and
      `username` and `desktop` from host fields that sit beside `values` rather
      than inside it. `hosts/default.nix` supplies exactly two top-level keys
      under `values`, `git` for both hosts and `theme` for `arrakis` alone. Say
      top-level keys and not paths, because this task counts fourteen deep paths
      elsewhere and the same word in both senses reads as a contradiction; the
      same two keys are six leaves counted deeply. That is also
      why the three have no standalone answer: `mkHome` has no `hostConfig` and no
      attribute name to inherit from. `deps:` 7.4
- [ ] 8.2 Act: emit `homeModules` and `homeConfigurations.<profile>-<system>`
      for `dev` and `minimal` across the three `cacheSystems`
      (`flake.nix:109-113`): `aarch64-darwin`, `x86_64-linux`, `aarch64-linux`.
      Six configurations, not eight. An earlier draft said "the four systems",
      which is the `formatter` list at `flake.nix:229-233` and adds
      `x86_64-darwin`. That would make these the only outputs on a system nothing
      else here builds for. `deps:` 8.1
- [ ] 8.3 Verify: build all six configurations 8.2 emits, not one, each at
      `.#homeConfigurations.<profile>-<system>.activationPackage`, which is the
      buildable attribute and the one the proposal names as deciding its Behavior
      criterion. A missing
      `values` leaf fails per module, and which modules are imported depends on the
      profile and the system, so a leaf read only by a `dev` module is invisible to
      a `minimal` build and a leaf read only by a Darwin module is invisible to a
      Linux build. Profile crossed with system is where the 8.5 failure hides, and
      an earlier draft sampled one cell of six. It is a loop over an attribute list
      and no new mechanism; the three `aarch64-darwin` cells build natively and the
      three Linux cells build on the CI runners per 1.1. `deps:` 8.2
- [ ] 8.4 Confirm: owner runs `home-manager switch --flake .#dev-x86_64-linux` on a Linux box
      or container and reports whether the shell and editor come up. `deps:` 8.3
- [ ] 8.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on 8.1's split between the paths `mkHome` defaults and
      the paths it takes as arguments. Point them there and not at a missing
      specialArg, which 8.3 now catches mechanically across all six cells. The six
      builds exercise the defaults only, so a wrong default fails the build and a
      wrong argument does not. What is left is a judgment: which facts a
      standalone home configuration may invent about a machine it has never seen.
      `deps:` 8.4

## 9. The non-Nix path

- **SHAPE** loop
- **STOP** `bash bootstrap/verify-container.sh` exits 0, which runs the
  bootstrap in a clean Ubuntu container and then asserts `nvim --headless +qa`
  and `sysinit-agent --help` both exit 0 inside it. Task 9.2 writes that script.
  An earlier draft named it in the gate and in no act, so the phase was judged
  by a file it never created
- **MAX-ITERS** 4
- TERMINAL: CAPPED at 4 iterations, or STALLED after 2 iterations with the same
  tool failing to install. On either, stop and report which tool has no
  non-Nix installation path, and drop it from the ephemeral set.

- [ ] 9.1 Act: add `bootstrap/tools.toml` as the `minimal` profile's own
      manifest, naming each tool once with its nixpkgs attribute and its mise
      identifier. Decided in design.md section 6: the ephemeral-box set and the
      `minimal` profile are the same list, so there is no second list to drift
      from. `deps:` 6.2
- [ ] 9.2 Act: write `bootstrap/verify-container.sh`, the script this phase's
      STOP gate runs. Write it before the bootstrap it verifies, so the gate is
      not authored by the thing it judges. `deps:` 9.1
- [ ] 9.3 Act: make `bootstrap.sh` use a sparse checkout rather than a full
      clone, which is what design.md section 7 chose over splitting the neovim
      config into its own repository. `deps:` 9.2
- [ ] 9.4 Act: make the Nix `minimal` package group read the manifest, so the
      manifest is the source. Preserve the current element order in the derived
      list. `home.packages` reaches `buildEnv`, whose `drvPath` changes when
      identical paths are reordered, so a re-ordering rewrite churns every host
      hash for no content change. 9.9 depends on this rather than being immune to
      it, which an earlier draft had backwards: the derivation-path set carries
      each `buildEnv`'s own derivation as an interior entry, and that entry's
      hash is computed from the order of its `paths`. So a reordering rewrite
      fails 9.9 on a correct implementation. Preserve element order.
      `deps:` 9.1, 6.2
- [ ] 9.5 Act: generate `bootstrap/mise.toml` from the same manifest, with a
      pre-commit assertion that the checked-in file matches. `deps:` 9.1
- [ ] 9.6 Act: add `bootstrap/bootstrap.sh` that sparse-checks-out, symlinks the
      neovim and zsh configs, runs `mise install`, and
      `go install ./pkgs/sysinit-agent`. `deps:` 9.3, 9.5
- [ ] 9.7 Act: write the paths manifest during bootstrap by expanding `$HOME`
      into 4.1's layout template, so a box with no Nix resolves state paths from
      the same source every other consumer reads. Do not author the paths here:
      a second producer in a second language is the defect phase 4 removes, and
      4.3's check would fail on this script. Task 4.1 allows each consumer one
      documented default keyed to the manifest being absent and hands the
      installing to this task; without it that default is the permanent path on
      every non-Nix box and 4.3's check has nothing to prove. This is the paths
      manifest, not `bootstrap/tools.toml`, which the rest of this phase calls the
      manifest. `deps:` 9.6
- [ ] 9.8 Verify: the container run in the STOP gate passes; the manifest 9.7
      wrote matches 4.1's template with `$HOME` expanded, so the two producers are
      one; and `sysinit-agent note add` inside the container resolves its path
      from that manifest rather than from a default. `deps:` 9.7
- [ ] 9.9 Verify: the derivation-path set matches the 3.14 recording exactly,
      for both hosts, with an empty diff each way. Do NOT compare drvPath hashes
      here, which an earlier draft did. `drvPath` is order-sensitive: building `buildEnv` with
      `[hello jq]` and with `[jq hello]` yields different hashes, confirmed by
      running it. Task 9.4 replaces a literal package list with one derived from
      `bootstrap/tools.toml`, so unless the derived order matches the literal one
      element for element, every host hash moves while installing exactly the same
      packages, and the gate fails first on a correct implementation. Task 8.1
      carries a smaller version of the same risk depending on whether `mkHome`
      shares the darwin specialArg plumbing or sits beside it, which 8.1 does not
      say. The set is not blind to a reordering, so 9.4 must preserve element
      order and says so; what the set adds over a hash is that it names which
      derivations moved, so a reorder reads as `-env.drv` entries changing while
      a dropped package reads as an entry disappearing. 2.12, 3.14, and 10.12
      already use it.
      The `lv426` half runs locally and the `arrakis` half runs in the CI job 1.1
      adds.
      This closes a three-phase hole. The temporal comparison tasks are 6.5, which
      checks against 3.14, and 11.1, which checks against phase 10's re-record.
      "Temporal" because 6.6 also compares drvPaths, `minimal` against
      `workstation`, which is cross-profile rather than against a recording. Between them, phases 7, 8, and 9 have none. An earlier draft
      argued this by quoting what `grep -n 'drvPath' tasks.md` returns, which was
      wrong when written and rots on every edit: it names nine tasks, not six,
      including 6.6, 9.4, and this task itself. Name the comparison tasks instead,
      since a re-record is not a check.
      The phase that matters is 9. Task 9.4 makes the `minimal` package group read
      the manifest, and every host installs it because `workstation` contains
      `minimal`, so a package dropped there is a silent loss on both hosts.
      Without this task that loss is re-recorded as the new baseline by 10.12 and
      then confirmed correct by 11.1, which is the failure 1.1 exists to prevent.
      Phases 7 and 8 are covered because covering them is free, not because they
      are equally exposed. 7.2 adds `sysinit.theme.enable` defaulting to true, and
      8.1 and 8.2 add a builder attribute and new flake outputs that hosts do not
      evaluate through, because nix attrsets are lazy and an unforced `mkHome`
      never enters a host closure. An earlier draft of this task said in one
      sentence that hosts evaluate through `mkHome` and in another that they do
      not; the second is correct. If any of the three phases moves the closure
      contents, that is the finding, not a reason to waive.
      `deps:` 9.8
- [ ] 9.10 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on the generator, where silent drift between the two
      lists is the failure this phase exists to prevent. `deps:` 9.9

## 10. The session substrate

zmx is a session manager with one job: a named shell session that survives a
detach. It has no windows, panes, or splits on purpose, because that is the
window manager's job. That is the same line this change draws everywhere else,
so it belongs here rather than in a change of its own.

It enters under zsh, and seshy and wezterm integrate with it. It does NOT
replace `wtrun`, whose worker pane is an owner-visible surface, and it does not
become phase 5's viewer source. Widening it to those is a separate decision.

The STOP below is a `checks/` entry, so `nix flake check` builds the current
system's checks and only evaluates the rest. It passes on the owner's machine and
covers `aarch64-darwin` alone. That is a scope statement, not a defect; phase 3's
STOP has the same shape.

The gate below is a graph-phase STOP, which is a third convention in this file
and needs its failure behavior stated. Phase 3 and phase 9 are loops and pair
their STOP with a MAX-ITERS and a TERMINAL, which is what tells an implementer
what to do when the gate fails. Phase 2 has no header STOP and keeps its gate as
prose inside task 2.9. A graph does not iterate, so this STOP has no retry
semantics: it is a precondition on closing the phase, and a failure means fixing
the named task and re-running the gate, not re-entering the phase.

- **SHAPE** graph
- **STOP** the 10.9 check passes and lives in `checks/` rather than in this
  file. Prose in a task list runs once by hand and never again, so a later edit to
  `agent-identity.sh` would silently remove the gate 10.6 installs. Task 3.13
  already settled where such a check belongs: it was moved out of
  `.githooks/pre-commit` because that hook's idiom is skip-when-absent, and a
  guard that silently skips is the failure the task exists to catch. 10.9 fits
  there because it sources a function library and its stub replaces the only
  binary it needs. Note the technique has no precedent here: `checks/` and
  `.githooks/` contain no fake-binary pattern, so 10.9 introduces one and owes it
  a home.
  10.5 is NOT in this gate, and an earlier draft put it here. `checks/` receives
  only `{ lib, system, pkgs }` (`flake.nix:181-187`) and builds in a sandbox, and
  3.13 already recorded that limitation. 10.5 needs a live zmx daemon, real seshy
  worktrees under `$HOME`, and `sy list`, so it cannot run there and the STOP
  could never pass. It is an owner-run confirm instead, in the shape of 2.11 and
  8.4.

- [ ] 10.1 Gather: probe the installed `zmx`, not its README, in the shape of
      3.1. Record the environment variables it sets, and specifically whether a
      child process spawned inside a session inherits `ZMX_SESSION`. Also record
      whether `ZMX_SESSION` carries the `ZMX_SESSION_PREFIX` that 10.4 sets, since
      that string shape decides 10.8: if the variable is prefixed and `sy list`
      names are not, the two sides of `agent-sessions.sh:98` still differ by a
      prefix after both are drawn from the seshy namespace, and 10.5's
      scoped-to-the-prefix comparison needs the same fact. Also record
      whether `mise` can install zmx, which 10.2 needs to choose a package group:
      decision 6 makes `minimal` and the non-Nix manifest the same list, so a
      `minimal` member has to be installable without Nix. The whole
      argument for the dependency is that this key is readable with no fork and
      no terminal, and an earlier draft asserted it from documentation. zmx is
      the only third-party dependency in this change with no probe, which is the
      standard 3.1 sets for the other one. `deps:` 4.1
- [ ] 10.2 Act: add `zmx` to the `dev` package group and a
      `modules/home/programs/zmx/` module owning `ZMX_SESSION_PREFIX` and
      `ZMX_DIR`. Name the group, and give the reason from decision 6 rather than
      from a later task. An earlier draft said to pick `dev` "because 10.3's
      fallback argument depends on it", which chooses a group to keep an argument
      true and is circular: 10.3's fallback holds on its own terms, since any box
      without zmx needs `s` to keep working.
      The real constraint runs the other way. Decision 6 makes `minimal` and the
      non-Nix manifest the same list, so anything in `minimal` must be installable
      by `mise` on a box with no Nix. 10.1 answers that; read its result here. If
      zmx turns out to be `mise`-installable, `minimal` is the better group, and
      10.3's fallback is unaffected either way.
      State the taxonomy cost plainly. Decision 6 defines `dev` as `minimal` plus
      language toolchains and their servers and formatters, and a session manager
      is not one, so `dev` is a poor fit by category. It is not a shell-group fit
      either: `packages.nix:66-70`, which decision 6 calls the shell group, is
      `bash-language-server`, `shellcheck`, `shfmt`, `gum`, and `grc`, which is
      shell tooling rather than session tooling. So put zmx in `dev` and widen
      that group's stated meaning in `design.md` to "toolchains plus session
      tooling". Only the wording is open. An earlier draft also offered adding a
      fourth group, and that option is not reachable from here: 6.1 authors
      `sysinit.profiles.<minimal|dev|workstation>.enable` with each implying the
      one below, so a new group edits that option and its implication chain, and
      phase 6 closed behind two drvPath gates at 6.5 and 6.6 that nothing
      re-runs. Offering a branch that costs a reopened phase invites an
      implementer to take it. Do not leave the taxonomy widened silently, which is
      how a profile stops meaning anything and is the failure 11.4 asks a critic to
      look for. It is
      in nixpkgs at 0.6.0 and evaluates against this repository's pinned
      nixpkgs, so it needs no flake input and no overlay entry. The phase 4
      paths manifest owns the zmx state directory and this module reads it from
      there; the module owns both variables. An earlier draft put both in the
      manifest and gave one reason for it, that `ZMX_DIR` is a state path, which
      is not true of a namespace string. Design decision 4 already draws this
      line: the manifest owns the prefix, the consumer owns the identity under
      it. `deps:` 10.1
- [ ] 10.3 Act: make `s` in `zsh/integrations/seshy-wezterm.zsh:20-34` attach a
      zmx session named for the seshy session, rather than only `cd` into its
      directory at `:33`. Edit `s` alone. An earlier draft named `si` as a second
      site; `si` (`:40-48`) is an fzf picker that resolves a name and calls `s`
      at `:47`, so it inherits the change and editing both would attach twice.
      Keep the `cd` as the path taken when `zmx` is absent, because phase 9
      builds a box that has neither zmx nor Nix and `s` has to keep working
      there. `deps:` 10.2
- [ ] 10.4 Act: make every zmx session that `s` creates carry a seshy session
      name, and use
      `ZMX_SESSION_PREFIX` for the namespace rather than encoding it in each
      name, which is what the variable is for. State the invariant in one
      direction only. An earlier draft asked that `sy list` and `zmx list` "name
      the same things", which cannot be set equality: a seshy session is a
      worktree directory under `~/.local/state/seshy/sessions` and exists with no
      process running, while a zmx session is a live process, so a session
      created and not yet entered is in `sy list` alone. Do not trust
      `seshy/config.yaml`'s comment on where the `sy` gate lives while working
      here: it says the gate is a shell wrapper in
      `zsh/integrations/seshy-wezterm.zsh`, and that file defines `s`, `sl`,
      `si`, `wezcopy`, `weznot`, and `wezmon` and no `sy`. The gate is real but is
      a generated binary wrapper, `runtime/default.nix:255` reading `sy-gate.sh`.
      Correct the comment while here. `deps:` 10.3
- [ ] 10.5 Confirm: owner runs the comparison. Every name `zmx list` reports
      under `ZMX_SESSION_PREFIX` is a
      name `sy list` reports. One direction, per 10.4, and scoped to the prefix.
      This is a Confirm and not a check because it needs a live daemon and real
      worktrees, which a sandboxed `checks/` build has neither of.
      Check the two joins by their output, not just the two lists. With two live
      sessions, `agent-sessions` emits each session exactly once, with no duplicate
      carrying `status: null`. Count entries rather than looking for a repeated
      name: on a split the two entries for one session carry DIFFERENT names, the
      record name in `$active` and the seshy name in `$idle`, so two live sessions
      show four entries. An owner watching for the same name twice finds none and
      passes. And the waybar badge
      excludes the selected session, which is what `desktop.nix:343` fails to do on
      the same divergence. This phase has no automated gate for name agreement,
      since the STOP covers 10.8 alone, so this Confirm is the only thing standing
      between a namespace split and two silently wrong displays.
      Nothing constrains a direct `zmx` invocation, and 10.2 puts `zmx` on `PATH`,
      so an owner naming a session by hand creates one that matches no seshy
      directory. An unscoped comparison would fail on an implementation that is
      correct in every way this change controls. Nothing else in the phase exercises the invariant
      10.4 introduces, and an earlier draft asked 10.4 to "add the comparison"
      with no task running it. Create two sessions with `s` first and assert
      `zmx list` is non-empty before comparing. Subset-of holds trivially when the
      left side is empty, and on a box where no session has been entered that is
      the state the check finds, so without the non-empty assertion this task
      passes without testing anything. `deps:` 10.4, 10.8
- [ ] 10.6 Act: make `ZMX_SESSION` the session key wherever a fork is what it
      replaces. Two files, and they are not symmetric, because phase 2 already
      changed one of them.
      In `agentstate.go`, `identify` resolves the seshy directory and then
      `ZMX_SESSION`, and stops. There is no workspace branch to sit behind:
      2.2 deleted `paneWorkspace`, its call at `:288`, and the fallback at
      `:296-298`, and moved that resolution to the readers. An earlier draft
      described this file as it is today, said "do not delete the workspace
      fallback", and would have had an implementer restore
      `exec.Command("wezterm", "cli", "list", ...)` into `pkgs/sysinit-agent`,
      failing 2.9's fifth clause and reversing the phase 2 removal the proposal
      calls the one that matters.
      In `runtime/agent-identity.sh` all three sources stay, because that file
      has readers with no other way to answer. Order them seshy directory,
      `ZMX_SESSION`, then workspace, and move the `ai_workspace` call at `:16`
      so it runs only when both earlier sources are empty. The line a test has to
      beat is `:4`, `ai_wz=$(command -v wezterm ...)`, which is where the binary is
      resolved. That fork at `:6-7`
      is `"$ai_wz" cli list --format json` at `:6`, piped through `jq` to `:8`,
      the shell twin of the Go fork 2.2
      deletes, and today it runs on every call made from inside wezterm. Not on
      every call without qualification: `ai_workspace` returns at `:3` when the
      pane argument is empty, and both callers pass `${WEZTERM_PANE:-}`
      (`agent-prompt.sh:61`, `agent-notify.sh:22`), so outside wezterm it already
      does nothing. Moving the call is safe for consumers, which is worth
      stating because deferring a variable usually is not: `AI_WORKSPACE` has no
      reader outside this file, only the fallback at `:26-27`. No clause of 2.9 can see it:
      clause one's pattern is `cli send-text|cli activate-pane|cli split-pane`
      and clause five is scoped to `pkgs/sysinit-agent`. Do not widen 2.9 to
      cover it. An earlier draft of this task said to add a clause whose pattern
      includes `cli list`, and that is wrong twice over. `cli list` matches six
      files under `modules/home/programs/llm`, and five of them fork it correctly
      and on purpose: `skills/wtrun/wtrun.sh:21` and its `SKILL.md:47`, which 2.4
      keeps as an owner command, `runtime/agent-sessions.sh:38`, which 2.2's
      repair depends on, `runtime/agent-review.sh:117`, and
      `runtime/agent-focus.sh:26`, which 2.1 keeps. So the pattern is not a signal
      of the defect, and adding it turns clause one from a three-file set into an
      eight-file set, which is dilution rather than coverage. The deeper error is
      the instrument: what 10.6 changes is when the fork runs, and that is control
      flow. No grep can see it, because the gated call and the ungated call have
      identical text. Task 10.9 checks it by behavior instead. `deps:` 10.2
- [ ] 10.7 Act: decide what the workspace rollup and its renderers display, not
      what key the rollup groups by. Say "rollup" and not "agent deck": `agent-deck`
      is a third-party wezterm plugin loaded at `ui.lua:84` through
      `plugin_loader.load`, patched here by
      `wezterm/patches/agent-deck-idle-detection.patch`, and its API is
      `get_all_agent_states` (`:153`, `:203`, `:353`, `:724`). The code this task
      edits is the sysinit-owned rollup at `:350-405`, which consumes the plugin's
      output at `:353`. An earlier draft said "agent deck", which points an
      implementer at vendored upstream code the repo rule forbids editing.
      The record keeps one name field, `session`, which is the one fact its writer
      owns. The workspace stays a reader-side fact each surface resolves for
      itself.
      An earlier draft added a second `workspace` field to the record so each
      surface could read the one it wanted. That field has no writer.
      `agentstate.go` is the sole producer, with the record directory at `:65`,
      and 2.2 deletes `paneWorkspace` at `:321-346`, its call at `:288`, and the
      fallback at `:296-298`, which were the only way it could learn a workspace.
      `design.md:69` already says why nothing cheaper exists: no environment
      variable carries the workspace. So the writer would emit an empty field on
      every record, and filling it means restoring the fork, which fails 2.9's
      fifth clause. The readers already have their own answer: `ui.lua` takes it
      from the mux at `:357`, and `agent-sessions.sh` runs `wezterm cli list` at
      `:38` anyway.
      What to change. the rollup at `:350-405` groups by `win:get_workspace()` at `:378`
      and `:389` and never reads the record's `session`. An earlier draft cited
      `:377` and `:388`, which are a closing brace and an `if`. Keep the grouping
      and make the group display the session names of the panes in it, so a deck
      group named for a workspace still shows which zmx sessions are inside it.
      This does not require the `ui.lua` restructuring the non-goals forbid, and
      the reason is worth naming so an implementer does not reach for one. The
      function already builds a flat `panes` array at `:365-377` carrying one entry
      per pane with `workspace` on it at `:369`, alongside the collapsed `sessions`
      table, so the grouping structure needs no change.
      The session name is not there yet, and an earlier draft said it nearly was.
      That draft cited `:369` for the `repo` derivation, which is `:370`, and
      called it the same mechanism as reading the record, which it is not:
      `pane_repo` at `:276` resolves from the pane in memory, while
      `read_pane_git` at `:294` opens the record file. This function makes no
      per-pane file read at all today, and says so in a comment at `:371`. So the
      edit is one more field on that constructor plus a per-pane `read_pane_git`
      call plus a render change.
      Why display and not key. Three surfaces read the record's `session` and two
      are not wezterm. The sketchybar widget `agent_sessions.lua:14-16` shells out
      to `agent-sessions` for the macOS menu bar, and `desktop.nix:333-338` wires
      it as a waybar module. A workspace key is defensible for a workspace-scoped
      display, and a global menu bar is not one. Leaving the deck to show only a
      workspace name ships a screen where the tab bar says `default` and the menu
      bar says the zmx session name, for the same agent, at the same moment.
      That is still not the rewrite the non-goals forbid, and there is a working
      shape to copy: `session_tree` at `:723` already does this exact read at
      `:768-769`, the only call site besides the definition, and `rollup_cache` at
      `:407-414` already throttles the rollup that would carry the cost.
      Name all four sites, because the producer is not enough. `panes` reaches one
      consumer of three: `:1288` destructures `local sessions, panes`, while `:848`
      and `:889` take the first return only. The collapsed entry at `:389-394` is
      `{status, reason, since, rank}`, its four fields on `:390-393`, and carries
      no name, so the tab bar at `:889`,
      which reads `sessions[entry.name]` at `:898`, cannot see a field added to
      `panes`. The tab bar is this task's own example of the defect, so either add
      a names field to the collapsed entry at `:389-394` or change `:889` to take
      both returns. An earlier draft said the edit was one field plus a render
      change and named neither renderer.
      `deps:` 10.6
- [ ] 10.8 Act: reconcile the namespace the two joins share. This is a key
      decision and lives apart from 10.7, which decides display. An earlier draft
      merged them, and 10.5 could then draw no correct edge: it needs this half
      and not the other, and the merged task's own first line says it decides
      display and not key.
      There are three name producers today:
      `selected.json` holds `mux.get_active_workspace()` (`ui.lua:183`, written at
      `:192`, read at `agent-sessions.sh:19`), a wezterm workspace name; the
      record's `.session` (`agent-sessions.sh:66-67`, defaulting to `default`),
      which this phase changes to a zmx name; and `sy list`
      (`agent-sessions.sh:78`), seshy names. Two joins consume them.
      `agent-sessions.sh:98` computes `$names - ($active | map(.name))`, seshy names
      minus record names, so if the two namespaces diverge the subtraction removes
      nothing and every live session is emitted twice, once in `$active` and once
      in `$idle` with `status: null`. `desktop.nix:343` computes
      `.name != $sel`, a record name against a workspace name, so on divergence the
      selected session fails to exclude itself from the `+N` badge.
      Decide which producer wins, and settle both joins with that one decision.
      They do not share a producer pair: `:98` joins producer 3 against producer
      2, while `desktop.nix:343` joins producer 2 against producer 1, the
      workspace name in `selected.json`. So reconciling `:98` alone leaves `:343`
      still comparing a session name against a workspace name, and the selected
      session still fails to exclude itself from the `+N` badge, which is a thing
      10.5 asserts directly. A set difference across two namespaces is
      meaningless whatever it returns, and so is an inequality test.
      Land the second half in `agent-sessions.sh` and not in `desktop.nix`.
      `desktop.nix:342` binds `$sel` from `.selected` in the payload it is handed,
      so it consumes the name and cannot resolve it. The value is built at
      `agent-sessions.sh:19` from `selected.json`, which `ui.lua:192` writes, so
      those two are the only places the reconciliation can go. `agent-sessions.sh`
      is the better of them, because the sketchybar widget reads the same
      `selected` field from the same payload (`agent_sessions.lua:30`), so one
      edit there settles both surfaces where an edit in `desktop.nix` would settle
      one. An earlier draft named both joins and instructed on one, and a later
      one offered `desktop.nix:343` as a place to resolve `$sel`, which sends an
      implementer to a consumer. `deps:` 10.4, 10.6
- [ ] 10.9 Verify: the `agent-identity.sh` fork does not run when a cheaper
      source answers. Put a stub named `wezterm` first on `PATH` that appends to
      a marker file and exits non-zero, set `ZMX_SESSION`, source the file, call
      `agent_identity` with a non-empty pane argument, and assert it resolves the
      session AND the marker file is absent. Then unset both earlier sources, call
      it again, and assert the marker file now exists. Source and call; do not run
      the file. An earlier draft said "run the script" and there is no script:
      `agent-identity.sh` defines two functions and nothing else, so executing it
      defines them and exits, producing no marker in either half and passing half
      one for the wrong reason.
      Both halves are needed: the first proves the gate is there, the second
      proves the gate did not become a deletion, which would take the fallback
      away from the readers 10.6 says must keep it. This is a behavioral check
      because the property is control flow and the gated call has the same text as
      the ungated one, so no grep distinguishes them.
      Source `agent-identity.sh` directly in the test shell. Do NOT put the stub
      on the `PATH` of `agent-notify` or `agent-prompt` and run those: the stub is
      unreachable there and both halves of the check break in opposite directions.
      `agent-identity.sh` is never installed as a program. `rg -n 'agent-identity'`
      returns one hit outside `openspec`, `runtime/default.nix:103`, which reads it
      into a string that is concatenated into two `writeShellApplication`s, and
      both list `pkgs.wezterm` in `runtimeInputs` (`:132`, `:157`).
      `writeShellApplication` prepends `runtimeInputs` to `PATH` ahead of the
      inherited one, so `command -v wezterm` at `:4` returns the store binary and
      the stub never runs. Half one would then find the marker absent because the
      stub was unreachable rather than because the gate worked, which is a pass on
      the exact defect it targets; half two would find the marker missing forever
      and fail on a correct implementation. Sourcing the file works because it is a
      function library with no top-level side effects, so `:4` executes as written
      and `PATH` decides. Overriding `runtimeInputs` in a test derivation is the
      other correct form. Pass a non-empty pane argument in both halves, or
      `ai_workspace` returns at `:3` and the second half asserts a marker that
      could never appear. Run the test shell without `errexit` and `pipefail`, to
      match production. Only two applications embed this file, `agent-notify` and
      `agent-prompt`, and both set `bashOptions = [ ]` (`runtime/default.nix:134`
      and `:160`; the embeds are `:135` and `:167`). An earlier draft cited five
      sites, which is every `bashOptions = [ ]` in the file and three more than the
      claim needs. The stub exits
      non-zero, so a harness with those options aborts the caller at the pipeline
      on `:6-8`. The marker assertion would still hold, since the stub writes
      before it exits, but nothing after the pipeline would run. `deps:` 10.6
- [ ] 10.10 Verify: a command still running after a detach is still running after
      a reattach, decided by starting a `sleep` in a zmx session, closing the
      wezterm pane, opening a new one, and reattaching. This is the property zmx
      is here for, and nothing else in the change tests it. `deps:` 10.6
- [ ] 10.11 Verify: the surfaces agree by name. There are two keys and three
      surfaces, and an earlier draft said two of each. `agent-sessions` is one
      producer with three consumers: itself, the sketchybar widget, and the waybar
      module, all inheriting the record's `session`; the wezterm deck is the one
      surface on the workspace key, which it resolves itself. Run two agents in
      two zmx sessions in one wezterm workspace and assert that `agent-sessions`
      and the sketchybar widget both report two entries under the zmx session
      names, and that the deck shows one group named for the workspace containing
      both of those same session names. An earlier draft checked cardinality
      per surface without comparing names across them, which passes while two
      displays disagree.
      Also confirm an agent in a pane with no `ZMX_SESSION` still resolves,
      through the readers 2.2 moved that fallback to. `deps:` 10.7, 10.8
- [ ] 10.12 Verify: re-record the two host drvPaths. This phase adds a package
      on purpose, so name each difference by diffing the derivation-path sets
      against the 3.14 recording. The `lv426` half runs locally and the `arrakis`
      half runs in the CI job 1.1 adds. `deps:` 10.11
- [ ] 10.13 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on whether zmx and seshy now own the same fact under two
      names, and on whether the session key can disagree between the file bus and
      the deck after 10.8. `deps:` 10.12

## 11. Closeout

- **SHAPE** graph

- [ ] 11.1 Verify: the two host drvPaths still match the phase 10 re-recording,
      which is the last one, since phase 10 adds a package and phases 4 through 9
      are closure-neutral. Separately, enumerate what phases 2, 3, and 10 changed
      by diffing the derivation-path sets against 1.1's, and confirm every entry
      is named in a task of one of those three phases. A `drvPath` is one opaque
      hash: it answers equal or unequal and cannot be diffed into a list, so an
      earlier draft asked for an enumeration the named artifact cannot produce.
      The `lv426` half runs locally and the `arrakis` half runs in the CI job 1.1
      adds. An unexplained entry is a silent loss.
      `deps:` 10.13
- [ ] 11.2 Act: write the spec deltas this change owes. `agent-state-emission`
      keeps its OSC requirement because 2.2 reverses the deletion, so that one
      needs no delta. The behaviors with no spec today and a spec-worthy
      contract after this change are the note file and its derived export, and
      `review` as the reader. Add them rather than leaving a change that ships
      behavior no spec describes. `deps:` 11.1
- [ ] 11.3 Act: remove the gate scaffolding in the same commit that archives
      the change. Delete `.github/workflows/closure-baseline.yml`,
      `hack/host-baseline.sh`, and `openspec/changes/make-sysinit-composable/baseline/`.
      This is its own task because nothing else closes the loop: archiving moves
      the change directory under `openspec/changes/archive/`, and the workflow
      diffs against paths inside it, so the job breaks on the archive commit.
      Same commit, not a follow-up, or there is a window where the workflow points
      at a path that no longer exists. 11.1 is the last consumer of the baseline,
      which is why this depends on it rather than running earlier. Keep
      `hack/host-baseline.sh` only if something outside this change has adopted
      it by then; check before deleting. `deps:` 11.2
- [ ] 11.4 Act: open the follow-on change `decompose-wezterm-ui`, which
      design.md section 8 sequences after this one. `deps:` 11.3
- [ ] 11.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics are NOT run: the owner directed on 2026-08-08 that the apply
      proceed on deterministic lint alone, so every task in this list reaches the
      `not run` terminal state the skill defines and records the open questions
      rather than refuting them. The questions below are what critics WOULD have
      been asked, kept because they name where this phase is weakest on the whole diff, asking what a profile smaller than
      `workstation` silently loses that nothing asserts. `deps:` 11.4
