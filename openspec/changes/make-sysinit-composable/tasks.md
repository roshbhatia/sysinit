## 1. Record the baseline

- **SHAPE** graph

- [ ] 1.1 Capture `nix eval --raw .#darwinConfigurations.lv426.system.drvPath`
      and the same for `arrakis` and `nostromo` into a scratch file. This is the
      baseline for the phases that must not change what the hosts install:
      6, 7, and 8. It is NOT a whole-change gate. Phases 2 and 3 change the
      closure on purpose, because they delete and rename packaged code, so an
      equality gate spanning them can only fail. Each of those two phases
      re-records the baseline as its last step, and states in one line what
      moved and why it was intended. Capture `owner-wezterm-sites.txt` here too,
      which task 2.9 compares against: the literal output of
      `rg --no-line-number '"wezterm"|wezterm cli'` over
      `modules/home/programs/neovim/config` with `-g '!**/doc/**'`, minus the four
      lines phase 2 removes. Run it without line numbers. 2.8 deletes 41 lines
      above `wezterm_terminal.lua:100`, which shifts five surviving sites in that
      file, so a positional artifact fails on a correct implementation. The set is
      `path:matched-text` pairs. 31 lines today, minus 1 for `doc/`, minus 4 for
      the removed lines, is 26. It has to be recorded before the edits, or the
      gate compares the edited tree against a snapshot of itself. `deps:` none
- [ ] 1.2 Capture `nix path-info -S` on the current home closure, so the profile
      split has a number to beat. `deps:` 1.1
- [ ] 1.3 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on whether the baseline captured is the right one, since
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

- [ ] 2.1 Act: in `runtime/agent-prompt.sh`, delete the `Accept)` and `Deny)`
      arms of the `case` at `:125`, the `send-text` block at `:135-137`, the
      `approve_keys` and `reject_keys` tables at `:50-59`, and
      `--actions "Accept,Deny"` at `:115`. Do not delete by line range: `:128-132`
      is the `@CONTENTCLICKED` focus branch and `:133` is the `esac`, both of
      which stay, so a range delete leaves an unterminated `case`. Re-gate the
      rich alerter at `:64-70`, which currently keys on `approve_keys` being
      non-empty and would otherwise be decided by a table that no longer exists.
      The agent deck stays. The notification says an agent needs you, and
      clicking it puts you in the pane, where you answer. `deps:` 1.1
- [ ] 2.2 Act: keep the OSC `SetUserVar` write in `internal/agentstate`. An
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
- [ ] 2.3 Act: leave `pane_agent_state` at `wezterm/lua/sysinit/pkg/ui.lua`
      alone. An earlier draft deleted `:330-348` as "the user-var path". That
      range is the whole function, and `:342-346` is the agent-deck fallback,
      which is the only status source for the seven harnesses that fire no
      hooks. `deps:` 2.2
- [ ] 2.4 Act: stop exposing `wtrun` to agents. Remove it from the rendered
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
- [ ] 2.5 Act: make `spec_watch.lua` opt-in by deleting the unconditional
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
- [ ] 2.6 Act: delete `neovim/config/lua/harness/control.lua` and
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
- [ ] 2.7 Act: cut the agent's route into the editor's pane-driving code, and
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
- [ ] 2.8 Act: fix the orphan and decide the `$EDITOR` shim. `plugins/harness.lua:25`
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
- [ ] 2.9 Verify: no agent-reachable path drives a terminal or an editor. The
      gate has four clauses and only one is a grep for nothing: a search for any
      nvim socket or msgpack reference under `pkgs/` returns nothing.
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
      At 2.9 the live command must equal that 26-entry set exactly. That fails when a site is left
      behind and it fails when a new one appears, which a grep for nothing does
      neither of once the answer is not zero. It must match the argv-table form,
      since nine of the fourteen sites are written that way and only five are
      string-form: `wezterm_terminal.lua:53`, `:57`, `:104`, `:165`, and
      `preview.lua:61`. An earlier draft said the old pattern saw four, a number
      left over from the draft that called the total thirteen; it returns eight
      lines over the config.
      The fifth clause is `rg -n 'wezterm' pkgs/sysinit-agent` returning nothing,
      which is what proves 2.2 deleted the per-tool-call fork. Clause one cannot
      see it: `agentstate.go:329` is
      `exec.Command("wezterm", "cli", "list", "--format", "json")`, so no
      `wezterm cli` string pattern matches it, and an earlier draft left the fork
      with no clause at all.
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
      `nix store diff-closures` at 2.12 cannot see it.
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
- [ ] 2.10 Verify: `wtrun` still passes its own contract unchanged, since 2.4
      changes who may call it and not what it does. `wtrun -w 0 'false'` exits 1,
      `wtrun -w 1 'sleep 5'` exits 75, and the `sleep` is still running when it
      does. `deps:` 2.4
