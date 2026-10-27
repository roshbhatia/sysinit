---
name: local-workflows
description: Choose the execution role and compose native helpers, separate harnesses, workspaces, queues, and terminals. Use at multi-step intake and for sy/seshy, Taskwarrior, task-queue/Pueue, zmx, worker, wezspawn, or WezTerm operations.
---

# Local workflows

Keep task UUIDs and selected checkouts explicit across existing commands. A task,
workspace, execution attempt, and terminal pane describe different things.

## Choose the execution role

First identify the current harness's actual tools and the assignment's scope.
A bounded delegate carries out its assigned work and returns evidence to its
coordinator. It does not take over the parent task, mark that task complete, or
start a new orchestration tree unless its assignment covers that responsibility.

A coordinator owns integration and verification. Choose the execution mode per
task; mode selection does not override delegation restrictions or expand scope.
Continue directly when a helper would add no useful independence or capability.

| Mode | Choose it when | Mechanism |
| --- | --- | --- |
| Native coordination | Bounded research, implementation, or review fits the current harness's helper tools | Native helpers and the roles actually available in this session |
| Cross-harness coordination | Work needs another harness's tools or authentication, an independent process, or a durable queued run | Published harness registry and an explicit `task-queue` attempt |

For native coordination, use the current harness's helper API. Names and
capabilities differ between harnesses; check the available tools rather than
assuming a particular agent type. A native helper does not require another CLI,
Pueue job, workspace, or terminal pane merely to exist.

For cross-harness coordination, inspect `~/.config/sysinit/agents.json` for the
installed command and context file. Verify its noninteractive flags with installed
help. Pass the task UUID, exact authorization, relevant instructions, selected
checkout, bounded ownership, expected result, and acceptance criteria explicitly.
Read `taskwarrior` for submission and review. The ACP capability is a transport
capability; it does not establish native helper support or delegation permission.
Selecting a Goose ACP provider alone does not create a multi-harness workflow.

Native helpers can refer to their coordinator's task UUID without creating another
task. Separately queued concurrent units need distinct agreed task UUIDs, linked
back to the coordinator through annotations. Do not submit simultaneous attempts
for the same UUID; task-queue rejects them. Read `taskwarrior` for retry semantics.

For either mode, give read-only helpers access to the selected checkout; isolate
concurrent writers through the workspace owner's supported worktree lifecycle.
Collect each result and verify the integrated outcome before completing the task.
Use Conductor when reusable workflow steps and routing are needed; read
`conductor` for that interface.

## Choose the owning command

| Need | Entry point | Owns |
| --- | --- | --- |
| Durable work and acceptance criteria | `taskwarrior`; read the `taskwarrior` skill | Task UUID, dependencies, annotations, verified completion |
| Workspace and worktree lifecycle | `sy`; read `feature-based-session-manager` | Session membership and lifecycle of seshy-owned worktrees |
| Explicit queued execution | `task-queue`; read the submission section of `taskwarrior` | Attempt UUID, exact argv/cwd, Taskwarrior linkage and review state |
| Queue scheduling and output inspection | Pueue underneath `task-queue` | Job ID, scheduling, process output and exit status |
| Attachable queued terminal | `task-queue submit --terminal` | A zmx-backed execution, not a new WezTerm window |
| Visible execution requested by the owner | `worker` | One reusable WezTerm pane and command logs per workspace |

`worker` remains an owner-facing command, excluded from the agent skill registry.
This guidance does not grant permission to open panes or bypass its tool policy.
Keep short commands inline. Use a queued attempt when separate execution is useful;
do not turn every command into a task, attempt, or pane.

## Compose a task and workspace

1. Inspect the relevant Taskwarrior UUID, ownership, dependencies, and prior attempts.
2. Reuse the selected checkout. `sy current --path --quiet` looks up its session;
   a checkout outside seshy can still be used directly. Do not create a workspace
   merely to run a command. Read `feature-based-session-manager` before changing
   worktrees or registering an app-owned checkout by reference.
3. Choose an exact execution directory. `sy status <name> --format json` describes
   session members; a multi-repository session is not a single repository cwd.
4. Continue current-session work here, or submit one bounded execution through
   `task-queue`. Carry the same UUID, authorized scope, checkout, and acceptance
   criteria. A queue, session, or terminal does not add authorization.
5. Inspect the attempt's output and verify its result. Record completion through
   Taskwarrior or the imported task's owning workflow. Exit zero is not acceptance.

Use the submission examples and prompt contract in `taskwarrior`. Goose, Claude,
Codex, other installed harnesses, and foreground Conductor workflows use the same
boundary with their own argv. Detached dashboard/MCP launches do not signal queued
completion.

## Inspect and control the right execution

Start with `task-queue status`. Keep the Taskwarrior UUID, attempt UUID, and Pueue
job ID distinct. The `taskwarrior` skill documents submission, inspection,
cancellation, and retry through `task-queue`; Pueue supplies scheduling and output
underneath it. Native helper
results stay with their coordinator unless an explicit queued attempt is needed.

`--terminal` supplies an attachable zmx session. Inspect the returned attempt's
terminal identity and `zmx help` before attaching. Check `zmx list` first because
`zmx attach` creates a session when the name is absent. Closing a GUI view and ending
the queued process are different actions; inspect the attempt state afterwards.

## WezTerm and visible panes

Use `worker` for a long visible command when the owner requests that workflow.
Its cwd is the caller's checkout; `worker --status` inspects that workspace's pane.
It requires the caller to be inside WezTerm; a desktop agent should use its normal
execution tool or task-queue rather than creating a pane to satisfy that condition.
Waiting can time out while the command continues. Inspect the recorded result,
not the pane's existence, before claiming completion. Do not replace task-queue
with a pane when task-linked execution and review records are required.

`wezspawn` opens a window in the GUI's focused workspace and directory. It is a
launcher for that focused context, not a way to select an arbitrary task checkout.
It handles the missing-GUI case. Prefer it over raw `wezterm cli spawn` when the
owner requests another window.

Use raw WezTerm CLI for specific pane inspection or control after identifying the
intended pane. Every call passes `--no-auto-start`:

```sh
wezterm cli --no-auto-start list-clients
wezterm cli --no-auto-start list --format json
wezterm cli --no-auto-start get-text --pane-id <pane-id>
```

A pane ID does not prove a visible GUI exists. Without an attached GUI, a raw
CLI call can create a headless mux and return an ID without drawing a window.
Sending text types into a live terminal; verify its target and running process
before sending, interrupting, or closing it. Preserve unrelated panes and sessions.

## Agent shells

Invoke Bash explicitly for Bash syntax. Detected Claude/Codex noninteractive zsh
sessions enable unquoted field splitting and literal leading `=` arguments.
Other harnesses can opt in with `SYSINIT_AGENT_SHELL=1 zsh -c '...'`. Interactive
zsh retains its normal rules. These options do not make zsh a Bash interpreter;
quote paths and arguments normally.
