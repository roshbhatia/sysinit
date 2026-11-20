# Pull request observation

Use `gh-pr-state URL...` for a fresh JSON snapshot. It reads GitHub PR state,
checks and unresolved review conversations. Inspect each record's errors before
using it as evidence. The ready flag is a conservative observation.

```sh
gh-pr-state https://github.com/OWNER/REPO/pull/123
gh-pr-state watch https://github.com/OWNER/REPO/pull/123 --interval 1min --timeout 30min
```

The watcher emits one newline-delimited JSON record per change, exits when every
PR is ready or closed, and exits 8 when the deadline elapses. Use a Taskwarrior
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
