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

`bin/nvim-ctl adopt` splits the editor to the **right**, because in that flow the
agent pane already exists and owns the left.

## Channels

Four channels exist. They are listed cheapest first.

### 1. Filesystem (all 12 agents, no setup)

`lua/harness/file_refresh.lua` polls `checktime`, so buffers pick up agent edits.
`lua/harness/spec_watch.lua` watches `openspec/` with `vim.uv.fs_event` and
previews artifacts as they are written. `gitsigns` shows the resulting hunks.

This needs no cooperation from the CLI, which is why the spec preview uses it.

### 2. Text injection (all 12 agents, no setup)

`wezterm cli send-text` into the agent pane. Every adapter's `send()` ends here.
`<leader>jR` uses it to deliver a whole batch of review comments at once.

### 3. Neovim RPC socket (any agent that can run a shell command)

`bin/nvim-ctl` writes a JSON request to a temp file, then calls
`nvim --server <socket> --remote-expr`. `lua/harness/control.lua` handles it.

This is the channel that lets an agent *show* you code: open a file, highlight a
range, annotate a line, split two files side by side. See the
`nvim-walkthrough` skill.

The socket is Neovim's own (`vim.v.servername`). Nothing extra runs, and the
same mechanism already backs the `$EDITOR` bridge in
`lua/utils/remote_editor.lua`.

Discovery works two ways:

1. Harness-spawned panes get `NVIM_HOST_SOCKET` in their environment.
2. Agents started outside nvim read `lua/harness/instance.lua`'s registry at
   `$XDG_STATE_HOME/nvim/harness/instances/*.json`.

### 4. MCP and ACP (not wired, on purpose)

Per-session MCP injection was considered and rejected. Only 4 of the 12 CLIs
accept an MCP config at spawn time:

| Flag | Agents |
|---|---|
| `--mcp-config` | claude, amp, pi |
| `--additional-mcp-config` | copilot |

The other eight need persistent config that the harness would have to write and
own: `codex mcp add`, `cursor-agent mcp`, `devin mcp`, `goose --with-extension`,
plus config files for opencode and crush. `agy` exposes no MCP surface at all.

That is a per-agent maintenance burden for a capability channel 3 already covers
with one shell script. Revisit if the coverage gap closes.

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
| `<leader>jw` | toggle spec auto-preview |
| `<leader>jp` | preview the current file |
| `<leader>jC` | clear agent highlights and annotations |

## Keeping CLI flags honest

`lua/harness/options.lua` supports five option kinds. Three exist specifically to
stop flag drift going unnoticed:

- `enum` renders a fixed choice list, so a retired choice cannot be typed.
- `opt_value` models flags valid bare or with a value, such as `--resume [id]`.
- `list` models repeatable flags, such as `--add-dir A --add-dir B`.

When an agent CLI updates, re-read its `--help` and reconcile the schema. Prefer
`enum` over a free-text `value` with the choices written into the prompt string.
