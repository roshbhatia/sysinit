---
name: taskwarrior
description: Track shared Taskwarrior work and submit explicit agent executions through task-queue and Pueue. Use at task intake, when resuming work, or when recording blockers and completion.
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

## Submit agent work

Use `local-workflows` to distinguish native helpers from separate harness runs.
Native helpers use their harness's API and return results to their coordinator;
they do not need a Pueue attempt for every delegated question.

At task intake, consider queued execution for agreed work that benefits from a
separate harness process, scheduling, or an attachable terminal. Continue work already owned
by the current session here unless a separate execution is useful. A queue is an
execution mechanism; it does not expand authorization or approve external actions.

When installed, `task-queue` records explicit attempts and runs them through Pueue.
Use it instead of a direct `pueue add` for Taskwarrior-linked work. The task must be
pending, unblocked, and have completed dependencies. The queue rechecks this when
execution starts. It rejects duplicate attempts and concurrent task-linked runs
in the same working directory.

1. Read `taskwarrior rc.context:none <uuid> info` and `task-queue status`. Check
   ownership, prior attempts, dependencies, repository, and annotations.
2. Prepare a bounded prompt containing the full UUID, description, relevant
   project and annotations, repository, exact authorization, acceptance criteria,
   and verification requirements. Save it outside disposable temporary storage
   when the attempt must survive a restart. Do not embed credentials.
3. Choose an installed harness and an existing working directory or seshy session.
   Use that harness's supported noninteractive command. Verify flags with `--help`
   when uncertain; do not copy interactive aliases or add permission bypasses.
4. Submit explicit arguments. `--task` uses the task's `repo` by default;
   `--cwd` overrides it and `--session` resolves an existing seshy workspace.
   Choose one of the examples below, not all three for the same task.

```sh
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  goose run --instructions /absolute/task-prompt.md
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  claude --print 'Read /absolute/task-prompt.md and carry out its authorized task.'
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  codex exec 'Read /absolute/task-prompt.md and carry out its authorized task.'
```

Other installed harnesses use the same queue with their own explicit command.
Add `--terminal` before `--` for an attachable zmx session. Queue output includes
the attempt UUID and Pueue job ID; retain both with the Taskwarrior UUID. A
Taskwarrior session ownership marker remains coordination metadata, not a lock.

Inspect `task-queue status`, `pueue status`, and `pueue log <job-id>`. Use
`task-queue cancel <attempt-uuid>` for cancellation and
`task-queue resume <attempt-uuid>` for an interrupted submission. After a completed
attempt, inspect its result before submitting a new one with `--retry`.

Successful execution sets `review: true` in the attempt record and leaves the
Taskwarrior task pending. Inspect the actual diff, artifacts, and checks; record
verified completion through the task's owning workflow. Imported Linear tasks
still require their authorized Linear completion workflow followed by sync.

`taskwarrior` shows actionable work. Use `taskwarrior working`, `taskwarrior stalled`, and `taskwarrior review`
for active, blocked, and all unfinished work. The focus view excludes waiting,
blocked, backlog, inbox, idea, and note entries; absence there does not mean completion.

For interactive review, run `taskwarrior-tui`. Its initial view uses the actionable
filter. Press `R` to select a report, `/` to filter, `z` for details, and `?` for
help. `taskwarrior-tui -r review` opens all unfinished work. The `c` context menu
changes the shared persistent context; agents must continue to use per-command
overrides. For isolated testing, set `TASKRC` and `TASKDATA` explicitly: existing
environment values take precedence over the TUI's command-line path options.

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
