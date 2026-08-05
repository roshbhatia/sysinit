## 1. Sidebar correctness

- **SHAPE** graph

- [x] 1.1 Add `pad` beside the existing `truncate` in
      `extensions/openspec-sidebar/index.ts`, and use it in `SidebarCompositor.paint`
      so each row occupies the full sidebar width. Extend `reset()` with SGR 49 so
      appended padding cannot inherit a run's background (D1)
- [x] 1.2 Replace the `Workspace` panel with `Changes`: add `summaryHeader` beside
      `panelHeader`, drop the branch, ahead, and untracked reads, and test for a
      repository with `git rev-parse --git-dir` rather than a current branch
      `deps:` 1.1
- [x] 1.3 Render one OpenSpec change with a `+N more` count. Pick it by directory
      modification time, and run `openspec status` for that one change only (D2)
      `deps:` 1.1
- [x] 1.4 Remove the `McpServerInfo` interface, `getMcpServers`, `renderMcp`, and the
      `node:fs` and `node:os` imports they were the only users of (D3) `deps:` 1.1
- [x] 1.5 Return zero rows from a panel with nothing to report: an empty subagent
      list and an unavailable `openspec` `deps:` 1.1
- [x] 1.6 Confirm the extension parses: `bun build --target=bun --no-bundle` on the
      file exits 0, and no reference to the removed `state.changes` shape remains
      `deps:` 1.2, 1.3, 1.4, 1.5
- [x] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to break
      the render against the proposal `Behavior` criteria and D1 through D3.
      Adversarial review: waived by owner, on the grounds that the root cause was read
      directly from the paint loop and every artifact in the owner's screenshot maps to
      it `deps:` 1.6

## 2. Footer retirement and package removal

- **SHAPE** graph

- [x] 2.1 Delete `extensions/openspec-status.ts` and its install entry in
      `default.nix`. The sidebar OpenSpec panel carries the same fact
- [x] 2.2 Drop `status-line` and `model-status` from `vendored-extensions.nix`, with a
      comment recording that the sidebar owns the turn count and the model, and that
      `model-status` also wrote an emoji and called `console.log` on every model change
      `deps:` 2.1
- [x] 2.3 Remove `pi-mcp-adapter`, `@benvargas/pi-claude-code-use`, `pi-dcp`, and
      `pi-interview` from `piPackages` and `piPackagePaths`, delete their three lock
      files, and record above the list why each is absent so none returns silently (D8)
- [x] 2.4 Verify no dangling reference: `dcp`, `mcpAdapter`, `piClaudeCodeUse`, and
      `interview` appear nowhere in `default.nix` `deps:` 2.3
- [x] 2.5 Run `nix flake check` and build the four pi checks. All exit 0 `deps:` 2.2,
      2.4
- [x] 2.6 Adversarial review (`adversarial-review` skill): critics attempt to break the
      removals against the proposal `Behavior` criteria and D3 and D8.
      Adversarial review: waived by owner, on the grounds that each removal was
      established by reading what the package reads at runtime against what this
      repository writes `deps:` 2.5

## 3. Diff review chord

- **SHAPE** graph

- [x] 3.1 Add `extensions/diff-review.ts` (follows the extension shape in
      `extensions/openspec-sidebar/index.ts`): `ctrl+b` and `/review` open the
      working-tree diff in a neovim split
- [x] 3.2 Open the split through the multiplexer's own CLI: `wezterm cli split-pane`,
      falling back to `tmux split-window`, and report the command when neither is
      present (D5) `deps:` 3.1
- [x] 3.3 Use `nvim -c CodeDiff`, which opens the whole changeset with its file
      explorer, rather than `git difftool`'s one-pair-at-a-time form (D6) `deps:` 3.1
- [x] 3.4 Narrow `tui.editor.cursorLeft` to `left` in the generated
      `keybindings.json`, so `ctrl+b` is uncontested, and modernize `renameSession` to
      the namespaced `app.session.rename` (D7) `deps:` 3.1
- [x] 3.5 Install it in `customExtensionFiles`, then verify against the built
      `home-manager-files` that the pi extension set is `diff-review.ts` plus the
      vendored files plus `openspec-sidebar`, with none of the three removed
      extensions `deps:` 3.2, 3.3, 3.4
