## 1. The workspace boundary is data

- **SHAPE** graph
- **MERGE** 1.4

- [x] 1.1 Read the workspace root from the environment, falling back to the cwd when it is unset or names a missing path `deps:` none `writes:` modules/home/programs/neovim/config/lua/utils/gitrepo.lua

      `declared_workspace(dir)` reads `$SYSINIT_WORKSPACE`, expands it, and answers
      only when it is a directory that contains `dir`. The containment rule is what
      keeps the variable a boundary rather than a global override.

      The fallback gained a step the old rule did not have: the git top level of the
      cwd, then the cwd. So an editor opened in `src/` and an agent writing from the
      repository root now resolve the same workspace, and therefore the same
      edit-event log. Memoised per cwd, because the git step spawns a process and
      `workspace()` is read on every roots query, message, and health report.

- [x] 1.2 Make the same rule answer in the Go layer, so the repo set and the edit-event log key share one boundary `deps:` none `writes:` pkgs/sysinit-agent/internal/repo/repo.go

      `repo.DeclaredWorkspace(dir)` is the same three rules in the same order, and
      `repo.Workspace` calls it before `RootAt`. The seshy path rule is gone from
      this file. `paths.SeshySessions` stays where it belongs: `agentstate.identify`
      uses it to name the session for the status line, which is a label, not a
      boundary.

      `TestSeshySessionKeysOneLogForSeveralRepositories` asserted the old mechanism
      and now fails by design, so it was rewritten as
      `TestDeclaredWorkspaceKeysOneLogForSeveralRepositories`: the guarantee is
      unchanged, that two repositories in one workspace write one log, and its source
      is now the declaration. `TestDeclaredWorkspaceAnswersOnlyForWhatItContains`
      covers the three refusals: a directory outside the declaration, a declaration
      naming a missing path, and a declaration naming a file.

- [x] 1.3 Export the boundary from the shell function that already resolves and enters a session `deps:` none `writes:` modules/home/programs/zsh/integrations/seshy-wezterm.zsh

      Set from a `chpwd` hook rather than only from `s()`. A shell can arrive in a
      session three ways, by `cd`, by a multiplexer reattaching, or by a pane opening
      there, and only the hook covers all three. It unsets the variable on leaving,
      which is what makes the containment rule in 1.1 and 1.2 the second line of
      defence rather than the first.

- [x] 1.4 Merge: prove the editor and the agent agree in a session directory, a plain directory of repositories, and a subdirectory of one repository `deps:` 1.1, 1.2, 1.3 `writes:` none

      One fixture, four cases, both ends. A fake session root holding `repoA` and
      `repoB`, a plain directory holding one repository, and a repository with a
      `sub/deep` subdirectory.

      | case | `sysinit-agent workspace health` | `gitrepo.workspace()` | roots |
      | --- | --- | --- | --- |
      | cwd in a declared session's repoA | `sessions/mine` | `sessions/mine` | 2 |
      | plain directory of repositories | `plain` | `plain` | 1 |
      | subdirectory of one repository | `one` | `one` | 1 |
      | declaration names a missing path | `plain` | `plain` | 1 |

      The shell hook was proven in a `zsh -f` sandbox with the paths manifest pointed
      at the fixture: entering `sessions/mine/repoA` set the variable to
      `sessions/mine`, entering the plain directory unset it, and entering the session
      root set it again.

- [x] 1.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 1.4 `writes:` openspec/changes/flatten-review-to-one-session/review.md

      Adversarial review: not run, per the recorded decision. Deterministic lint:
      `stylua --check`, `gofmt -l`, `go vet ./...`, `go test ./...`, and
      `nix flake check` all exit 0.

      The defect this phase actually had was a test that encoded the mechanism rather
      than the guarantee, and `go test` named it in one run. A critic reading the diff
      would have had to notice that a seshy-shaped fixture no longer resolves.

## 2. One session at a time

- **SHAPE** graph
- **MERGE** 2.4

