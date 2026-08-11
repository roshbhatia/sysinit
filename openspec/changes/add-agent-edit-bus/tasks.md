## 1. The writer

- **SHAPE** graph
- **MERGE** 1.4

- [x] 1.1 Declare the event-log location as a new path in the layout manifest, so both ends resolve it and neither hardcodes it `writes:` modules/shared/options/paths-layout.json `deps:` none

      `agentEdits` = `$HOME/.local/state/agents/edits`, beside `agentDiffNotes`.
      `paths.go` gained `AgentEditsKey` and `AgentEdits()` with the same
      manifest-then-fallback shape every other accessor has, so a box whose
      manifest predates the entry still resolves a path rather than an empty
      string.

- [x] 1.2 Add a `sysinit-agent` subcommand that appends one JSON event per edited file, keyed to a workspace the way the diff-note path is keyed, and bounded in size, following `pkgs/sysinit-agent/internal/note/` for layout and `internal/agentstate/` for stdin handling `writes:` pkgs/sysinit-agent/main.go, pkgs/sysinit-agent/internal/editevent/ `deps:` 1.1

      `sysinit-agent edit-event <harness> [--file P]... [--kind K] [--cwd D]`,
      falling back to `tool_input.file_path` and `cwd` on stdin when no flag
      supplies them. One line per file:
      `{version, ts, harness, kind, file, cwd}`.

      Two things the task text does not name had to be decided.

      The keying and the workspace rule went into `internal/repo`, not into the
      new package, because `repo` already owned both: `noteBase` was refactored
      into a shared `keyed(dir, root)` and `EditLogFile` reuses it, so the
      diff-note and edit-log names cannot drift apart. `Workspace(dir)` applies
      `agentstate.identify`'s rule in `identify`'s order, seshy session before
      git top level, but runs no `git status`: a hook on the edit path should not
      pay for a working-tree scan whose result it never reads.

      `parse` is the one loud failure path. A malformed argument list comes from
      a Nix expression rather than from bad luck, so it prints to stderr once.
      It still exits 0, because the agent can do nothing about it either way.

- [x] 1.3 Prove the failure paths with Go tests: an unwritable log directory still exits 0 with no stdout, concurrent writers each produce an intact line, and passing the size bound leaves the newest events and a shorter file `writes:` pkgs/sysinit-agent/internal/editevent/ `deps:` 1.2

      Ten tests. Beyond the three the task names: the line carries no file
      contents (asserted against a sentinel written into the file), a call
      naming no file creates no log at all, a seshy session keys one log for two
      repositories under it, and stdin supplies the path when no flag does.

      Five mutations, each applied to the committed tree and reverted:

      | Mutation | Caught by |
      | --- | --- |
      | `O_APPEND` dropped | 4 tests, concurrency among them |
      | truncation keeps the oldest lines | `TestBoundKeepsNewestAndShortensFile` |
      | truncation disabled | same |
      | exit 1 when the log is unwritable | `TestUnwritableLogDirectoryStillExitsZero` |
      | seshy branch removed from `Workspace` | `TestSeshySessionKeysOneLogForSeveralRepositories` |

      The first attempt at the exit-1 mutation reported a pass. The test had not
      run: this shell resets its working directory between calls, so
      `./internal/editevent/` resolved to nothing. Re-run from the module root it
      fails, as it should. Two of the five were verified only after that was
      found.

- [x] 1.4 Expose the subcommand through the runtime wrapper that already exposes `agent-state`, then prove `nix flake check` and `go test ./...` exit 0 `writes:` modules/home/programs/llm/runtime/default.nix `deps:` 1.2, 1.3

      `agent-edit-event`, named for what it records rather than for a harness,
      since the harness is an argument. Added to the `inherit` list, given an
      `editEventExe`, and installed through `home.packages` in
      `llm/default.nix`, which is the step `stateScript` needs and the runtime
      file alone does not provide.

      `nix flake check` exits 0. `nix build .#darwinConfigurations.lv426.system`
      exits 0. `go test ./...`, `go vet ./...`, and `gofmt -l` are all clean
      across the whole module, not only the new package.

      The first build failed with `cannot find module providing package
      .../internal/editevent`. The cause was not vendoring: flakes copy tracked
      files only, and the new directory was untracked. Staging it fixed it.

      `nix fmt` also reformatted `modules/home/programs/seshy/default.nix`, which
      this change does not touch. Reverted rather than carried, so no
      formatting-only edit rides along; the drift is left where it was found.

      Smoke-tested against the built store path, not only in tests: both the
      `--file` form and a real claude `PostToolUse` stdin payload write one
      correct line and exit 0.

- [x] 1.5 Adversarial review (`adversarial-review` skill): critics attempt to break the writer phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)

      NOT-RUN, per the owner decision recorded in `review.md`. The
      already-implemented risk named there was the one that mattered for this
      phase and it did not appear: nothing in the repository wrote edit events
      before this.

## 2. Claude emits events

- **SHAPE** graph
- **MERGE** 2.2