- [x] 3.6 Adversarial review (`adversarial-review` skill): critics attempt to break the
      review path against the proposal `Behavior` criteria and D5 through D7.
      Adversarial review: waived by owner, who redirected the phase to neovim-only
      mid-flight; the hunk half it would have reviewed no longer exists `deps:` 3.5

## 4. hunk removal

- **SHAPE** graph

- [x] 4.1 Remove the `hunk` flake input and its entry in the cache bundle list, then
      regenerate `flake.lock`
- [x] 4.2 Remove the `hunk` overlay entry from `overlays/inputs.nix`, delete
      `modules/home/programs/hunk.nix`, and drop it from
      `modules/home/programs/default.nix` (D8b) `deps:` 4.1
- [x] 4.3 Remove the five `hunk` entries from `llm/lib/allowlist.nix` `deps:` 4.2
- [x] 4.4 Remove `pager.log = false` from `git/default.nix`. It existed only because
      hunk was `core.pager` and its TUI waited for a quit key on `git log` output
      `deps:` 4.2
- [x] 4.5 Verify `hunk` appears in no `.nix` file and no lock file, then confirm
      `nix flake check` and the system build both exit 0 `deps:` 4.3, 4.4
- [x] 4.6 Adversarial review (`adversarial-review` skill): critics attempt to break the
      removal against the proposal `Behavior` criteria and D8b.
      Adversarial review: waived by owner, on the grounds that the removal is a
      grep-decidable absence and the build proves nothing else depended on it
      `deps:` 4.5

## 5. The neovim move

- **SHAPE** graph

- [x] 5.1 Confirm the `~/.config/nvim` clone is safe to move: 176 tracked files, a
      clean status, and an empty `openspec/` with nothing untracked to lose
- [x] 5.2 Copy the tracked files into `modules/home/programs/neovim/config/` with
      `git archive`, dropping `install.sh`, which only cloned the standalone repository
      `deps:` 5.1
- [x] 5.3 Rewrite `neovim/sysinit-nvim.nix` from a clone to a symlink, with the
      target in a new `sysinit.neovim.configPath` option (D9) `deps:` 5.2
- [x] 5.4 Fix the first attempt, which derived that target from `programs.nh.flake`.
      Evaluated on this host it resolved into the sysinit.laurel checkout, which
      carries no module tree from this repository, so activation would have failed on
      the live machine `deps:` 5.3
- [x] 5.5 Make activation refuse, and print the `mv` to run, when `~/.config/nvim` is a
      real directory. It may hold commits that never reached a remote `deps:` 5.3
- [x] 5.6 Confirm the system build exits 0 with the config staged `deps:` 5.5
- [x] 5.7 Adversarial review (`adversarial-review` skill): critics attempt to break the
      move against the proposal `Behavior` criteria and D9; revise until the loop
      reaches a terminal state (see the skill for the scaled round cap) `deps:` 5.6

## 6. The annotation layer

- **SHAPE** graph

- [x] 6.1 Add `runtime/diffnote.sh` (follows `runtime/agent-review.sh`) with hunk's
      `session comment` command surface: `add`, `apply --stdin`, `list`, `clear`,
      `path`. Validate a whole batch before writing, and replace the store atomically
      (D11)
- [x] 6.2 Build it in `runtime/default.nix` and install it in `llm/default.nix`
      `deps:` 6.1
- [x] 6.3 Add `config/lua/harness/diffnote.lua` (follows
      `config/lua/harness/spec_watch.lua`): read the note file, draw one extmark per
      note as virtual lines, clamp a stale line to the last line, and watch the store
      directory so a note lands in an open view (D10) `deps:` 6.1
- [x] 6.4 Call it from the three `CodeDiff` lifecycle hooks in
      `config/lua/plugins/codediff.lua` `deps:` 6.3
- [x] 6.5 Make `ctrl+b` ask pi to annotate after the split opens, naming the
      `diffnote apply --stdin` payload, delivered as a follow-up so it never interrupts
      a running turn (D4) `deps:` 6.2, 6.3
- [x] 6.6 Allowlist the writing and reading forms beside `specutil lock`, and leave
      `diffnote clear` off it, because clearing discards notes the owner may not have
      read `deps:` 6.2