- [ ] 2.11 Confirm: owner uses an agent for one session and reports whether
      anything they relied on is now missing. Record, rather than claim absence,
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
- [ ] 2.12 Verify: re-record the three host drvPaths. This phase changes them on
      purpose, so name each difference and its cause, using
      `nix store diff-closures` rather than the hashes alone. `deps:` 2.11
- [ ] 2.13 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on whether 2.2's self-report line is a real distinction
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

- [ ] 3.1 Gather: probe the `hunk` binary, not its README. It is not installed
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
      `deps:` 2.9
- [ ] 3.2 Act: add the `hunk` flake input back, pinned to its own nixpkgs. Do
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
- [ ] 3.3 Act: ship `review`, a command that runs
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
      through, omit `--agent-context`, or synthesize an empty export. `deps:` 3.2
- [ ] 3.4 Act: rename `internal/diffnote` to `internal/note` and remove only the
      neovim paths from it. Keep `add`, `apply`, `list`, `clear`, and `path`,
      and keep `--rationale`, `--author`, and `--replace`: task 3.1 establishes
      that hunk has no field for them, so deleting them loses data. Delete
      `--no-open` and every call into `nvimlink`. Keep `internal/store` byte for
      byte. `deps:` 3.3
- [ ] 3.5 Act: add the hunk-shaped export as a derived file the writer
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
      and lands outside it. Mark the export as derived in the file itself. That
      is advisory and not enforcement: nothing compares the export against the
      record, so an owner edit is still overwritten silently and the marker only
      changes what they can learn afterward. Do not also put it in the skill,
      because agents never open the export and the owner who stumbles on it is
      not reading an agent skill. The marker must be a key hunk's parser sees,
      since the export carries hunk's schema and JSON has no comments, so 3.1
      also records whether `--agent-context` tolerates an unknown top-level key
      and 3.13's accepted fixture is the marked file rather than a bare one. Rebuild fails on a malformed
      record because `readDoc` refuses one (`diffnote.go:147-160`); that is a
      loud failure and `clear --yes` stays the documented escape. `deps:` 3.4
- [ ] 3.6 Act: delete `internal/nvimlink` and the `neovim/go-client` dependency,
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
      gate cannot go green. `deps:` 3.4
- [ ] 3.7 Act: delete `neovim/config/lua/harness/diffnote.lua` and its callers
      in `plugins/codediff.lua`. Delete the five `harness.diffnote` call sites at
      `:69-71`, `:87`, `:102`, `:121`, and `:128`, and the two keymap entries
      that contain them. Do not delete `:69-128` as a span: the file is 142
      lines, that range ends inside the `<leader>dN` entry and leaves an orphan
      `end,` tail, and it also swallows the `CodeDiffFileSelect` wrapper, the
      `CodeDiffClose` restore, and the `<leader>dd` and `<leader>dH` keymaps,
      none of which is diffnote. This removes inline virtual text, the
      `<leader>dn` quickfix list, the `<leader>dN` float, and the fs watcher.
      That loss is the decision, not an oversight. `deps:` 3.6
- [ ] 3.8 Act: replace `skills/diffnote/` with a skill that wraps
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
      to a prompt, which reads as friction rather than as a defect. `deps:` 3.7
