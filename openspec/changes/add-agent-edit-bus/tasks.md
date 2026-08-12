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
- [x] 2.4 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0

      Run at the owner's direction, in a spawned WezTerm window rather than the
      conversation pane. Exit 0. The generation diff added exactly one path,
      `agent-edit-event`, and nothing else.

      Three live checks after it: the installed manifest resolves `agentEdits` to
      `~/.local/state/agents/edits`, `agent-edit-event` is on PATH under
      `/etc/profiles/per-user/roshan/bin`, and `~/.claude/settings.json` holds the
      `PostToolUse` entry with that resolved path.

- [x] 2.5 Confirm: the owner edits a file through claude and accepts that the events written name the files they expected, at the volume they expected, with nothing recorded that claude did not touch

      Closed on the owner's 2026-08-12 delegation. The trial below is joined by a
      second body of evidence the trial could not give: an ordinary working day.

      This repository's own log held 45 events over one 2026-08-12 session, 41 `edit`
      and 4 `write`, across 14 distinct files. Every file named is one claude actually
      wrote. The shape is what the phase predicted: `worker.go` at 20 events, four
      artifacts at 4 each, and a long tail of single edits.

      Three findings the trial's five-event run could not surface, all of which land
      on phase 5 rather than here:

      - 3 of the 14 files are OUTSIDE the workspace the log is keyed to, because the
        key comes from the cwd and the event carries an absolute path. A review scoped
        to this list has to expect a path its repository does not contain.
      - A subagent's edit is recorded under the parent's workspace as `harness:
        claude`, which is right and was untested: `modules/lib/shell/aliases.nix`
        appears because a background agent edited it.
      - An edit made by a Bash script rather than by the Edit or Write tool is NOT
        recorded, because the hook is on the tools. `tasks.md` shows 4 events for a
        file edited far more often than that through `python3`. That is the honest
        bound on any review scoped to this log, and 6.1 must set its numbers knowing
        the count is a floor rather than a total.

      Trial run in a fresh seshy session, `edit-bus-trial`, with claude driven
      non-interactively. Asked for two Writes, one Read, one Edit, and one Bash
      call. The log holds three events: `write a.txt`, `write b.txt`,
      `edit a.txt`. The Read and the Bash call recorded nothing, which is the
      negative case in `proposal.md` holding on a live harness rather than in a
      test.

      One log, keyed to the session directory, at the digest predicted before the
      run. Paths absolute.

      The first trial found a defect the tests did not. All four events read
      `kind: "edit"`, three of them Writes, so the field carried no information.
      Fixed by reading `tool_name` from the payload, with `edit` as a fallback
      rather than a default; three tests added and a sixth mutation confirms the
      tool name is load-bearing. The numbers above are from the re-run after the
      fix and a second switch.

      Left in place for the owner to inspect: the session, and the log at
      `~/.local/state/agents/edits/edit-bus-trial-2ff968978c83bf25.jsonl`.

## 3. Neovim reads events

- **SHAPE** graph
- **MERGE** 3.3

- [x] 3.1 Add a watcher that resolves the log from the installed manifest, starts at the current end of the file, survives the file being replaced under it, and reloads an open buffer only when it holds no unsaved changes `writes:` modules/home/programs/neovim/config/lua/harness/edit_events.lua `deps:` none
- [x] 3.2 Record the files an agent touched this session, so a later review can be scoped to them `writes:` modules/home/programs/neovim/config/lua/harness/edit_events.lua `deps:` 3.1
- [x] 3.3 Start the watcher where the polling refresh is started today, leaving that poll in place for the harnesses with no hook surface `writes:` modules/home/programs/neovim/config/lua/harness/ `deps:` 3.1, 3.2
- [x] 3.4 Adversarial review (`adversarial-review` skill): critics attempt to break the reader phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: NOT-RUN, recorded in `review.md:75` at the owner's explicit
      direction on 2026-08-11. What stands in its place is the live probe under 3.6,
      which is stronger than a test on one point and weaker on another: it exercised
      the real watcher against the real log, and it found that `--remote-expr`
      triggers the reload it was trying to measure, so `offset` and `touched` are the
      evidence and a reload is not.
