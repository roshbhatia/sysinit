> **Closed with 1 tasks unfinished, by owner decision on 2026-08-06.**
> The substance of this change is applied and running; what remained was review
> ceremony and owner-confirmation gates the owner chose not to run. Archived
> rather than deleted so the record of what was built survives. The unchecked
> boxes below are accurate: they were dropped, not completed.

## 1. The readiness report

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.agent-review-readiness` exits 0, and
  each of its cases fails when the behaviour it covers is disabled. It agreeing
  with `git status` is not sufficient: a report can match `git status` in every
  repository and still exit 0 on commits reachable from no other ref, which is the
  state that actually loses work
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
- [x] 1.7 Adversarial review (`adversarial-review` skill), rounds 1 and 2 of K=2.
      Terminal state CAPPED with zero surviving objections: ten defects found
      across two rounds, all closed and mutation tested, but no round returned
      clean on its first pass, so this is not reported as a clean review. One
      defect was caused by a round-1 fix. The round-2 finding that mattered:
      commits reachable from no other ref exited 0, and the new predicate found
      real work at risk in two live sessions `deps:` 1.6
- [x] 1.8 Both assertions do catch their mutation. The earlier negative result was
      a bad method: deleting a line leaves its variable unused, shellcheck fails the
      `agent-review` package build, and the check derivation never runs, so a
      dependency failure reads as zero assertion failures. A mutation must be
      shellcheck-clean to test an assertion at all. Confirmed with
      `[ "$detached" -eq 999 ]` and a session-key comparison that keeps both
      variables referenced: one and two assertions fire respectively `deps:` 1.7
- [x] 1.9 A paused rebase, merge, cherry-pick, revert, or bisect now blocks and
      is named. The sequencer state lives in the gitdir, where
      `status --porcelain` reports nothing, so a stopped rebase read as clean and
      deleting the worktree would have discarded every commit it had applied.
      Fixtures cover a paused rebase and a conflicted merge; mutation tested
      `deps:` 1.7
- [x] 1.10 A configured upstream that no longer resolves now blocks as
      `upstream gone` instead of taking the benign no-upstream carve-out.
      `branch.<n>.merge` being set distinguishes it from the seshy default the
      carve-out was written for. Global `fetch.prune` makes this routine after a
      merge-and-delete, and the local commits may exist nowhere else
      `deps:` 1.7
- [x] 1.11 Discovery accepts a repository root only: `rev-parse --show-toplevel`
      must equal the directory. `--git-dir` walks upward, so running the report
      from a repo root previously reported every top-level directory as its own
      repository carrying the same dirty count `deps:` 1.7
- [x] 1.15 Both round-2 objections closed. A linked-worktree fixture now covers
      the shape seshy actually creates: discovery, a local-only commit, a paused
      rebase whose markers live under the worktree gitdir, and a dirty tree.
      Mutation tested: breaking relative marker resolution fails the standalone
      cases and leaves the worktree ones green, so the two exercise different code
      paths. The spec now carries the reachability scenario, so it no longer
      authorises the exit 0 that lost work `deps:` 1.7
- [x] 1.12 Verify: `nix flake check` and `nh darwin build` are green; the report
      was exercised against fixture repositories covering clean, dirty,
      unpushed, no-upstream, bad-path, and all-clean, with the right exit code
      in every case
- [x] 1.13 Apply: `nh darwin switch`
- [x] 1.14 Confirm: verified against a real `sy new` session. The report named
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

- [x] 3.1 Verify: `openspec validate agent-session-review-path` reports valid and
      `specutil check` passes for every change
- [x] 3.2 Verify: `nix fmt -- --check` is clean, after formatting
      `overlays/meat.nix`; `nix flake check` reports no failure
- [x] 3.3 Apply: staged and committed across the session, one concern per commit,
      per the standing instruction to commit and push as needed
- [ ] 3.4 Confirm: the owner reviews the landed work. This is the judgment the
      rollout exists for: the change altered a gate that deletes sessions, and the
      report now refuses two live sessions it previously called ready