- [x] 2.1 Open one session, for the repository with the most changes, and report the rest as a count rather than as tabs `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      `open_one(group)` closes every open session through `lifecycle.close` and opens
      one, then attaches review.nvim after 200ms. `open_review` calls it for the first
      group and names the rest.

      Closing through `lifecycle` rather than by issuing `:CodeDiff` again says what is
      meant and does not depend on which tab the cursor is in, which the toggle
      behaviour at codediff's entry point does.

      Three-repository fixture: one session, `tab=2`, two tabs, comment layer attached
      with 8 comment keymaps. The 46-repository workspace with 7 dirty: `neph.nvim`
      open, and `Also changed: slice (47), homelab (16), seshy (14), .history (6),
      roshanbhatiadotcom (2), sysinit (1)`.

- [x] 2.2 Swap the open session for another repository's in place, closing the previous one first `deps:` 2.1 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      `M.review_repo(path)` moves the review, reusing the group's own scope so a step
      out of a scoped review and back does not widen to the whole working diff.

      It resolves to the innermost repository containing the path, not the first that
      does. The first version took the first match and went nowhere: the fixture's
      workspace is itself a repository, so it contains `repoA` and `repoB`, and the
      step from `ws` to `ws/repoA` resolved back to `ws`.

      Stepping `ws` to `repoA` to `repoB/f.txt`, measured at each step:

      ```
      OPENED focus=ws         sessions=1 tabs=2 comment_keymaps=8
      STEP1  focus=ws/repoA   sessions=1 tabs=2 comment_keymaps=8
      STEP2  focus=ws/repoB   sessions=1 tabs=2 comment_keymaps=8
      STEP3  focus=ws/repoB   sessions=1 tabs=2   (a path in no repository, refused)
      ```

- [x] 2.3 Delete the machinery the fan-out needed: the tab bound, the chained opens, the session poll, the render wait, the focus re-assertion `deps:` 2.1, 2.2 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      Gone: `MAX_TABS`, `open_next`, `stand_clear`, `await_session`, `await_render`,
      the `rendered` event watcher and its augroup, the 250ms focus re-assertion, and
      the `held`/`missed` bookkeeping the chain needed. `session_tabs` stays, as the one
      reader of codediff's registry, and `has_conflict` stays.

      What replaced them is one function that closes and opens. The tab the owner lands
      in is the tab codediff opened, which is a fact rather than a race.

- [x] 2.4 Merge: prove the landing tab over five consecutive runs in a real pane, and that one diff tab exists at any repository count `deps:` 2.1, 2.2, 2.3 `writes:` none

      Five consecutive reviews of the 46-repository workspace in a real WezTerm pane,
      driven by `nvim -c luafile` rather than by sent keystrokes, because a keystroke
      landed in insert mode and typed the probe into a buffer:

      ```
      run1 focus=neph.nvim sessions=1 tabs=2 wins=8 qf=167
      run2 focus=neph.nvim sessions=1 tabs=2 wins=8 qf=167
      run3 focus=neph.nvim sessions=1 tabs=2 wins=8 qf=167
      run4 focus=neph.nvim sessions=1 tabs=2 wins=8 qf=167
      run5 focus=neph.nvim sessions=1 tabs=2 wins=8 qf=167
      ```

      Identical five times, against 1 of 3 wrong for the fan-out. The first five runs
      of this pass were not identical in one column: the tab count went 2, 3, 4, 5, 6,
      because auto-session saved the diff tab and restored it empty. Fixed at that
      plugin's own seam, `pre_save_cmds` calling `api.review_close()`, since
      autocommands run in registration order and a `VimLeavePre` handler registered by
      a review would run after the save. A normal editing session in the same directory
      still saves, with no `tabnew` in it.

      Buffer cost, counted three ways because the raw handle count misreads it: 173
      handles, 7 loaded, 1 listed, 4 windows, 2 tabs. The 166 unloaded handles are the
      quickfix list's own stubs, one per entry. The fan-out left 24 buffers and 18
      windows.

      Regressions re-run and unchanged: the scoped review, the three degraded paths, the
      no-repository case, the inline default with its toggle, and the conflicted
      repository still opening the merge view with a result pane and 12 accept keymaps.

- [x] 2.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 2.4 `writes:` openspec/changes/flatten-review-to-one-session/review.md

      Adversarial review: not run, per the recorded decision. `stylua --check` over
      `config/lua/` exits 0, and the module loads under `loadfile`.

      Both defects in this phase came from running it: the first-match repository
      resolution, which a reading would have called correct, and the auto-session
      interaction, which is invisible outside a real pane because headless Neovim never
      saves a session.

## 3. The changed files are one list

- **SHAPE** graph
- **MERGE** 3.3

- [x] 3.1 Fill the quickfix list with every changed file under the workspace, absolute, status in the entry text, titled for the review `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      `fill_changed_list(groups, title)` writes one entry per changed file, ordered by
      repository the way the review is, with the repository in the entry text because
      the filename column truncates a long path and the repository is what says which
      diff a step opens.

      The title is the review's own message, so the list says what it is:
      `Harness: reviewing 3 repositories`.

      ```
      LIST   size=3 title=Harness: reviewing 3 repositories
      ENTRY1 [ws] o.txt
      ENTRY2 [repoA] repoA/f.txt
      ENTRY3 [repoB] repoB/f.txt
      ```

      This phase also declared `]q`, `[q`, and `<leader>dq` on the harness plugin,
      which was wrong and 4.1 removed: `after/plugin/lists.lua` had mapped the generic
      versions since 2026-08-09.