- [x] 6.7 Add `checks/diffnote-roundtrip.nix` (follows
      `checks/agent-sessions-rollup.nix`): assert that the CLI and the editor derive
      the same note path, that both payload shapes are accepted, that a rejected batch
      leaves the store byte-identical, and that rendering places one clamped extmark
      per note. Expose `M.draw` to make the render assertable without the plugin (D12)
      `deps:` 6.4
- [x] 6.8 Mutation test the check. Two mutations caught: shortening the Lua digest to
      15 characters failed the path assertion, and dropping the clamp failed the
      extmark assertion. A third, moving the write before validation, was not run
      because the anchor was not unique; that property is asserted but not
      mutation-verified `deps:` 6.7
- [x] 6.9 Run `nix flake check` and confirm it exits 0, including the new check
      `deps:` 6.8
- [x] 6.10 Adversarial review (`adversarial-review` skill), round 1 of K=2. NOT clean:
      three critics (correctness, ops, security) each returned surviving objections
      with reproductions. Two were upheld by all three: `..` escaped the repository,
      and a failed write zeroed the store into a state that absorbed every later note
      while reporting success. Also fixed: the logical-versus-physical cwd, stop()
      clearing one buffer instead of all, float and leading-zero line numbers, an
      `oldLine`-only comment anchored on the wrong side, escape injection through
      `diffnote list`, a forgeable signature line, no lock between writers, quadratic
      batch cost, a valueless flag exiting with no message, a timer leak, and a root
      cached across repositories. The allowlist tier was wrong and pi does not read
      that file at all `deps:` 6.9
- [x] 6.11 Rewrite the CLI against those objections: lexical `..` and `.` resolution,
      `pwd -P`, publish-only-what-parses, repair a zero-byte store and refuse a
      corrupt one, a lock directory per store, one-pass batch resolution, control-byte
      stripping at the write path (`[[:cntrl:]]`, after measuring that an escaped
      `\uXXXX` range matched the printable bytes instead) `deps:` 6.10
- [x] 6.12 Fix the renderer: clear every buffer drawn into, recompute the repository
      root per refresh, own attribution at the head with no forgeable signature, cap
      one row at three notes, reject a non-integral line, close both handles on a
      failed start, add `VimLeavePre`, and pcall the three CodeDiff hooks `deps:` 6.10
- [x] 6.13 Move the writing forms of `diffnote` to allowlist tierB, keep the reading
      forms in tierA, and record that pi's gate is `@gotgenes/pi-permission-system`
      rather than this file `deps:` 6.10
- [x] 6.14 Extend the check to the holes the review proved: seven rejection cases each
      asserting the store is byte-identical after, zero-byte and corrupt store
      handling, a producer failure mid-write, the symlinked cwd, the per-row cap, the
      `XDG_STATE_HOME` unset and trailing-slash branches, and control-byte stripping
      `deps:` 6.11, 6.12
- [x] 6.15 Mutation test the extended check: ten mutations, ten caught. Two needed the
      check strengthened first, one of which needed a case that drives a real producer
      failure. An eleventh showed the Lua trailing-slash strip was dead code because
      `vim.fs.joinpath` already collapses it, so the code was removed and the property
      pinned from both sides instead `deps:` 6.14
- [x] 6.16 Adversarial review round 2 of K=2, against the revised artifacts, run on
      owner approval at the round boundary. NOT clean: three critics (fix-induced
      regression, correctness, whole-change integration) again returned surviving
      objections. Two were upheld independently by two critics: a control byte in a
      note's PATH reached `diffnote list` and could forge a listing row, and `add`
      accepted a newline there that `apply` refused. The integration critic found that
      the neovim move silently dropped three tracked files, which the machine's own
      ignore rules hid `deps:` 6.15
- [x] 6.17 Track the three dropped files with `git add -f`:
      `config/.luarc.json`, `config/.neoconf.json`, and `config/.gitattributes`. Each
      was matched by this repository's `.gitignore` or the machine's global ignore, so
      `git archive` wrote them and `git add` skipped them. Parity with the old clone
      now verified file by file `deps:` 6.16
