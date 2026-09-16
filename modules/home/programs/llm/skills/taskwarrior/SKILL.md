---
name: taskwarrior
description: Read and maintain shared Taskwarrior todos across agents and sessions. Use before multi-step work, when resuming work, or when recording blockers and completion.
---

# Shared task context

Use the installed `task` CLI and its managed configuration. All agents on this
machine share one Taskwarrior database. Shell access is the integration; no MCP
server is required. Do not create a task database inside a repository.

Before starting multi-step work, inspect `task rc.context:none \( +PENDING or +WAITING \) export` and filter
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

For interactive review, run `taskwarrior-tui`. Its initial view uses the actionable
filter. Press `R` to select a report, `/` to filter, `z` for details, and `?` for
help. `taskwarrior-tui -r review` opens all unfinished work. The `c` context menu
changes the shared persistent context; agents must continue to use per-command
overrides. For isolated testing, set `TASKRC` and `TASKDATA` explicitly: existing
environment values take precedence over the TUI's command-line path options.

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

Use `task-context repo` for the current Git repository's actionable tasks.
TUI keys `1` and `2` open the configured source URL and repository directory.
`task-context backup` creates a private export snapshot. Restore with
`task-context restore SNAPSHOT NEW_DIRECTORY`; the destination must not exist.
Snapshots retain tasks, annotations, dependencies, and effective configuration.
They do not retain undo or replica synchronization history. Restores disable hooks
and synchronization settings until explicitly reconfigured.