- [ ] 3.9 Verify: a note carrying a multi-line rationale and an author, written
      with no `hunk` process running, is readable from the RECORD afterward with
      both fields intact. That half is unconditional. What `review` displays
      depends on 3.1: if the schema has no multi-line field, 3.5 permits the
      loss in the export, and then this task asserts only that the design says
      so. The record is the contract; the display is what the probe allows.
      `deps:` 3.7
- [ ] 3.10 Verify: a note written AFTER `review --watch` is already running
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
      asserted in prose and checked nowhere. `deps:` 3.5
- [ ] 3.11 Verify: `go test ./...` passes under `pkgs/sysinit-agent` with all
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
      that no STOP pattern matches. `deps:` 3.5
- [ ] 3.12 Verify: `neovim/config/lua/` has no remaining reference to any
      sysinit binary or state path, so the config is standalone. Scope this to
      the whole lua tree, not `harness/` alone: 3.7 edits
      `plugins/codediff.lua`, which an earlier draft's scope excluded, and three
      of its call sites sit inside `pcall` (`:68-72`, `:86-88`, `:101-103`), so
      a missed one fails silently on every CodeDiff open rather than throwing.
      Load the config headlessly here, since no other gate in the phase does. `deps:` 3.7
- [ ] 3.13 Act: add a `checks/` assertion that the export schema still matches
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
      unchanged. `deps:` 3.5, 3.8
- [ ] 3.14 Verify: re-record the three host drvPaths. This phase changes them on
      purpose, so name each difference and its cause, using
      `nix store diff-closures` rather than the hashes alone. Phases 6 through 8
      compare against this recording, not against 1.1. `deps:` 3.8
- [ ] 3.15 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the claim that no behavior was lost silently, on the
      derived export as an artifact that can go stale against its record, and
      on the loopback daemon as an unauthenticated local listener. `deps:` 3.14

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
      also fail 4.3's check, whose allowlist holds only the module. Exempt the
      template there alongside `paths.nix`, have 9.7 expand it rather than author
      paths, and let 9.8 compare the expanded file against it. The absolute path
      is required because
      `repo.go:63-64` records that nvim launched from a mux server inherits no
      session variables, so `XDG_STATE_HOME` is unset exactly where the fallback
      runs. That comment is about nvim; treat it as the demonstrated case rather
      than as proof for every consumer, and confirm the same for the shell and
      python readers while implementing. Allow each consumer exactly one documented default, keyed to
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
      Add the check as a pre-commit assertion over the whole tree, allowing the
      path only in `modules/shared/options/paths.nix` and in the layout template
      4.1 defines, which 9.7 expands on a box with no Nix. Those two are the
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
      keeps the OSC channel, and make the readers cite it. A fact with several
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
      lint; run critics on the generated manifest, where a consumer silently
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
      lint; run critics on whether a viewer that polls files reproduces the
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
- [ ] 6.5 Verify: the three drvPaths are unchanged against the baseline as
      re-recorded at the end of phase 3, not against 1.1. Phases 2 and 3 moved
      it on purpose. This phase must not move it at all: it only reorganizes
      which module is selected, so any difference is a module silently dropped
      from a profile. `deps:` 6.4
- [ ] 6.6 Verify: `nix path-info -S` on `minimal` is smaller than on
      `workstation`, and the `minimal` and `workstation` drvPaths differ from
      each other. Both clauses are the STOP gate, not 6.5 alone. `drvPath` is
      input-addressed, so a gate that only checks `workstation` equality passes
      when the profile layer was never wired: an `optionals` expression that
      yields the same list for every profile is identical to no profile layer,
      and 6.5 cannot tell them apart. `deps:` 6.5
- [ ] 6.7 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the gating, where a mis-scoped `optionals` silently
      drops a module from every profile. `deps:` 6.6

## 7. Decouple theming

- **SHAPE** graph

- [ ] 7.1 Gather: list the 21 modules referencing `stylix` and note what
      each sets. `deps:` 6.5
- [ ] 7.2 Act: add `sysinit.theme.enable`, default true, guarding each.
      `deps:` 7.1
