## 1. The writer

- **SHAPE** graph
- **MERGE** 1.4

- [ ] 1.1 Declare the event-log location as a new path in the layout manifest, so both ends resolve it and neither hardcodes it `writes:` modules/shared/options/paths-layout.json `deps:` none
- [ ] 1.2 Add a `sysinit-agent` subcommand that appends one JSON event per edited file, keyed to a workspace the way the diff-note path is keyed, and bounded in size, following `pkgs/sysinit-agent/internal/note/` for layout and `internal/agentstate/` for stdin handling `writes:` pkgs/sysinit-agent/main.go, pkgs/sysinit-agent/internal/editevent/ `deps:` 1.1
- [ ] 1.3 Prove the failure paths with Go tests: an unwritable log directory still exits 0 with no stdout, concurrent writers each produce an intact line, and passing the size bound leaves the newest events and a shorter file `writes:` pkgs/sysinit-agent/internal/editevent/ `deps:` 1.2
- [ ] 1.4 Expose the subcommand through the runtime wrapper that already exposes `agent-state`, then prove `nix flake check` and `go test ./...` exit 0 `writes:` modules/home/programs/llm/runtime/default.nix `deps:` 1.2, 1.3
- [ ] 1.5 Adversarial review (`adversarial-review` skill): critics attempt to break the writer phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)

## 2. Claude emits events

- **SHAPE** graph
- **MERGE** 2.2

- [ ] 2.1 Record edit-bus capability as its own field on every registry entry, true for claude and false elsewhere until each surface is proven `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 2.2 Give claude a post-edit hook that writes one event per edited file, reusing the matcher its existing pre-edit guard already uses, then prove `nix build .#darwinConfigurations.lv426.system` exits 0 `writes:` modules/home/programs/llm/harnesses/claude/default.nix `deps:` 2.1
- [ ] 2.3 Adversarial review (`adversarial-review` skill): critics attempt to break the claude wiring against the proposal `Behavior` criteria; revise until the loop reaches a terminal state
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
