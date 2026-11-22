# Agent workspaces

A workspace pairs a directory with a terminal pane and optional review splits.
The directory can be a Git worktree, part of a worktree, a seshy session, or an
ordinary folder. The original directory stays the agent's working directory.

```sh
agent-workspace agents
agent-workspace open --agent pi
agent-workspace open --agent goose --cwd ~/project -- --model <model>
agent-workspace open --session my-feature --agent claude
agent-workspace open --cwd ~/notes -- <command> <arguments>
agent-workspace attach --pane-id <existing-pane-id>
agent-workspace list
```

Use an agent name or command from the installed registry. Set
`SYSINIT_WORKSPACE_AGENT` for a personal default. The command after `--` can
be any executable. `open` creates a new tab. `attach` records an existing
pane and uses its reported directory unless you supply `--cwd`. Both print a
workspace ID. Use `--task <taskwarrior-uuid>` to record a link to an existing
task. Seshy still manages the session and its repositories.

`resume <workspace-id>` focuses its live pane. When a launched pane has
closed, `resume` reopens the exact recorded conversation if the agent has
one. Use `--conversation <native-id>` to bind an existing conversation at
launch or when reopening, or `--restart` for a fresh process. Claude, Pi, and
Strands accept a new conversation ID at launch, so the workspace assigns one.
For other agents, supply a full native ID when you want to associate a
conversation. The agent owns saving and resolving that conversation.

## Review changes and give feedback

Git workspaces pin the current commit and open or refresh Diffview when files
change, regardless of which agent is running. Use `--base` for a different
Git revision. File observation is scoped to the launched command's lifetime.
Use `--no-watch` for manual review or `--watch` to enable observation in an
ordinary folder. An attached pane supports manual refresh.

An ordinary folder opens in Neovim. Compare matching files with an explicit
baseline directory when you have one. Use `--directory` on `open` or `attach`
to choose folder review even inside a Git repository.

```sh
agent-workspace refresh <workspace-id> --focus
agent-workspace refresh <workspace-id> --file notes.txt --against ~/baseline
agent-workspace note <workspace-id> notes.txt 42 'Clarify the decision here.'
agent-workspace feedback <workspace-id>
agent-workspace feedback <workspace-id> --paste
```

In Diffview, use `:ChangesNote` on the saved working-tree side. In folder
review, use `:WorkspaceNote` on a saved file. `feedback` exports the notes as
JSON. `--paste` stages them in the recorded pane for you to review and submit.
It works with the agent's normal input interface.

For terminal placement use `ty` or `nuwez`. For editor operations use
`nuvim` with the socket returned by `refresh`. For independent review,
`agent-diff` accepts `--cwd`, `--pane-id`, `--background`, and `--json`.
OpenCode exposes its native viewer as `/diff` and the Neovim launcher as
`/nvim-diff`. Both work with a normal OpenCode launch. See the
[installed review tools](review-tools.md) for worktree and PR readers.

## Optional Codex App Server integration

```sh
agent-workspace open --adapter codex
agent-workspace open --adapter codex --conversation <codex-thread-id>
agent-workspace last-turn <workspace-id> --patch
agent-workspace feedback <workspace-id> --send
agent-workspace feedback <workspace-id> --send --steer <active-turn-id>
```

This adapter uses native completion notifications, records the exact thread
ID and captures the patch that Codex reports. `show` exposes the active turn
ID for steering. `--send` starts a turn on the idle thread or steers the
specified active turn. A Codex thread becomes resumable once it has saved
conversation history. Set `--socket` to use a different local App Server.

Workspace records and plain-file notes live under
`${XDG_STATE_HOME:-$HOME/.local/state}/agent-workspace`. The Changes local
provider owns Git review notes. Workspace feedback exports both.
