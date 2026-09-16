---
name: taskwarrior
description: Read and maintain shared Taskwarrior todos across agents and sessions. Use before multi-step work, when resuming work, or when recording blockers and completion.
---

# Shared task context

Use the installed `task` CLI and its managed configuration. All agents on this
machine share one Taskwarrior database. Shell access is the integration; no MCP
server is required. Do not create a task database inside a repository.

Before starting multi-step work, inspect `task status:pending export` and filter
by repository or project. Reuse an existing task when it
matches the requested outcome. Use UUIDs, since numeric IDs can change.

Create tasks only for agreed work. Store the repository path in `repo` and use
`agent` for the current session identifier. A session marker records ownership;
it is not a lock. Check existing ownership before starting duplicate work.

```sh
task add 'Implement the agreed change' repo:/absolute/repository project:sysinit
task <uuid> modify agent:<session-id>
task <uuid> start
task <uuid> annotate 'Blocked: describe the condition and next step'
task <uuid> stop
task <uuid> annotate 'Verified: checks and commit reference'
task <uuid> done
```

Use annotations for handoffs and blockers. Mark completion only after the
requested outcome is verified. Keep agent-local plans for short execution steps;
Taskwarrior holds durable outcomes and unfinished work.

Taskwarrior is shared across local agents, not automatically across machines.
Use host-specific instructions for external integrations and data boundaries.
Downstream flakes extend `programs.taskwarrior.config` for fields and reports,
and `sysinit.llm.instructions.extraSections` for agent guidance.
