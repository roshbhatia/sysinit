''
  ---
  name: beads-workflow
  description: Use when tracking tasks, managing issues, breaking down features into work items, or doing multi-step implementation work that needs persistent state across sessions
  ---

  # Beads Workflow

  ## Overview

  Beads (`bd`) is a distributed, git-backed graph issue tracker designed for AI agents. It provides persistent, structured memory for coding agents, replacing ad-hoc markdown plans with a dependency-aware task graph.

  ## When to Use

  - Multi-step feature implementation
  - Bug tracking across sessions
  - Task breakdown from PRDs
  - Any work that spans multiple commits or sessions
  - Coordinating parallel work streams

  ## When NOT to Use

  - Single-file, single-commit changes
  - Quick formatting fixes
  - Simple questions or exploration
  - Use TodoWrite for ephemeral in-session task tracking that does not need persistence

  ## Essential Commands

  | Command | Action |
  |---------|--------|
  | `bd init` | Initialize beads in current project |
  | `bd ready` | List tasks with no open blockers |
  | `bd create "Title" -p 0` | Create a P0 (highest priority) task |
  | `bd create "Title" -p 1` | Create a P1 task |
  | `bd update <id> --claim` | Atomically claim a task (sets assignee + in_progress) |
  | `bd update <id> --status done` | Mark task complete |
  | `bd dep add <id> <blocker-id>` | Add dependency (blocker blocks id) |
  | `bd show <id>` | View task details and audit trail |
  | `bd list` | List all tasks |
  | `bd sync` | Sync beads state with git |

  ## Task Hierarchy

  Beads supports hierarchical IDs for epics and subtasks:

  - `bd-a3f8` -- Epic
  - `bd-a3f8.1` -- Task under epic
  - `bd-a3f8.1.1` -- Sub-task

  ## Workflow Integration

  1. Break PRD into atomic tasks with `bd create`
  2. Add dependencies with `bd dep add`
  3. Check what is ready with `bd ready`
  4. Claim a task with `bd update <id> --claim`
  5. Implement, verify, get sign-off
  6. Mark done with `bd update <id> --status done`
  7. Repeat from step 3

  ## MCP Integration

  Beads is available as an MCP server (`beads-mcp`) for tools that support it. The MCP server runs via `uvx --isolated --with packaging beads-mcp`.

  ## Session End

  Always run `bd sync` before pushing to ensure beads state is committed:

  ```bash
  git pull --rebase
  bd sync
  git push
  ```

  ## Critical Rules

  - Execute tasks sequentially (one at a time), even if parallelization seems possible
  - Do NOT start a new task until the current task is verified and signed off
  - Do NOT mark a task as complete until the user explicitly signs off
  - Use `bd ready` to determine next task, not your own judgment about priority
''
