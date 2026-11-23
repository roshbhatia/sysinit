# Terminal providers

`task-queue submit --terminal` runs in the configured terminal workspace.
`TQ_TERMINAL_WORKSPACE` sets its name and defaults to `task-queue`.
On macOS, `task-queue` and `task-board` select Rex when invoked from a Rex
block. Other invocations default to WezTerm.
Rex uses a session named after the configured workspace and a native tab per
attempt. To display a focused Rex attempt, select that session in Rex with
`Cmd+S`. Provider actions work against the local Rex server.
The WezTerm adapter honors `TQ_WEZTERM_SOCKET` and `TQ_WEZTERM_DOMAIN`.

External repositories can supply a local provider manifest through
`SYSINIT_TERMINAL_PROVIDER`. An attempt retains the manifest selected at
submission. Keep that manifest available while the attempt still needs terminal
access. Existing WezTerm attempts remain attachable through the original mux
configuration.

| Installed tool | Terminal boundary |
| --- | --- |
| `agent-diff`, `task-board` | Open review in the caller's Rex or WezTerm tab. Rex review drafts can use Reviewr's inbox or clipboard. |
| `task-queue`, `tq` | Pueue owns execution and logs. Terminal-backed attempts retain their provider and native terminal IDs. |
| `agents`, `changes`, `traces`, `nuvim`, `nvim` | Run in either terminal. Editor operations use Neovim's socket. |
| `seshy`, Tether, zoxide | Publish launch plans consumed by both pickers. Rex's host picker owns native Rex server connections. |
| `ty`, `nuwez`, `wezspawn`, `wezterm-remote` | Manage WezTerm. Use the native `rex` CLI for Rex sessions, tabs, and panes. |
| `neorex` | Opt-in Rex editor frontend. It manages its own Neovim listening socket. |
| `worker`, `agent-workspace`, agent-session tracking, automatic `ask` scrollback | Existing WezTerm integrations. Rex supports visible commands and scrollback through its own CLI. |

## Provider actions

Use the `provider/v1` manifest and JSONL protocol. A queue provider
implements four actions. All queue requests include the workspace.

| Action | Request | Result |
| --- | --- | --- |
| `terminal.spawn` | Working directory, title, and exact child argument list | Opaque JSON `reference` |
| `terminal.status` | The saved `reference` | `live` boolean |
| `terminal.focus` | The saved `reference` | `live` boolean, current `workspace` if it changed, and optional `argv` for interactive attach |
| `terminal.close` | The saved `reference` | Success, including when that terminal has already closed |
| `terminal.review` | Selected directory in `cwd` | Success after opening review. This action is used by the board. |

A provider verifies its own terminal identity before acting. Pueue owns jobs
and `task-queue` supervises the command process. Terminal-specific configuration stays
with the provider. The board remains usable with Taskwarrior alone.
