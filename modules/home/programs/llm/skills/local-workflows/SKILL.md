---
name: local-workflows
description: Choose the execution role and compose native helpers, separate harnesses, workspaces, queues, and terminals. Use at multi-step intake and for sy/seshy, Taskwarrior, task-queue/Pueue, zmx, worker, wezspawn, WezTerm, or command/session recovery with Atuin.
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

## Recover prior command and session context

Atuin keeps shell history and captured agent Threads local to this machine;
automatic sync is disabled. Use the Atuin MCP history/thread search tools for
prior commands and conversations, or `atuin threads list --style json`,
`atuin threads search --help`, and `atuin threads show <id>` from the shell.
Threads capture full tool inputs and outputs for the harnesses Atuin supports.
Native harness transcripts remain the source when capture has no matching entry.

`atuin resume` selects a session to resume or continue in another supported
harness. Inspect `atuin resume --help` and use `--print` to review the command
before launching it. A resume does not grant new authorization or replace the
Taskwarrior UUID, selected checkout, queue attempt, or terminal owner. Keep
current work here unless a separate execution is useful and authorized.
Nix owns Atuin settings and its daemon; change sysinit source rather than running
`atuin config enable`, `atuin mcp install`, or native daemon autostart setup.

## Choose the owning command

| Need | Entry point | Owns |
| --- | --- | --- |
| Durable work and acceptance criteria | `taskwarrior`; read the `taskwarrior` skill | Task UUID, dependencies, annotations, verified completion |
| Workspace and worktree lifecycle | `sy`; read `feature-based-session-manager` | Session membership and lifecycle of seshy-owned worktrees |
| Structured local session and pane API | `ty`; read `ty` | Compose seshy catalogs/open plans with explicit WezTerm pane operations |
| Explicit queued execution | `task-queue`; read the submission section of `taskwarrior` | Attempt UUID, exact argv/cwd, Taskwarrior linkage and review state |
| Queue scheduling and output inspection | Pueue underneath `task-queue` | Job ID, scheduling, process output and exit status |
| Attachable queued terminal | `task-queue submit --terminal` | A zmx-backed execution, not a new WezTerm window |
| Visible execution requested by the owner | `worker` | One reusable WezTerm pane and command logs per workspace |

`worker` remains an owner-facing command, excluded from the agent skill registry.
This guidance does not grant permission to open panes or bypass its tool policy.
Keep short commands inline. Use a queued attempt when separate execution is useful;
do not turn every command into a task, attempt, or pane.

`ty sessions` and `ty panes` return separate versioned JSON
documents. `ty catalog` combines them. Read `ty` before
using pane or session actions. Session and worktree lifecycle remains with
`sy`; task-linked execution remains with `task-queue`; use `worker` when the
owner requests a long-running visible command in the current workspace.

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

## Shared Codex server

Nix runs the local Codex app-server as a user service. Interactive `codex` clients
reuse it; `codex agents` inspects its chats and `codex app-server daemon version`
checks the connection. The desktop app retains its own process lifecycle.
Keep Taskwarrior/Pueue submissions on the existing bounded `codex exec` workflow.
Service restarts can interrupt shared turns. Nix and the platform service manager
own this server; native daemon bootstrap/update commands manage a separate package
installation and do not replace that ownership.

On NixOS and nix-darwin, Nix-owned Codex lifecycle hooks come from
`/etc/codex/hooks.json` and are trusted by native system policy. Plugin and project
hooks retain their own review flow. Hook commands resolve through the stable user
profile; source changes belong in sysinit rather than the generated hook file.