- [x] 3.5 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [x] 3.6 Confirm: the owner makes an unsaved edit to a file, has claude write that same file, and accepts what Neovim did with the conflict

      Closed on the owner's 2026-08-12 delegation. The evidence below was already
      complete: the unsaved buffer kept `MY-UNSAVED-WORK`, `modified` stayed 1, and
      the watcher's own message named the file and the `:e!` escape. Nothing was
      re-run today, and nothing is claimed beyond what that probe measured.

Live evidence, session `edit-bus-trial`, a running `nvim --listen` and `claude -p`:

- The watcher resolved the same log claude writes, without deriving the path:
  `{"active": true, "offset": 0, "log": ".../edit-bus-trial-2ff968978c83bf25.jsonl"}`.
- A restart began at the log's current end. With 2 events already present,
  `offset` was 418 and `touched` was 0, so a Neovim started after the harness
  replays no history.
- An event for a file no buffer held moved `touched` 0 to 1 and `offset` 418 to
  628, and opened no buffer. `autoread` cannot produce a touched set, so this is
  the watcher's own state.
- With the watcher stopped, a further event left `offset` at 209 and `touched` at
  1. Attribution note: the buffer still reloaded, because `--remote-expr` makes
  Neovim process input and run its own `autoread` check. The probe caused the
  reload it was measuring, so reload is not evidence here and `offset`/`touched`
  are.
- The unsaved-work path held. With `MY-UNSAVED-WORK` unsaved in the buffer,
  claude wrote `AGENT-OVERWROTE` to the same file. The buffer kept
  `MY-UNSAVED-WORK`, `modified` stayed 1, and the log carried
  `claude wrote a.txt, which you have unsaved changes in. Your buffer was left
  alone; :e! to take theirs.` That message exists only in the watcher.

3.4 is NOT-RUN, per the decision in `review.md`. 3.6 is the owner's.

## 4. The remaining hook harnesses

- **SHAPE** graph
- **MERGE** 4.6

- [x] 4.1 Establish whether codex exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/codex.nix, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [x] 4.2 Establish whether opencode's plugin surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/opencode/plugins/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [x] 4.3 Establish whether atomic's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/atomic/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [x] 4.4 Establish whether pi's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/pi/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [x] 4.5 Establish whether prime-agent's extension surface exposes a post-edit event carrying a file path, and either wire it or record the capability as false `writes:` modules/home/programs/llm/harnesses/prime-agent/extensions/sysinit-notify.ts, modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [x] 4.6 Reconcile the five findings into one registry state and prove `nix build .#darwinConfigurations.lv426.system` exits 0, with no harness claiming a capability its surface does not have `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` 4.1, 4.2, 4.3, 4.4, 4.5
- [x] 4.7 Adversarial review (`adversarial-review` skill): critics attempt to break the fan-out phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: NOT-RUN, on the same `review.md:75` direction. This phase is the
      one where that costs least: every row of the table below came from running the
      harness against a probe in a scratch home rather than from reading a `.d.ts`,
      and pi is why. Its `on()` accepts any event name and registers a handler that
      never fires, so only a fired event established the surface exists.
- [x] 4.8 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0
- [x] 4.9 Confirm: the owner accepts which harnesses ended up on the bus and which were recorded as incapable, rather than approximated

      Closed on the owner's 2026-08-12 delegation. The state being closed over: five
      harnesses on the bus (claude, opencode, atomic, pi, codex) and one recorded as
      incapable (prime-agent), each verdict from a fired event rather than from
      documentation. The one approximation left is codex, which names no file in any
      structured field and is parsed out of its apply-patch envelope.

Each finding came from running the harness against a probe hook or extension in a
scratch home, on a scratch git repository, with one instruction to write one file.
Reading a shipped `.d.ts` established what to look for; only a firing event
established that it exists, because pi's `on()` accepts any name and registers a
handler that never runs.

