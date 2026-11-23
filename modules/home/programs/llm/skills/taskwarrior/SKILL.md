---
name: taskwarrior
description: Track shared Taskwarrior work and submit or inspect durable commands or agent runs through task-queue and Pueue. Use for work linked to a task UUID that must outlive the current shell, at durable task intake, or when recording blockers and completion.
---

# Shared task context

`task` runs Go Task (Taskfile). Use `taskwarrior` for todos.

Use the installed `taskwarrior` CLI and its managed configuration. All agents on this
machine share one Taskwarrior database. Shell access is the integration; no MCP
server is required. Do not create a task database inside a repository.

Before owning or resuming multi-step work, inspect `taskwarrior rc.context:none \( +PENDING or +WAITING \) export` and filter
by repository or project. Reuse an existing task when it
matches the requested outcome. Use UUIDs, since numeric IDs can change.

As a bounded delegate, use the coordinator's supplied UUID, scope, and relevant
annotations. Return evidence to that coordinator. Ask it for missing task context
when needed; do not create a duplicate task or mark the parent's task complete.

Create tasks only for agreed work. Store the repository path in `repo` and use
`agent` for the current session identifier. A session marker records ownership;
it is not a lock. Check existing ownership before starting duplicate work.

```sh
taskwarrior rc.context:none add 'Implement the agreed change' repo:/absolute/repository project:sysinit
taskwarrior rc.context:none <uuid> modify agent:<session-id>
taskwarrior rc.context:none <uuid> start
taskwarrior rc.context:none <uuid> annotate 'Blocked: describe the condition and next step'
taskwarrior rc.context:none <uuid> stop
taskwarrior rc.context:none <uuid> annotate 'Verified: checks and commit reference'
taskwarrior rc.context:none <uuid> done
```

Use annotations for handoffs and blockers. Mark completion only after the
requested outcome is verified. Keep agent-local plans for short execution steps;
Taskwarrior holds durable outcomes and unfinished work.

## Queued execution

Keep work in this session unless a separate attempt is useful and authorized.
Submit a task-linked command with `task-queue submit --task <uuid> --cwd <checkout> -- <command> [args...]`.
Retain the returned attempt ID and find it in `task-queue status`.
Before submitting, resuming, retrying, or cancelling `task-queue` work, read
[queued execution](references/queued-execution.md). Inspect existing attempts;
a successful queued command still requires result verification.

`taskwarrior` shows actionable work. Use `taskwarrior working`, `taskwarrior stalled`, and `taskwarrior review`
for active, blocked, and all unfinished work. The focus view excludes waiting,
blocked, backlog, inbox, idea, and note entries; absence there does not mean completion.

For interactive review, run `taskwarrior-tui`. Its initial view uses the actionable
filter. Press `R` to select a report, `/` to filter, `z` for details, and `?` for
help. `taskwarrior-tui -r review` opens all unfinished work. The `c` context menu
changes the shared persistent context; agents must continue to use per-command
overrides. For isolated testing, set `TASKRC` and `TASKDATA` explicitly: existing
environment values take precedence over the TUI's command-line path options.

Use `task-board` for the Kanban view or `task-board --json` for its projection.
The board links tasks to queue attempts and agent workspaces by UUID. Use
`--context`, `--repo`, or `--project` to set a view without changing the
shared context. Use `f` to open the selected task's review in the configured
terminal. Enter opens the full handoff and `a` records a new annotation.
Use `+review` to mark a task ready for human review after recording the
result and checks. Use `-review` when work resumes. A successful queue exit
leaves the task in its existing lane.

When a decision blocks progress, annotate the task with the specific question,
exact workspace, what changed, checks run, and the next step. Link a local
handoff file from the annotation if more context is needed. Then set
`+blocked -review`, stop the task, and let a queued attempt exit. Record the
answer on the same UUID before clearing the blocker. Continue explicitly in
the same workspace. A fresh harness can read the annotations and inspect the
workspace before making changes.

Capture ideas with `taskwarrior add 'Idea' kind:idea +inbox` and reference notes with
`taskwarrior add 'Note' kind:note`. Use `taskwarrior inbox`, `taskwarrior ideas`, or `taskwarrior notes` to find
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
