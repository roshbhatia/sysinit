# Review and pull request observation

## Choose a review surface

- For the current checkout, use `git diff` or `git diff --cached` for changes
  relative to the index or HEAD. For changes since an existing review
  checkpoint, use `review-checkpoint diff`. The patch can be piped to
  `hunk patch` when the user wants an interactive reader.
- For a live Neovim working-tree split, load `agent-diff` and target the
  current checkout and intended WezTerm pane.
- For a GitHub PR patch, use `gh pr diff URL`. To open an interactive PR
  review, use `gh-pr-diff URL`, which opens Atlas inside Neovim.

## Observe a pull request

Use `gh-pr-state URL...` for a fresh JSON snapshot. It reads GitHub PR state,
checks and unresolved review conversations. Inspect each record's errors before
using it as evidence. The ready flag is a conservative observation.

```sh
gh-pr-state https://github.com/OWNER/REPO/pull/123
gh-pr-state watch https://github.com/OWNER/REPO/pull/123 --until ready
gh-pr-state watch https://github.com/OWNER/REPO/pull/123 --until closed --interval 1min --timeout 30min
```

Hand off the canonical URL and the requested outcome. Use the snapshot for
an immediate answer, `watch --until ready` for readiness, or
`watch --until closed` for a merge or closure. The watcher emits one
newline-delimited JSON record per change and exits 8 when the deadline elapses.
Report the final observed state and head, including whether a closed PR merged.
Use a Taskwarrior
UUID for the outcome and an explicit queued attempt if the wait must survive the
session. Use `tq status` and the corresponding Pueue job log on resume.

```sh
tq submit --task UUID -- gh-pr-state watch https://github.com/OWNER/REPO/pull/123
```

To follow only required CI, use `gh pr checks --required --watch`. When
`gh event` is available and the account has preview access, its events can
trigger a snapshot. Read current state when attaching or reconnecting, since
missed events are not replayed.

Before an authorized merge, verify the head, required checks, any named
reviewer's approval, unresolved conversations, and repository policy. Use
`gh pr merge --match-head-commit` on ordinary PRs and the stack workflow on
stacked PRs. Observe the merge and any expected deployment separately.