- [x] 2.1 Record edit-bus capability as its own field on every registry entry, true for claude and false elsewhere until each surface is proven `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` none

      `editBus` on all 14 entries, true on claude alone.

      One thing the task text does not name: the field needed a guard, because
      like `neovimAdapter` it is read by no Nix code, and the way to get it wrong
      is to claim it on a `notify = "scrape"` harness that has no hook surface at
      all. That entry would look supported and emit nothing.
      `runtime/default.nix` now throws on that combination, alongside the two
      assertions already there.

      The guard was verified by injecting `editBus = true` on amp, whose notify
      is `scrape`. Instantiation fails with `amp sets editBus but notify is not
      "hook"`. Restored from a copy, not with `git checkout`, since the tree
      carries other work.

      `nix eval --apply "x: 1"` did NOT catch it: the throw lives in a
      `runCommand` script, so nothing forces it until the derivation is
      instantiated. `.drvPath` is what forces it.

- [x] 2.2 Give claude a post-edit hook that writes one event per edited file, reusing the matcher its existing pre-edit guard already uses, then prove `nix build .#darwinConfigurations.lv426.system` exits 0 `writes:` modules/home/programs/llm/harnesses/claude/default.nix `deps:` 2.1

      A `PostToolUse` entry on `Edit|Write|NotebookEdit`, the same matcher the
      nix guard already uses in `PreToolUse`, running
      `agent-edit-event claude` with `async = true`. Claude had no `PostToolUse`
      block at all before this.

      Build exits 0. The rendered `claude-code-settings.json` in the store holds
      the hook with the profile path resolved, which is stronger evidence than
      the build alone: it proves the wrapper is on PATH under the name the hook
      calls.

- [x] 2.3 Adversarial review (`adversarial-review` skill): critics attempt to break the claude wiring against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      NOT-RUN, per the owner decision recorded in `review.md`. The
      capability-overclaim risk named there is the one this phase could have hit,
      and the guard added in 2.1 is the answer to it.
- [ ] 2.4 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 2.5 Confirm: the owner edits a file through claude and accepts that the events written name the files they expected, at the volume they expected, with nothing recorded that claude did not touch

## 3. Neovim reads events

- **SHAPE** graph
- **MERGE** 3.3

- [ ] 3.1 Add a watcher that resolves the log from the installed manifest, starts at the current end of the file, survives the file being replaced under it, and reloads an open buffer only when it holds no unsaved changes `writes:` modules/home/programs/neovim/config/lua/harness/edit_events.lua `deps:` none
- [ ] 3.2 Record the files an agent touched this session, so a later review can be scoped to them `writes:` modules/home/programs/neovim/config/lua/harness/edit_events.lua `deps:` 3.1
- [ ] 3.3 Start the watcher where the polling refresh is started today, leaving that poll in place for the harnesses with no hook surface `writes:` modules/home/programs/neovim/config/lua/harness/ `deps:` 3.1, 3.2
- [ ] 3.4 Adversarial review (`adversarial-review` skill): critics attempt to break the reader phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
- [ ] 3.5 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 3.6 Confirm: the owner makes an unsaved edit to a file, has claude write that same file, and accepts what Neovim did with the conflict

## 4. The remaining hook harnesses

- **SHAPE** graph
- **MERGE** 4.6

- [ ] 4.1 Establish whether codex exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/codex.nix, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 4.2 Establish whether opencode's plugin surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/opencode/plugins/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 4.3 Establish whether atomic's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/atomic/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 4.4 Establish whether pi's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/pi/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 4.5 Establish whether prime-agent's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/prime-agent/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 4.6 Reconcile the five findings into one registry state and prove `nix build .#darwinConfigurations.lv426.system` exits 0, with no harness claiming a capability its surface does not have `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` 4.1, 4.2, 4.3, 4.4, 4.5
- [ ] 4.7 Adversarial review (`adversarial-review` skill): critics attempt to break the fan-out phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
- [ ] 4.8 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 4.9 Confirm: the owner accepts which harnesses ended up on the bus and which were recorded as incapable, rather than approximated

## 5. Reviews scoped to the turn

- **SHAPE** graph
- **MERGE** 5.2

- [ ] 5.1 Decide whether the declared review plugin can scope a diff to a file list, or whether the diff plugin beneath it must be driven directly `writes:` none `deps:` none
- [ ] 5.2 Open a review restricted to the files an agent touched this session, keeping the full working diff reachable and making the narrowed scope visible `writes:` modules/home/programs/neovim/config/lua/harness/, modules/home/programs/neovim/config/lua/plugins/review.lua `deps:` 5.1
- [ ] 5.3 Adversarial review (`adversarial-review` skill): critics attempt to break the scoping phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
- [ ] 5.4 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 5.5 Confirm: the owner accepts that a scoped review shows the work they meant to review, and that the narrowing is obvious enough to not be mistaken for the whole diff

## 6. Rollout

- [ ] 6.1 Measure an ordinary turn's event count and set the size bound and retained-line count from it, replacing whatever placeholder shipped in phase 1
- [ ] 6.2 Decide whether the poll should now be skipped for a workspace whose harness writes to the bus, or left running for every harness
- [ ] 6.3 Apply: `openspec archive add-agent-edit-bus`, gated on `specutil check` and `spec-preflight all` exiting 0