- [x] 3.2 Swap the session when the current quickfix entry belongs to a repository other than the open one `deps:` 3.1 `writes:` modules/home/programs/neovim/config/lua/harness/

      `harness/review_follow.lua`, a `BufWinEnter` autocommand, not a wrapper around a
      quickfix command. So `]q`, a picker, `:cdo`, and a plain `:edit` all reach it, and
      the module knows nothing about the quickfix list: the list is one caller, not the
      mechanism.

      Two guards, both from running it. Only a buffer with no `buftype`, since
      codediff's own panes and every plugin buffer have one and following those would
      swap the session for a window the owner did not open. And a 50ms defer, because
      the event fires while codediff is still building its windows.

      `:clast` in the three-repository fixture moved the review from `ws` to `repoB`
      with `sessions=1 tabs=2` unchanged.

- [x] 3.3 Merge: prove the list in one repository and in the forty-six repository workspace, and that `:cdo` acts on it `deps:` 3.1, 3.2 `writes:` none

      One repository: `size=1 title=Harness: reviewing 1 repository`, and `:cfdo`
      visited 1 file. Three repositories: `size=3`, `:cfdo` visited 3, starting at the
      first repository's file. The 46-repository workspace: 167 entries, which is the
      163 changed files the agent reported plus the four that changed while this work
      ran.

      `:cfdo` is the composability claim in one line. It walked every entry with no
      knowledge of the review, and the review needed no knowledge of it.

- [x] 3.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 3.3 `writes:` openspec/changes/flatten-review-to-one-session/review.md

      Adversarial review: not run, per the recorded decision. `stylua --check` over
      `config/lua/` exits 0. The health report gained a line naming which rule produced
      the workspace, declared or inferred, proven in both states against the fixture.

## 4. Rollout

- **SHAPE** sequence