- [x] 6.18 Reject control bytes in a path in both entry points, detecting a newline by
      `tr -d` rather than `grep`, which cannot match a line separator (D17). Validate
      the summary after stripping, so a summary of only control bytes cannot land as an
      empty note. Type `author` and `rationale` in `apply`, so it accepts exactly what
      `add` guarantees `deps:` 6.16
- [x] 6.19 Fix the renderer: validate `summary` so one malformed note cannot suppress
      its valid neighbours on a shared row, bound a row in rendered LINES as well as
      note count, make the visible selection stable by insertion order, and redraw
      every drawn buffer on refresh so a REMOVED note disappears `deps:` 6.16
- [x] 6.20 Fix the CLI's exit codes and edges: `clear` on a store-less repository is
      success rather than the failed test's status, the absent-store `list --json`
      carries the same keys as every other path, a symlinked store is refused rather
      than replaced, and the lock trap clears before releasing so a signal cannot
      release a lock this process no longer holds `deps:` 6.16
- [x] 6.21 Read `lastModified`, `completedTasks`, and `totalTasks` from
      `openspec list --json` instead of re-deriving them, which removes the stat
      fan-out and the `tasks.md` read and fixes the panel below the repository root
      (D2) `deps:` 6.16
- [x] 6.22 Align the chord with the sidebar on what "changed" means, and report "not a
      git repository" rather than a clean tree (D16). Name `author` inside the
      `ANNOTATE_PROMPT` payload shape it shows, and state that `line` is on the
      modified side `deps:` 6.16
- [x] 6.23 Fix what the review found in the surrounding work: the activation error
      named `programs.nh.flake` rather than `sysinit.neovim.configPath` and tested the
      directory rather than `init.lua`; the `renameSession` comment claimed a migration
      path the pinned binary does not contain; `checks/lua-parses.nix` had no guard for
      the largest Lua home in the repository; `checks/default.nix` was out of
      alphabetical order; and the moved `README.md` still told the reader to install
      from the repository this change abandons `deps:` 6.16
- [x] 6.24 Extend the check for all of it, then mutation test: ten mutations, ten
      caught, two only after correcting the mutation itself. `nvim_eval` now surfaces
      nvim's stderr, because a Lua error produced empty stdout that read as a failed
      assertion rather than a probe that never ran `deps:` 6.18, 6.19, 6.20, 6.21, 6.22
- [x] 6.25 Round 2 is the K=2 cap. Terminal state CAPPED, with the accepted-and-
      recorded items listed in the design `Risks` and the proposal `Non-goals` rather
      than fixed: lexical symlink resolution, note pruning policy, `printf *` as a
      general allowlist property, author authenticity, a stale lock after SIGKILL, the
      shared watch directory, and two dangling references inside the moved subtree
      (an `nvim-walkthrough` skill that exists nowhere, and `config/bin/nvim-ctl`
      which nothing puts on PATH) `deps:` 6.24

## 7. Rollout

- [x] 7.1 Move: the owner runs `mv ~/.config/nvim ~/.config/nvim.pre-inline`.
      Activation refuses while a real directory is there, and moving rather than
      deleting keeps any commit that never reached a remote
- [x] 7.2 Apply: `nh darwin switch` from the `sysinit.laurel` checkout in a split
      pane, gated on `nix flake check` and
      `nix build .#darwinConfigurations.lv426.system` exiting 0
- [x] 7.3 Confirm: nvim starts from the symlinked path with its plugins loaded, the
      owner reads a live sidebar and judges that it reports what they meant it to
      report, and `ctrl+b` opens a CodeDiff split that shows a note pi wrote
- [x] 7.4 Decide: the owner retired the `sysinit.nvim` remote (archived) and chose
      each unmanaged config's fate. `pi-permission-system/config.json` moved into
      Nix, generated from `allowlist.nix`. `pi-rtk-optimizer/config.json` was
      deleted with its extension: the config held nothing but upstream defaults, and
      the extension rewrote `event.input.command` to `rtk <cmd>` forms that match
      none of the 13 deny globs, which under `yoloMode` auto-approve. `pkgs.rtk` and
      its `doCheck = false` overlay went with it, unreferenced. Still open:
      `~/.config/nvim.pre-inline`, the stale `mcp-cache.json`, and the hand-written
      `pi-openai-fast.json` and `pi-openai-verbosity.json`
