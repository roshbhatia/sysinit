# Agent and editor integration

How the twelve-agent harness and Neovim talk to each other, and why each channel
was chosen.

## Layout

Agent panes open on the **left**. The editor keeps the right side. Four places
decide this, and all four must agree:

| Site | Role |
|---|---|
| `lua/utils/wezterm_terminal.lua` `_spawn` | wezterm split flag, default `--left` |
| `lua/harness/lifecycle.lua` `snacks_opts` | snacks fallback position, default `left` |
| `lua/plugins/claudecode.lua` | `split_side` for claudecode.nvim's own provider |
| adapters | may pass `side = "right"` to opt out; none do today |

A fifth site used to exist: `bin/nvim-ctl adopt` split the editor to the right,
because in that flow the agent pane already existed and owned the left. That
command is deleted; see Channels.

## Channels

Two channels exist. They are listed cheapest first.

Both are agent-to-owner. Neither lets an agent move a surface the owner did not
ask it to move, and that is the rule the whole harness now follows: an agent may
write to an output stream about itself, and may not write to an input stream.

### 1. Filesystem (all 12 agents, no setup)

`lua/harness/file_refresh.lua` polls `checktime`, so buffers pick up agent edits.
`lua/harness/spec_watch.lua` watches `openspec/` with `vim.uv.fs_event` and
previews artifacts as they are written. `gitsigns` shows the resulting hunks.

This needs no cooperation from the CLI, which is why the spec preview uses it.

The watcher is opt-in. Turn it on with `:HarnessSpecWatch` or `<leader>jw`. It
used to start with the editor, which opened a preview nobody asked for.

### 2. Text injection, owner-initiated only (all 12 agents, no setup)

`wezterm cli send-text` into the agent pane. Every adapter's `send()` ends here.
`<leader>jR` uses it to deliver a whole batch of review comments at once.

Read the direction carefully. The owner presses a key and text goes to the
agent. Nothing in this repository sends text the other way any more.

### Removed: the Neovim RPC socket

There used to be a third channel. `bin/nvim-ctl` wrote a JSON request to a temp
file and called `nvim --server <socket> --remote-expr`, and
`lua/harness/control.lua` handled it. It let an agent open a file, highlight a
range, annotate a line, and split two files side by side in the owner's editor.

That is remote control, so it is gone: `bin/nvim-ctl`, `lua/harness/control.lua`,
`lua/harness/instance.lua`, and `lua/utils/remote_editor.lua` are all deleted,
along with the `$EDITOR` shim that used the same construct.

Deleting the handler would not have been enough on its own.
`nvim --server <sock> --remote-expr` reaches any lua module in a running editor,
so the channel was the socket, not the op table. The repository handed the agent
that socket two ways, and both are closed:

1. Harness-spawned panes got `NVIM_HOST_SOCKET` in their environment. The
   `editor_env` that exported it is deleted.
2. Agents started outside nvim read a registry at
   `$XDG_STATE_HOME/nvim/harness/instances/*.json`. The module that published it
   is deleted.

An agent that wants to show you something writes a file and says so. You open it.

### Not wired, on purpose: MCP and ACP

Per-session MCP injection was considered and rejected. Only 4 of the 12 CLIs
accept an MCP config at spawn time:

| Flag | Agents |
|---|---|
| `--mcp-config` | claude, amp, pi |
| `--additional-mcp-config` | copilot |

The other eight need persistent config that the harness would have to write and
own: `codex mcp add`, `cursor-agent mcp`, `devin mcp`, `goose --with-extension`,
plus config files for opencode and crush. `agy` exposes no MCP surface at all.

That was a per-agent maintenance burden for a capability the deleted RPC channel
covered with one shell script. That channel is gone on purpose, so MCP is no
longer the cheaper alternative to it; it is a different thing entirely. Revisit
on its own merits, not as a replacement.

ACP is a real alternative. `opencode acp`, `copilot --acp`, `devin acp`, and
`goose acp` are native, and ACP streams tool calls carrying `diff` content plus
`session/request_permission`. It is not wired because ACP runs the agent as a
subprocess of nvim with its own chat buffer. This harness deliberately runs
agents as full TUIs in wezterm panes, and those two models conflict.

## Reviewing an agent's work

1. `<leader>dd` opens the working diff in codediff.nvim.
2. `<leader>dr` opens the same diff with review.nvim annotations enabled.
3. `i` adds a typed comment: note, suggestion, issue, or praise.
4. `]n` and `[n` move between comments.
5. `<leader>jR` sends the whole batch to the active agent, unsubmitted.

## Spec artifacts

`spec_watch` previews `openspec/changes/<name>/*.md` and `openspec/specs/**` as
an agent writes them. Archived changes are skipped.

Rendering uses `glow` when it is on `PATH`, and falls back to a plain markdown
buffer otherwise. `glow` is optional by design.

| Key | Action |
|---|---|
| `<leader>jw` | toggle spec auto-preview (off at startup) |
| `<leader>jp` | preview the current file |

## Keeping CLI flags honest

`lua/harness/options.lua` supports five option kinds. Three exist specifically to
stop flag drift going unnoticed:

- `enum` renders a fixed choice list, so a retired choice cannot be typed.
- `opt_value` models flags valid bare or with a value, such as `--resume [id]`.
- `list` models repeatable flags, such as `--add-dir A --add-dir B`.

When an agent CLI updates, re-read its `--help` and reconcile the schema. Prefer
`enum` over a free-text `value` with the choices written into the prompt string.
