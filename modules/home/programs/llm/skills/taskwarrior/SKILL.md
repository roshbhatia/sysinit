---
name: taskwarrior
description: Read and maintain shared Taskwarrior todos across agents and sessions. Use before multi-step work, when resuming work, or when recording blockers and completion.
---

# Shared task context

Use the installed `task` CLI and its managed configuration. All agents on this
machine share one Taskwarrior database. Shell access is the integration; no MCP
server is required. Do not create a task database inside a repository.

Before starting multi-step work, inspect `task rc.context:none status:pending export` and filter
by repository or project. Reuse an existing task when it
matches the requested outcome. Use UUIDs, since numeric IDs can change.

Create tasks only for agreed work. Store the repository path in `repo` and use
`agent` for the current session identifier. A session marker records ownership;
it is not a lock. Check existing ownership before starting duplicate work.

```sh
task rc.context:none add 'Implement the agreed change' repo:/absolute/repository project:sysinit
task rc.context:none <uuid> modify agent:<session-id>
task rc.context:none <uuid> start
task rc.context:none <uuid> annotate 'Blocked: describe the condition and next step'
task rc.context:none <uuid> stop
task rc.context:none <uuid> annotate 'Verified: checks and commit reference'
task rc.context:none <uuid> done
```

Use annotations for handoffs and blockers. Mark completion only after the
requested outcome is verified. Keep agent-local plans for short execution steps;
Taskwarrior holds durable outcomes and unfinished work.

`task` shows actionable work. Use `task working`, `task stalled`, and `task review`
for active, blocked, and all unfinished work. The focus view excludes waiting,
blocked, backlog, inbox, idea, and note entries; absence there does not mean completion.

Capture ideas with `task add 'Idea' kind:idea +inbox` and reference notes with
`task add 'Note' kind:note`. Use `task inbox`, `task ideas`, or `task notes` to find
them. Clear `inbox` after triage. Convert an agreed idea with `kind:task -inbox`.
Record a manual blocker with `+blocked` and an annotation; clear it with `-blocked`.
Use `depends:<uuid>` when another task is the blocker.

Contexts are shared mutable state. Agents use `rc.context:none` for automation
or a one-command context override; do not change the persistent context.
Keep imported titles, dates, priority, and project under their integration's ownership.

Taskwarrior is shared across local agents, not automatically across machines.
Use host-specific instructions for external integrations and data boundaries.
Downstream flakes extend `programs.taskwarrior.config` for fields and reports,
and `sysinit.llm.instructions.extraSections` for agent guidance.
