## 1. The readiness report

- **SHAPE** loop
- **STOP** `agent-review` matches `git status` in every repository of a real
  session and exits non-zero only when something is unfinished
- **MAX-ITERS** 4

- [x] 1.1 Spike result: seshy passes hook environment variables, confirmed by a
      string scan of the installed binary: `SESHY_EVENT`, `SESHY_SESSION`,
      `SESHY_SESSION_PATH`, `SESHY_REPOS`, `SESHY_REPO_COUNT`
- [x] 1.2 Author `config/agent-review.sh` reporting per repository the branch,
      the uncommitted file count, and the unpushed commit count (follows the
      state-file read in `config/agent-focus.sh`)
- [x] 1.3 Treat a branch with no upstream as "no upstream", never as zero
      unpushed commits
- [x] 1.4 Add the agent-state check, intersecting state files with the live pane
      set and skipping the input entirely when that set is unknown
- [x] 1.5 Build it through `notify.nix` so it shares the identity resolver, and
      install it on PATH
- [x] 1.6 Add the `agent-review-readiness` flake check: fixture repositories for
      ready, dirty, unpushed, no-upstream, a state file with no live pane set, a
      path that is not a directory, and a directory holding no repository. Every
      case asserts the exit code, because that code is what `sy delete` gates on.
      Mutation tested against five defects, each caught by its own assertion and
      not by a dependency failure: always-ready, ignore-dirty, ignore-unpushed,
      dropping the no-upstream note, and a bad path returning success
- [ ] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until the loop reaches
      a terminal state
- [x] 1.8 Verify: `nix flake check` and `nh darwin build` are green; the report
      was exercised against fixture repositories covering clean, dirty,
      unpushed, no-upstream, bad-path, and all-clean, with the right exit code
      in every case
- [x] 1.9 Apply: `nh darwin switch`
- [x] 1.10 Confirm: verified against a real `sy new` session. The report named
      the branch `dev/rshnbhatia/review-probe/sysinit` and `no upstream`, which
      matched `git status` and `rev-parse` exactly

## 2. The archive gate

- **SHAPE** graph
- [x] 2.1 Gate `sy delete` in the zsh `sy` wrapper, not in seshy's `preDelete`
      hook. Testing showed seshy runs that hook advisorily: a non-zero exit logs
      a warning and deletes anyway, with or without `--force` `deps: none`
- [x] 2.2 Make the gate permissive when the report cannot run, so a session can
      never become undeletable `deps: 2.1`
- [x] 2.3 Name `--force` in the refusal message itself `deps: 2.1`
- [x] 2.4 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until the loop reaches
      a terminal state `deps: 2.2,2.3`
- [x] 2.5 Verify: `nix flake check` and `nh darwin build` are green; review the
      diff `deps: 2.4`
- [x] 2.6 Apply: `nh darwin switch` `deps: 2.5`
- [x] 2.7 Confirm: all four paths verified in real WezTerm panes. Unfinished
      refuses and the session survives; `--force` deletes; a clean, pushed
      session reports ready and deletes; a bad path exits 2 and is permissive
      `deps: 2.6`

## 3. Rollout

- [ ] 3.1 Verify: `openspec validate agent-session-review-path` passes and
      `specutil check` reports no finding
- [ ] 3.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed
- [ ] 3.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill
- [ ] 3.4 Confirm: the owner approves the staged diff before any commit