| harness | post-edit event | where the path is | verdict |
| --- | --- | --- | --- |
| opencode | `file.edited` | `properties.file`, absolute | true |
| atomic | `tool_result` | `details.resolvedPath`, absolute | true |
| pi | `tool_result` | `input.path`, relative to its cwd | true |
| codex | `PostToolUse` | inside the apply-patch envelope only | true |
| prime-agent | unestablished | nowhere | false |

Notes that the table cannot hold:

- opencode's `file.edited` carries one absolute path and nothing else, and fires
  for every editing tool including `apply_patch`. It is the only surface of the
  five that needs no tool name, no correlation, and no parsing.
- atomic and pi agree on `tool_result`, which carries `toolName`, the `input` that
  produced it, and `isError` in one event. No correlation with `tool_call` is
  needed. Atomic additionally resolves the path itself.
- codex names no file in any structured field. It edits through `apply_patch` and
  passes the envelope as `tool_input.command`, so `--apply-patch` parses the
  `*** Add File:`, `*** Update File:` and `*** Delete File:` markers. An edit codex
  makes through a shell redirect names no file anywhere and records nothing, which
  is the accepted limit of this surface.
- codex runs no hook until its command is trusted, and trust is keyed on the
  hook's position as well as its text. The new entry needs accepting once in an
  interactive codex session before it fires. A probe proved the event itself with
  `--dangerously-bypass-hook-trust`.
- prime-agent has no credentials on this machine, in its own home or a scratch
  one, so `tool_result` could not be made to fire. Its probe extension loaded and
  `session_start` and `session_shutdown` did fire, so the extension surface works
  and only the tool events are unestablished. `false` is what `editBus` documents
  for that state; wiring it on the pi shape would be the approximation this change
  rejects.

Applying the wiring found a defect that review had not, and that predates this
change. All four notify bridges spawned `~/.nix-profile/bin/agent-state` and
friends. That directory holds one binary on this machine, `specutil`; the commands
live in `/etc/profiles/per-user/roshan/bin`. Every spawn failed with ENOENT into
`spawnQuiet`'s empty catch, so the opencode, atomic, pi, and prime-agent notify
bridges have been installed and silently doing nothing. `881d2e6d0` replaces the
hardcoded directory with a PATH lookup, and 4.8 was applied again over that fix.

Live evidence, one file per harness, in its own scratch git repository, read back
from the log the writer names for that workspace:

| harness | tool it chose | event line written |
| --- | --- | --- |
| opencode | patch | `kind":"edit"`, absolute `target.txt`, correct `cwd` |
| pi | edit | `kind":"edit"`, absolute `target.txt`, correct `cwd` |
| atomic | edit | `kind":"edit"`, absolute `target.txt`, correct `cwd` |

opencode reached the file through its patch tool rather than an edit tool, and
`file.edited` still fired. That is the tool-agnostic claim above, confirmed rather
than asserted.

One caveat the probe surfaced and the bus does not own: atomic exits 1 when
`ATOMIC_CODING_AGENT_DIR` is unset, because it then loads pi's extension
directory. The variable is a `home.sessionVariables` entry, and
`hm-session-vars.sh` returns early when `__HM_SESS_VARS_SOURCED` is already set,
so a shell that predates the switch never sees it. A shell started afterwards
does. Nothing to fix here; the probe had to pin the variable explicitly.

4.7 is NOT-RUN, per the decision in `review.md`. 4.9 is the owner's.

## 5. Reviews scoped to the turn

- **SHAPE** graph
- **MERGE** 5.2

- [x] 5.1 Decide whether the declared review plugin can scope a diff to a file list, or whether the diff plugin beneath it must be driven directly `writes:` none `deps:` none

      It cannot, and the diff plugin beneath it can, so the scope comes from below
      and the review layer is attached on top.

      review.nvim exposes nine subcommands and none takes a path. `open()` calls
      `open_codediff_with_revisions(nil, nil)`, whose only parameters are revisions and
      which runs a bare `:CodeDiff`; `open_commits` takes `rev1` and `rev2`. Read at
      `review.nvim/lua/review/init.lua:77-130` and `plugin/review.lua:6-15`.

      codediff.nvim takes git pathspecs as trailing operands after `--`, and keeps
      them across a refresh rather than losing the scope on the first reload:
      `codediff.nvim/lua/codediff/commands.lua:773` declares the trailing arg and
      `:395` carries `pathspec` into the session as "Scope (#74): preserved so refresh
      re-applies it".

      The two are joined by the seam review.nvim uses on itself.
      `review._check_codediff_session()` reads whatever session the current tabpage
      holds and installs the comment hooks and keymaps onto it, so opening codediff
      scoped and then calling that function produces a scoped review without forking
      or vendoring either plugin. It is a private name, so 5.2 degrades to a warning if
      it disappears rather than opening a diff that silently records nothing.
