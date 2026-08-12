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

- [ ] 2.1 Open one session, for the repository with the most changes, and report the rest as a count rather than as tabs `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

- [ ] 2.2 Swap the open session for another repository's in place, closing the previous one first `deps:` 2.1 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

- [ ] 2.3 Delete the machinery the fan-out needed: the tab bound, the chained opens, the session poll, the render wait, the focus re-assertion `deps:` 2.1, 2.2 `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

- [ ] 2.4 Merge: prove the landing tab over five consecutive runs in a real pane, and that one diff tab exists at any repository count `deps:` 2.1, 2.2, 2.3 `writes:` none

- [ ] 2.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 2.4 `writes:` openspec/changes/flatten-review-to-one-session/review.md

## 3. The changed files are one list

- **SHAPE** graph
- **MERGE** 3.3

- [ ] 3.1 Fill the quickfix list with every changed file under the workspace, absolute, status in the entry text, titled for the review `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

- [ ] 3.2 Swap the session when the current quickfix entry belongs to a repository other than the open one `deps:` 3.1 `writes:` modules/home/programs/neovim/config/lua/harness/

- [ ] 3.3 Merge: prove the list in one repository and in the forty-six repository workspace, and that `:cdo` acts on it `deps:` 3.1, 3.2 `writes:` none

- [ ] 3.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 3.3 `writes:` openspec/changes/flatten-review-to-one-session/review.md

## 4. Rollout

- **SHAPE** sequence

- [ ] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in its own pane, gated on the checks in `design.md` `deps:` 1.5, 2.5, 3.4 `writes:` none

- [ ] 4.2 Confirm: the owner runs each entry point on real work and accepts the one-session reading, or names what it costs them `deps:` 4.1 `writes:` none