- [ ] 7.3 Verify: with the flag true the generated wezterm and neovim theme
      files are byte-identical to today. `deps:` 7.2
- [ ] 7.4 Verify: with the flag false the home modules evaluate without the
      stylix module present. `deps:` 7.2
- [ ] 7.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on guards placed at the wrong nesting level, which would
      change the true branch too. `deps:` 7.4

## 8. Standalone home configurations

- **SHAPE** graph

- [ ] 8.1 Act: add a `mkHome` builder supplying the specialArgs the home tree
      expects without going through nix-darwin. `deps:` 7.4
- [ ] 8.2 Act: emit `homeModules` and `homeConfigurations.<profile>-<system>`
      for `dev` and `minimal` across the four systems. `deps:` 8.1
- [ ] 8.3 Verify: `nix build .#homeConfigurations.dev-x86_64-linux.activationPackage`
      succeeds. `deps:` 8.2
- [ ] 8.4 Confirm: owner runs `home-manager switch --flake .#dev` on a Linux box
      or container and reports whether the shell and editor come up. `deps:` 8.3
- [ ] 8.5 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on `mkHome`, where a missing specialArg fails only for
      the modules that read it. `deps:` 8.4

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
      manifest is the source. `deps:` 9.1, 6.2
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
- [ ] 9.9 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the generator, where silent drift between the two
      lists is the failure this phase exists to prevent. `deps:` 9.8

## 10. The session substrate

zmx is a session manager with one job: a named shell session that survives a
detach. It has no windows, panes, or splits on purpose, because that is the
window manager's job. That is the same line this change draws everywhere else,
so it belongs here rather than in a change of its own.

It enters under zsh, and seshy and wezterm integrate with it. It does NOT
replace `wtrun`, whose worker pane is an owner-visible surface, and it does not
become phase 5's viewer source. Widening it to those is a separate decision.

- **SHAPE** graph

- [ ] 10.1 Gather: probe the installed `zmx`, not its README, in the shape of
      3.1. Record the environment variables it sets, and specifically whether a
      child process spawned inside a session inherits `ZMX_SESSION`. The whole
      argument for the dependency is that this key is readable with no fork and
      no terminal, and an earlier draft asserted it from documentation. zmx is
      the only third-party dependency in this change with no probe, which is the
      standard 3.1 sets for the other one. `deps:` 4.1
- [ ] 10.2 Act: add `zmx` to the `dev` package group and a
      `modules/home/programs/zmx/` module owning `ZMX_SESSION_PREFIX` and
      `ZMX_DIR`. Name the group, because 10.3's fallback argument depends on it:
      phase 9's box has no Nix, and 9.1 makes `bootstrap/tools.toml` the
      `minimal` manifest, so zmx in `minimal` would falsify that premise. It is
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
- [ ] 10.4 Act: make every zmx session name a seshy session name, and use
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
- [ ] 10.5 Verify: every name `zmx list` reports is a name `sy list` reports.
      One direction, per 10.4. Nothing else in the phase exercises the invariant
      10.4 introduces, and an earlier draft asked 10.4 to "add the comparison"
      with no task running it. Create two sessions with `s` first and assert
      `zmx list` is non-empty before comparing. Subset-of holds trivially when the
      left side is empty, and on a box where no session has been entered that is
      the state the check finds, so without the non-empty assertion this task
      passes without testing anything. `deps:` 10.4
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
      so it runs only when both earlier sources are empty. That fork at `:6-7`
      is `"$ai_wz" cli list --format json`, the shell twin of the Go fork 2.2
      deletes, and it runs unconditionally today. No clause of 2.9 can see it:
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
      identical text. Task 10.8 checks it by behavior instead. `deps:` 10.2
