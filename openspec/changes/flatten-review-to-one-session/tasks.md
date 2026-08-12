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

      `]q`, `[q`, and `<leader>dq` are declared on the harness plugin, which is not
      lazy. Nothing in this config mapped them before, so the message that says to step
      with `]q` was not true until they existed.

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

- [ ] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in its own pane, gated on the checks in `design.md` `deps:` 1.5, 2.5, 3.4 `writes:` none

- [ ] 4.2 Confirm: the owner runs each entry point on real work and accepts the one-session reading, or names what it costs them `deps:` 4.1 `writes:` none