- [x] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in its own pane, gated on the checks in `design.md` `deps:` 1.5, 2.5, 3.4 `writes:` none

      `nix build .#darwinConfigurations.lv426.system` exit 0, then eleven commits
      pushed as `b66cdc326..e0ce7bb6a`, then `sysinit.laurel`'s lock moved
      `21a2cf8` to `e0ce7bb` and `nh darwin switch .` exit 0, `DIFF +1.06 KiB`.

      Two runs failed before that, neither on this change. GitHub's codeload returned
      503 for the tarball, so the lock never moved and the switch rebuilt the old
      revision. Then the Homebrew step aborted: `block-goose` could not upgrade because
      its `/Applications/Goose.app` had been deleted outside Nix. The cask is now
      removed from `modules/darwin/homebrew.nix` at the owner's direction, which is the
      declaration matching the machine rather than the reverse.

      Proven on the installed binary rather than a build output, since the point of
      applying is that the boundary now travels with it:

      | `$SYSINIT_WORKSPACE` | cwd | `workspace=` | roots |
      | --- | --- | --- | --- |
      | `personal/roshbhatia` | `sysinit/modules` | `personal/roshbhatia` | 46 |
      | `~/Downloads` | `sysinit/modules` | `sysinit` | 1 |
      | unset | `sysinit/modules` | `sysinit` | 1 |

      The middle row is the containment rule refusing a declaration that does not
      contain the cwd, on the shipped binary.

      One defect surfaced only here, from reading the live keymap table rather than the
      diff: `after/plugin/lists.lua` has mapped `]q`, `[q`, `]Q`, `[Q`, and
      `<leader>eq` since 2026-08-09, loclist-aware, and `after/plugin` loads after a
      lazy plugin's keys. So 3.1's three keymaps were redundant, two of them shadowed
      and dead. Worse, the generic `]q` steps a list only while its window is open and
      otherwise notifies `No quickfix or location list open`, so the review's own
      message named a step that did nothing. Fixed by deleting the three and opening
      the list from the review, focus returned to the diff:

      ```
      SPAN  qfwin=true  qf=165 wins=7 tabs=2 focus=file   ]q: idx 1 -> 2, no notify
      SOLO  qfwin=false qf=2   wins=6 tabs=2
      CLOSE qfwin=false qf_entries=165   (the window goes, the entries stay)
      ```

      One repository keeps no list window, because codediff's explorer is already that
      index. 3.1's claim that nothing else mapped `]q` was wrong, and only the applied
      config could say so.

- [ ] 4.2 Confirm: the owner runs each entry point on real work and accepts the one-session reading, or names what it costs them `deps:` 4.1 `writes:` none

## 5. What the confirm found

- **SHAPE** graph
- **MERGE** 5.5

The owner ran the entry points on real work in a seshy workspace with a live agent
and named four costs. Three are the surface being wrong rather than the reading:
a key that meant three things, a key that refused on two rows out of three, and
tab and pane rows naming the wrapper holding a pty. The fourth is the reading
itself: the review showed the diff and none of the reasoning, because the notes
only existed when the agent had been told to write them.

- [x] 5.1 File a review note from what the harness already wrote, on the hook that already fires for an edit `deps:` none `writes:` pkgs/sysinit-agent/internal/note/auto.go

      `note auto <harness>` reads a PostToolUse payload, walks the transcript that
      payload names, and files one note. It is a second hook on the matcher
      `agent-edit-event` already uses, wrapped as `agent-note-auto` so git comes from
      the closure rather than from the agent's PATH.

      The rejected option is the one the owner offered first: ask the model to run
      `note add` itself, from an instruction in the hook's output. It was already how
      this worked, and it is what produced the complaint. The instruction competes with
      the task, so notes appear for the edits the model narrates and a review then
      shows three files annotated out of nine, reading as though the other six went
      unexamined. Reading the words the model already wrote needs nothing from the
      model, and cannot be crowded out.

      Three rules keep it honest. The first sentence of the narration is the summary
      and the rest is the rationale, because that is where a harness states what it did
      and then why. The anchor is the patch the tool reported, falling back to locating
      the replacement text in the file. And an author of `claude (auto)` says the note
      was derived, so a reader weighs it differently from one written deliberately.

      No narration means no note: a box that restates the diff is worse than no box.
      Every other failure is silent with exit 0, for the reason `edit-event` is, and
      `--explain` is the one mode that prints the note it would file or the reason it
      would not.

      Proven against this session's own transcript, 21k lines, and in a fixture:

      ```
      --explain, real transcript      line=511 from structuredPatch, summary=first sentence
      --explain, tool_response=string line=100 by locating the text in the file
      empty transcript                writes nothing, exit 0
      file outside a repository       writes nothing, exit 0
      same region twice               1 note; a far region adds a second
      nested repository               note lands in the inner store, outer store empty
      ```

      `go test ./internal/note/` covers all of it, including that a garbage payload,
      an unknown flag, and a missing harness argument each exit 0 and print nothing.