- [ ] 10.7 Act: decide what the agent deck groups by, and write it down. The
      three-source key 10.6 sets governs the file bus. The deck does not read it:
      `ui.lua:349-398` walks `wezterm.mux.all_windows()`, takes
      `win:get_workspace()` at `:357`, and groups by that at `:377` and `:388`,
      never reading the record's `session`. So two zmx sessions inside one
      wezterm workspace collapse to one deck group, and that is the motivating
      case, since zmx exists to make a session independent of the terminal and
      the owner has no reason to open a second workspace. `ui.lua` cannot read
      `ZMX_SESSION` in any case: it runs in the mux process and the variable is
      in a pane's child shell. This disagreement predates zmx, because `identify`
      already writes the seshy directory name while the deck groups by workspace.
      Either make the deck prefer the record's `session` when present, which is a
      scoped edit at `:377` and `:388` and not the `ui.lua` rewrite the non-goals
      forbid, or record in `design.md` that the deck is workspace-keyed by design
      and that zmx sessions inside one workspace merge there. Do one or the
      other. Leaving it is two surfaces naming one pane two ways with nothing
      comparing them. `deps:` 10.6
- [ ] 10.8 Verify: the `agent-identity.sh` fork does not run when a cheaper
      source answers. Put a stub named `wezterm` first on `PATH` that appends to
      a marker file and exits non-zero, set `ZMX_SESSION`, run the script, and
      assert it resolves the session AND the marker file is absent. Then unset
      both earlier sources, run it again, and assert the marker file now exists.
      Both halves are needed: the first proves the gate is there, the second
      proves the gate did not become a deletion, which would take the fallback
      away from the readers 10.6 says must keep it. This is a behavioral check
      because the property is control flow and the gated call has the same text as
      the ungated one, so no grep distinguishes them. `deps:` 10.6
- [ ] 10.9 Verify: a command still running after a detach is still running after
      a reattach, decided by starting a `sleep` in a zmx session, closing the
      wezterm pane, opening a new one, and reattaching. This is the property zmx
      is here for, and nothing else in the change tests it. `deps:` 10.6
- [ ] 10.10 Verify: two clauses, one per surface, since 10.7 establishes they use
      different keys. In `agent-sessions`, two agents in two zmx sessions produce
      two groups, keyed by the record's `session`. In the deck, the result is
      whichever 10.7 decided, checked against that decision by name rather than
      by count. An earlier draft checked cardinality per surface without
      comparing names across them, which passes while the two displays disagree.
      Also confirm an agent in a pane with no `ZMX_SESSION` still resolves,
      through the readers 2.2 moved that fallback to. `deps:` 10.7
- [ ] 10.11 Verify: re-record the three host drvPaths. This phase adds a package
      on purpose, so name each difference with `nix store diff-closures`.
      `deps:` 10.10
- [ ] 10.12 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on whether zmx and seshy now own the same fact under two
      names, and on whether the session key can disagree between the file bus and
      the deck after 10.7. `deps:` 10.11

## 11. Closeout

- **SHAPE** graph

- [ ] 11.1 Verify: the three host drvPaths still match the phase 10 re-recording,
      which is the last one, since phase 10 adds a package and phases 4 through 9
      are closure-neutral. Separately, enumerate what phases 2, 3, and 10 changed
      with `nix store diff-closures` against the 1.1 build, and confirm every
      entry is named in a task of one of those three phases. A
      `drvPath` is one opaque hash: it answers equal or unequal and cannot be
      diffed into a list, so an earlier draft asked for an enumeration the named
      artifact cannot produce. An unexplained entry is a silent loss.
      `deps:` 10.12
- [ ] 11.2 Act: write the spec deltas this change owes. `agent-state-emission`
      keeps its OSC requirement because 2.2 reverses the deletion, so that one
      needs no delta. The behaviors with no spec today and a spec-worthy
      contract after this change are the note file and its derived export, and
      `review` as the reader. Add them rather than leaving a change that ships
      behavior no spec describes. `deps:` 11.1
- [ ] 11.3 Act: open the follow-on change `decompose-wezterm-ui`, which
      design.md section 8 sequences after this one. `deps:` 11.2
- [ ] 11.4 Adversarial review (`adversarial-review` skill): run deterministic
      lint; run critics on the whole diff, asking what a profile smaller than
      `workstation` silently loses that nothing asserts. `deps:` 11.2
