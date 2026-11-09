---
name: local-workflows
description: Choose the execution role and compose native helpers, separate harnesses, workspaces, queues, and terminals. Use at multi-step intake and for sy/seshy, Taskwarrior, task-queue/Pueue, zmx, worker, wezspawn, WezTerm, or command/session recovery with Atuin.
---

# Local workflows

A task, checkout, execution attempt, and terminal are separate identities.
Reuse the selected checkout. A bounded delegate returns evidence to its
coordinator without taking over the task or creating a duplicate task.

| Need | Owning command or skill |
| --- | --- |
| Durable work and acceptance evidence | `taskwarrior` |
| Workspace/worktree lifecycle | `sy`; load `feature-based-session-manager` |
| Explicit queued attempt | `task-queue`; read Taskwarrior's queue reference |
| Owner-requested visible pane operation | `ty` or `worker`; load `ty` |
| Prior command or conversation recovery | Atuin; inspect supported search/resume interfaces |

Keep short work in the current session. Native helpers or separate queued
harnesses require the current task's delegation authorization; selecting a
mechanism does not grant it. Use separate checkouts for concurrent writers,
through the workspace owner's lifecycle, and verify integrated results.

Read [execution and terminal details](references/execution-and-terminals.md)
only for queue composition, cross-harness execution, session recovery, visible
terminal work, or shared Codex service diagnosis. It owns command contracts,
context handoff, and terminal boundaries. Do not restart a shared service merely
to resolve uncertainty; preserve active sessions and inspect evidence first.