- [x] 5.2 Leave one owner per `<leader>d` sequence `deps:` none `writes:` modules/home/programs/neovim/config/lua/plugins/which-key.lua

      One real conflict, and it was in which-key rather than in a keymap:
      `{ "<leader>dr", group = "Review" }` declared a sequence that is also a mapping,
      so the review read as a prefix waiting for another key with `<leader>dR` sitting
      under it. A group and a mapping cannot share a sequence. The group is gone.

      The rest of the namespace has one owner each, which the config now says by
      grep rather than by memory: `dd` workspace diff, `dr` review, `dR` scoped
      review, `d?` health, `dh` file history, `dH` repository history, `dt` explorer,
      `dq` quit, `dl` layout, and `di`/`dc`/`db`/`dx` for a conflict.

- [x] 5.3 Close what the switcher row names, at the level that row is on `deps:` none `writes:` modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua

      `^x` keyed on the row's `workspace` field, which every row carries, so one key
      meant three things: on a pane row it killed the whole session that pane belonged
      to. It also refused outright on any row of a session with a window open, which is
      most of them.

      It now reads the kind prefix out of the row id, the way `session_tree_dispatch`
      already does, and closes a session's panes, a tab's panes, or one pane. The one
      refusal left is the pane running the selector, at every level: killing it takes
      the selector with it, and the reopen that follows would run against a dead pane.

- [x] 5.4 Name the work in a tab or pane row, not the wrapper holding its pty `deps:` none `writes:` modules/home/programs/wezterm/lua/sysinit/pkg/ui/format.lua

      `zmx` and `caffeinate` hold a pane's pty without doing the work in it, and
      wezterm reports the pane's own foreground process, so every session through
      either read as the wrapper's name. `is_passthrough` is now exported, because
      three renderers see only a name and one of them is handed a table rather than a
      Pane and cannot walk the process tree.

      A pane row's last fallback was the pane's OSC title, which an agent sets to a
      sentence about the session, so the row printed
      `in ✳ Identify explicit steps to launch FRA this week` under a tab of that same
      name. The title is accepted only as a single non-passthrough token now, and the
      switcher omits the segment when it is empty.

- [x] 5.5 Merge: apply, then prove all four on the installed configuration `deps:` 5.1, 5.2, 5.3, 5.4 `writes:` none

      `nix build .#darwinConfigurations.lv426.system` exit 0, six commits pushed as
      `b1e7eb736..eced0bc14`, three `nh darwin switch .` runs from `sysinit.laurel`,
      each exit 0, `DIFF +22.6 KiB` then 0 bytes twice.

      The first build failed and named nothing about this change:
      `internal/note/note.go:92:10: undefined: autoRun`. A flake copies tracked files
      only, and `auto.go` was untracked, so the build compiled a package with a call to
      a function that was not there. `git add` fixed it.

      5.1, end to end, twice, in a three-repository seshy workspace with a live
      `claude` started at the workspace root and told explicitly not to write notes:

      ```
      homelab/README.md:38  I am adding a one-sentence purpose statement to homelab/README.md, because…
      sysinit/README.md:76  I am adding a one-sentence purpose statement to sysinit/README.md, because…
      sysinit/README.md:82  I am adding a one-sentence maintainer line naming @roshbhatia, …
      ```

      Each note reached the store of the repository holding the file, from an agent
      whose own directory was the workspace above both. The author reads
      `claude (auto)`, and the notes render as `[AGENT]` boxes in the inline diff
      alongside an older hand-written note authored `claude`, which is the distinction
      the author field exists to make.

      Two anchor defects surfaced only here, both from the note landing next to the
      change rather than on it. A hunk opens with three lines of context, so
      `newStart` put the note three lines above the edit: 38 where the text was 41.
      Then an append opens with a blank added line, so the first changed line was the
      blank one: 43 where the text was 44. Both are fixed and both are proven on the
      installed binary, the second on a live agent edit that anchored on 82, the line
      it wrote.

      5.2, read from the running editor's keymap table rather than from the diff:
      `d?`, `dH`, `dR`, `dd`, `dh`, `dr`, six mappings, no duplicate, and `dr` is a
      mapping rather than a prefix.

      5.3 and 5.4 are on the machine and evaluate: `wezterm show-keys` renders the
      whole config, `session_tree_actions` included, with no Lua error, and the store
      path `~/.config/wezterm` points at carries both changes. What is not proven here
      is the keypress: `^x` acts inside an InputSelector overlay, which takes input
      from the window rather than from a pane's pty, so `wezterm cli send-text` cannot
      reach it. The same is true of reading a rendered switcher row. Both are the
      owner's to try, which is what 4.2 is for.

