---
name: local-workflows
description: Choose sysinit commands for PR state or closure, checkpoint patches, remote shell or WezTerm attach, and durable task intake.
---

# Local workflows

A task, checkout, execution attempt, and terminal are separate identities.
Reuse the selected checkout. A bounded delegate returns evidence to its
coordinator without taking over the task or creating a duplicate task.

| Need | Owning command or skill |
| --- | --- |
| Durable work and acceptance evidence | `taskwarrior` |
| Workspace/worktree lifecycle | `sy`; load `workspace-manage` |
| Explicit queued attempt | `task-queue`; read Taskwarrior's queue reference |
| Owner-requested visible pane operation | `ty` or `worker`; load `terminal-wezterm` |
| PR head, CI, and unresolved conversations | `gh-pr-state URL`; to follow closure or merge, use `gh-pr-state watch URL --until closed` |
| Changes since a review checkpoint | `review-checkpoint diff`; pipe to `hunk patch` for an interactive patch reader |
| Preview a normal remote shell | `tsh --dry-run HOST` |
| Preview a native WezTerm mux attach | `tether attach --dry-run HOST` |
| Prior command or conversation recovery | Atuin; inspect supported search/resume interfaces |

Keep short work in the current session. Native helpers or separate queued
harnesses require the current task's delegation authorization; selecting a
mechanism does not grant it. Use separate checkouts for concurrent writers,
through the workspace owner's lifecycle, and verify integrated results.

Queue a command for durable PR observation. Use an agent when its independent
judgment or execution adds something to the result.

For harness-specific work, verify the current session's tools and
permissions. Use a native helper for authorized independent reading when
that keeps unrelated context out of the main session. Use a direct
command for deterministic checks or observations. A fresh context still
shares the checkout unless the workspace owner creates a separate one.

Read [review and PR details](references/pull-requests.md) for PR queries,
watch outcomes, and review surfaces. Read the
[remote access route](references/execution-and-terminals.md#remote-access)
before connecting.

Read [execution and terminal details](references/execution-and-terminals.md)
only for queue composition, cross-harness execution, session recovery, visible
terminal work, or shared Codex service diagnosis. It owns command contracts,
context handoff, and terminal boundaries. Do not restart a shared service merely
to resolve uncertainty; preserve active sessions and inspect evidence first.
