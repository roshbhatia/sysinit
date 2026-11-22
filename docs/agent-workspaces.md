# Agent workspaces

`agent-workspace` creates a WezTerm tab for a worktree and records its Git base,
pane ID and, when using Codex, thread ID. Run it inside WezTerm or supply an
existing `--pane-id`. The launcher defaults to the current worktree and pins
its current commit. Supply `--base` to review against another commit or branch.
Supply `--session` to select an existing seshy session. For a session with
multiple repositories, also supply `--cwd`.

```sh
agent-workspace open --cwd "$PWD"
agent-workspace open --session my-feature --cwd "$PWD" --thread <codex-thread-id>
agent-workspace open --cwd "$PWD" -- <agent-command> <arguments>
agent-workspace show <workspace-id>
agent-workspace resume <workspace-id>
```

`open` prints a JSON record. Use its `id` with subsequent commands. Supply
`--task <taskwarrior-uuid>` to record a link to an existing task. Use `sy` to
manage worktrees and `tq` to queue work. Use `ty` or `nuwez` to manage panes and
`nuvim` to work with the Neovim socket returned by `refresh`.

The default launcher connects to the local Codex App Server and opens the
native Codex TUI on the recorded thread. Set `--socket` to use a different
local App Server. `show` reports the thread ID after the TUI attaches.
`resume` focuses a live workspace pane or resumes its exact saved Codex
thread. Codex saves a new thread when it has conversation history.
Commands supplied after `--` manage their own process and
session lifecycle. For those commands, call `refresh` from the terminal or
the agent's own completion hook.

## Review changes

When a Codex turn completes with worktree changes, the launcher opens or
refreshes a Neovim Diffview split against the pinned base. Existing splits
refresh in place. Use `--focus` to open or select the diff deliberately.
`last-turn` reads the most recent completed turn observed by the launcher.
Use `--patch` for the patch Codex reported for that turn.

```sh
agent-workspace refresh <workspace-id> --focus
agent-workspace last-turn <workspace-id> --patch
agent-diff --cwd "$PWD" --pane-id <pane-id> --base HEAD --background --json
```

Add a note with `:ChangesNote` from a saved file on the working-tree side in
the review split, or use the CLI. The local Changes provider stores review
notes with their file, line, pinned base, and workspace ID.

```sh
agent-workspace note <workspace-id> path/to/file 42 'Keep the validation next to the write.'
agent-workspace feedback <workspace-id>
agent-workspace feedback <workspace-id> --send
agent-workspace feedback <workspace-id> --send --steer <active-turn-id>
```

`feedback` prints versioned JSON suitable for piping to another agent's
input. For Codex, `--send` starts a new turn on the recorded idle thread.
`--send --steer` sends to the specified active turn. Include the exact turn ID
reported as `active_turn_id` by `show`. Review notes stay local until explicitly
submitted.

Workspace and last-turn records live under
`${XDG_STATE_HOME:-$HOME/.local/state}/agent-workspace`. Codex owns its thread
history. Changes owns note storage. The commands operate on existing Git
worktrees and WezTerm sessions.