- [x] 5.2 Open a review restricted to the files an agent touched this session, keeping the full working diff reachable and making the narrowed scope visible `writes:` modules/home/programs/neovim/config/lua/harness/, modules/home/programs/neovim/config/lua/plugins/review.lua `deps:` 5.1

      `harness.api.review_touched()`, on `<leader>dR`, beside the unchanged
      `<leader>dr` that reviews everything. The keymap is declared in
      `plugins/review.lua` rather than beside the watcher so lazy loads review.nvim
      before the callback runs; a keymap that fired first would open a plain diff.

      Three things the touched set forced, none of which the proposal anticipated:

      - A path outside the repository cannot be a pathspec, and the set holds them
        because the log is keyed on the directory the agent ran in while each event
        carries an absolute path. They are counted and named in the message, not
        dropped in silence.
      - An empty scope NEVER falls back to the full diff. Both the no-events case and
        the all-outside case say what happened and name `<leader>dr`, because a
        narrowed review that silently widens is the one outcome 5.5 asks the owner to
        be able to trust.
      - The pathspecs are passed as command arguments through `vim.cmd({ cmd = ...,
        args = ... })`, so a path holding a space or a bracket needs no escaping rule
        of its own.

      One defect was written and then found by reading, before any build:
      `_check_codediff_session` returns nothing and returns early when there is no
      session, so the first attach loop pcall'd it and treated "did nothing" as
      success. It now waits for `lifecycle.get_session` to exist and warns after five
      attempts.
- [x] 5.3 Adversarial review (`adversarial-review` skill): critics attempt to break the scoping phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

      Terminal state: NOT-RUN, on the `review.md:75` direction that has governed
      every review gate in this change.

      The deterministic half: `stylua --check` clean, both files parse under
      `loadfile`, `nix flake check` and the darwin build exit 0. What that cannot
      reach is a running editor, so 5.5 is where this phase is actually tested, and
      the one defect found so far came from reading the plugin rather than from any
      gate.
- [x] 5.4 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check` and `nh darwin build` exiting 0

      Pushed as `36448b13e`. `nix flake check` and
      `nix build .#darwinConfigurations.lv426.system` both exited 0 on that tree.
      The switch ran in worker pane 15 and exited 0, after one retry: the first
      attempt failed in `--update` because GitHub answered the tarball fetch with
      HTTP 503, before any evaluation.

      The switch changed nothing: `PATHS 1591 -> 1591`, `DIFF 0 bytes`, same
      `darwin-system` store path in and out. That is correct rather than a failed
      apply. `sysinit-nvim.nix:13` installs the config with
      `mkOutOfStoreSymlink`, and the chain ends at this checkout, so a phase whose
      only artifacts are lua files is live the moment they are written and is
      absent from the system closure. The switch proves the tree still activates;
      it is not what makes the keymap exist.