- [x] 5.6 Show one index of the changed files, not two `deps:` 5.5 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      The owner saw both at once and said which one to keep: codediff's explorer under
      the diff reading `Changes (2)` and `Staged Changes (0)`, and a quickfix window
      under that listing the same files in a different order. The review no longer
      opens a window for the list.

      Nothing is lost by closing it, which is what 3.1 and 4.1 already built: `]q`
      steps a list with entries whether or not a window shows it, and `<leader>eq`
      opens the window for anyone who wants to read it as a list. So `show_changed_list`
      and the `span_repos` flag that existed only to decide when to call it are both
      gone, and the composability claim is unchanged because it never depended on the
      window.

      ```
      windows  diff h=57, codediff-explorer h=15, no qf window
      ]q       qf=4 idx=2 tabs=2 qfwin=0, review swapped to homelab, 3 notes drawn
      ```

      One measurement lied first. The window was still there after the edit, and the
      loaded module's own traceback named a function the file no longer holds: nvim's
      byte-code cache under `~/.cache/nvim/luac` had served the old compiled chunk
      while `readfile` showed the new source. So a Lua edit is live after a restart
      only once that cache is invalidated, and a probe that reads the file proves
      nothing about the module in memory.

- [x] 5.8 Take each layer out and prove the review still opens `deps:` 5.6 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      Every input the review reads is optional, and until now that was a claim rather
      than a measurement. Five layers can be swapped out under it: `sysinit-agent`,
      `fd`, the note store, review.nvim's attach seam, and codediff's empty-view seam.
      Each was removed on a real fixture in its own WezTerm pane, against a directory
      of six repositories built to be awkward: a clean one, one holding a deleted file,
      an untracked file, a binary, a CRLF file and a file with no trailing newline, a
      repository nested inside it, a second repository whose basename collides with the
      first, and one stopped mid-merge with an unmerged path. Notes were seeded on a
      line 2, a line 9999, and a line carrying a long non-ASCII summary.

      Ten cases on the full configuration, then six more from a clean editor:

      ```
      health, 13 findings, 0 error       every changed file opens, 9 entries stepped
      5 repositories found               clean repository opens Changes (0)
      one session, 1 explorer, 0 qf win  no repository opens nothing
      two notes on a line, one [AGENT ×2] scoped review with no event still opens
      note on line 9999 draws on line 4  three opens in a row, still 2 tabs
      innermost repository owns its note  20-line window, 1 explorer, no error
      colliding basename owns its own     mid-merge, 8 windows, di dc db dx
      close leaves 1 tab, 0 marks
      ```

      One defect, and it was the criterion this change wrote for itself. `open_one`
      opened the empty explorer only when the caller passed `empty`, which only the
      workspace path did. `review_repo` on a clean repository resolved a root the
      change query had never listed, so it reached `:CodeDiff`, which refuses a clean
      repository before it builds anything, and the review said "No changes to show"
      and opened nothing. `has_conflict` is now `repo_state`: one `git status
      --porcelain` answers both whether a path is unmerged and whether anything changed
      at all, so no entry point can reach that refusal by not knowing. It is also one
      git call where there were two.

      With a layer removed, each degraded run opens the review and says what it lost:

      ```
      no sysinit-agent          source=fd scan, 5 roots, 0 notes, review opens
      no sysinit-agent, no fd   source=git rev-parse, 1 root, 0 notes, review opens
      review.nvim seam gone     health error, warns "did not attach", review opens
      codediff seam gone        health error, clean repository falls back to a message
      ```

      The note layer needed a fix to reach that row. `vim.system` raises `ENOENT` for a
      command that is not on PATH rather than returning a non-zero code, and that call
      sits inside the review's open path, so a machine without `sysinit-agent` failed
      the diff itself rather than losing its notes. It is guarded the way every other
      caller in `utils.gitrepo` already guards, and the health report names the binary
      once so a rename is one edit.

      `git` is deliberately not guarded. Nothing in this configuration works without
      it, so a guard there would add a branch that can only be reached on a machine
      where the diff plugin, the sign column and the history keys are all already dead.

      The Claude half is the same question asked of the hook, and the hook does not
      read the agent's PATH: `agent-note-auto` is a `writeShellApplication` that
      prepends its own git and `sysinit-agent` store paths. Run with
      `env -i PATH=/usr/bin:/bin`, seven malformed payloads each exit 0, print nothing,
      and leave the note count unchanged: empty stdin, text that is not JSON, JSON with
      no fields, a transcript path that does not exist, a transcript that is not JSONL,
      a file in no repository, and a tool it does not handle.

      One interactive step is left, and it is codediff's own guard rather than
      something to fix here. Opening a merge result marks its buffer modified before
      the owner accepts anything, so a review that stepped through an unmerged file
      asks `(D)iscard, [C]ancel` on close. It blocks Neovim's main loop, which is worth
      knowing when driving the review from a script: the first run of this suite read
      two later cases as failures that were only the loop waiting for a key.

