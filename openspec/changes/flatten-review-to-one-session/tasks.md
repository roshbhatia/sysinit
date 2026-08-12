## 1. The workspace boundary is data

- **SHAPE** graph
- **MERGE** 1.4

- [ ] 1.1 Read the workspace root from the environment, falling back to the cwd when it is unset or names a missing path `deps:` none `writes:` modules/home/programs/neovim/config/lua/utils/gitrepo.lua

- [ ] 1.2 Make the same rule answer in the Go layer, so the repo set and the edit-event log key share one boundary `deps:` none `writes:` pkgs/sysinit-agent/internal/repo/repo.go

- [ ] 1.3 Export the boundary from the shell function that already resolves and enters a session `deps:` none `writes:` modules/home/programs/zsh/integrations/seshy-wezterm.zsh

- [ ] 1.4 Merge: prove the editor and the agent agree in a session directory, a plain directory of repositories, and a subdirectory of one repository `deps:` 1.1, 1.2, 1.3 `writes:` none

- [ ] 1.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 1.4 `writes:` openspec/changes/flatten-review-to-one-session/review.md

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