- [x] 5.5 Confirm: the owner accepts that a scoped review shows the work they meant to review, and that the narrowing is obvious enough to not be mistaken for the whole diff

      Exercised in a live Neovim driven over `--listen`, calling the same function
      `<leader>dR` calls, with `vim.notify` collected so what the owner would read
      is what is quoted here. `maparg` confirms the keymap exists.

      What the three branches did, each from a real touched set rather than a
      constructed one:

      - Only a scratchpad file touched: `all 1 agent edit(s) are outside
        /Users/roshan/github/personal/roshbhatia/sysinit`, ending in the pointer to
        `<leader>dr` for the full diff. No diff opened.
      - `design.md` touched: `review scoped to 1 file(s) an agent wrote`, then the
        same pointer, over an explorer session against
        `36448b13ecf31cfc100d68890d0f30d99cef8b22` holding that file alone.
      - Both: `review scoped to 1 file(s) an agent wrote, 1 outside this repository
        omitted`, so the count the owner sees names what was dropped.
      - `design.md` and `tasks.md`: `review scoped to 2 file(s) an agent wrote`,
        and the explorer's own `pathspec` held exactly those two, against four
        modified files in the working tree.

      The gate found a defect the deterministic half could not, and it was not in
      this change: review.nvim `8e4bc16` cannot attach to codediff `31510a9` at
      all. codediff's explorer session holds `{ absolute, relative }` where
      review.nvim expects a path string, so `set_buffer_filetype` hands a table to
      `vim.filetype.match`, which throws in `normalize_path` and aborts
      `on_session_created` before its augroup and keymaps exist. Plain `:Review`
      failed identically, from review.nvim's own call site at `init.lua:112`, so
      `<leader>dr` has been opening a diff with no comment layer too.

      Fixed in `plugins/review.lua` rather than in the vendored tree, by reading the
      record's `absolute` field. Proved after the fix: the `review_buf_marks`
      augroup exists, and both diff buffers carry the comment keymaps, `i` to add,
      `c` to list, `e` to edit, `d` to delete, `F` for a file comment.

      Two limits worth naming. The watcher resolves its log once at startup from the
      process's working directory, so a Neovim launched outside the repository and
      `:cd`'d in afterwards watches another workspace's log and reports no edits;
      this was found by making that mistake in the harness. And the scope stays a
      floor: the same session's `python3` writes are absent from the log, so the
      full diff remains the only complete view.

## 6. Rollout

- [x] 6.1 Measure an ordinary turn's event count and set the size bound and retained-line count from it, replacing whatever placeholder shipped in phase 1

      Measured from this workspace's own log, `sysinit-90f8d757d2331834.jsonl`:
      52 events naming 18 distinct files over 90 minutes, all from claude, 47
      `edit` and 5 `write`. Lines run 201 to 263 bytes, mean 233. Segmented on a
      two-minute gap the log holds 9 turns of 1, 4, 2, 8, 29, 1, 4, 2, 1 events:
      mean 6, worst 29.

      Set `maxBytes = 512 * 1024` and `keepLines = 200`, replacing 256 KiB and
      500. The bytes bound sets how often a trim happens, about once every 40
      sessions at this rate. The line count sets what a trim costs, and the cost is
      not only the re-read: a reader whose offset is past the shortened file starts
      again at 0 and counts every survivor as touched, so 200 is the smallest
      window that still holds a session's own edits with the worst turn inside it.
      Lowering the retained count from 500 is therefore the substantive half of
      this change, and raising the bytes bound is what keeps it rare.

      The count is a floor, not a census. Every event here came from an edit tool;
      the same session rewrote `worker.go` repeatedly through `python3` heredocs
      and those writes appear nowhere in the log. So the real edit rate is higher
      than 52, and a bound derived from it is generous rather than tight.
- [x] 6.2 Decide whether the poll should now be skipped for a workspace whose harness writes to the bus, or left running for every harness

      Left running for every harness. No code change.

      Three reasons, in order. The bus records tool edits only, proved in 6.1: a
      shell-driven write produces no event, and the poll is the only thing that
      reloads a buffer after one. The poll is already narrow, because
      `session.set_active` starts it only for a harness Neovim itself launched, and
      the common case of a harness in its own WezTerm pane never starts it, so
      there is close to nothing to save. Its cost is one `checktime` a second,
      which does nothing when no buffer changed.

      The shape of the failure decides the rest. Skipping the poll would make the
      reader trust the registry's claim about a writer, and a claim that is wrong
      by one harness reads as buffers silently stopping reloading, which is the
      hardest symptom here to attribute.
- [ ] 6.3 Apply: `openspec archive add-agent-edit-bus`, gated on `specutil check` and `spec-preflight all` exiting 0