- [x] 5.9 Let `^x` close the session it is pressed in, and step between sessions with `^[` and `^]` `deps:` 5.3 `writes:` modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua

      The owner pressed `^x` on the row of the session they were sitting in and it
      refused. 5.3 had reduced that refusal from three levels to one, and one was
      still one too many: the row named a session, and the answer was to leave it.

      Refusing was the wrong answer to a real problem. Closing every pane of the
      current workspace leaves the window with nothing to show, and killing the
      selector's own pane leaves the reopen running against a dead pane. Both are now
      answered before the kill rather than avoided by it. The window moves to
      `default` first when the close would empty the workspace it is showing, and the
      selector reopens only when its own pane survived and the window did not move.

      `default` is never closed, only reset to one pane, from any session. It is
      where every other close falls back to, so closing it outright is the one close
      that can leave a window with nowhere to go. The pane kept is the selector's own
      when the selector is running in it.

      The decision is now a pure function of the pane list, `M.close_plan`, separate
      from the killing, because the edge cases are all in the decision and none of
      them are in the two `wezterm cli` calls. Driven under the `chordcheck` stub,
      31 assertions over a five-pane fixture:

      ```
      another session      targets it, no move, reopens
      own session          targets all 3, moves to default, no reopen
      default, 1 pane      refuses, nothing closed
      default, 3 panes     keeps the selector's own, resets, reopens
      default from work    keeps the first, resets, reopens
      own tab, own pane    closed, no reopen
      last tab, last pane  moves to default, no reopen
      dormant row          refuses, names the row
      ```

      `^[` and `^]` step back and forward through the plugin's own cycle order, which
      is the order the switcher lists and which saves the workspace it leaves. Both
      were stripped in June for a stated reason: `^[` is how a terminal sends ESC, so
      binding it means a pane never sees that keypress again. The owner asked for them
      back knowing the cost. Locked mode is the way back to ESC, and is why these are
      callbacks rather than the plugin's actions bound directly.

      `wezterm show-keys` against the edited tree renders 219 lines with no Lua error,
      `CTRL [` and `CTRL ]` among them, and `nix build .#darwinConfigurations.lv426.system`
      exits 0. What is still not proven here is the keypress itself, for the reason
      5.5 gives: an InputSelector takes input from the window rather than from a
      pane's pty.

      The 31 assertions are not in the repository. There is no Lua test runner in
      `hack/lint.sh` to hold them, and adding one is a change of its own.

- [ ] 5.7 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 5.5, 5.6, 5.8, 5.9 `writes:` openspec/changes/flatten-review-to-one-session/review.md
