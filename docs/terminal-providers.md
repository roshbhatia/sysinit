# Terminal providers

`tq submit --terminal` runs in the configured terminal workspace.
`TQ_TERMINAL_WORKSPACE` sets its name and defaults to `task-queue`.
The Sysinit packages wire the WezTerm provider into `tq` and `task-board`.
The WezTerm adapter honors `TQ_WEZTERM_SOCKET` and `TQ_WEZTERM_DOMAIN`.

External repositories can supply a local provider manifest through
`SYSINIT_TERMINAL_PROVIDER`. An attempt retains the manifest selected at
submission. Keep that manifest available while the attempt still needs terminal
access. Existing WezTerm attempts remain attachable through the original mux
configuration.

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
and `tq` supervises the command process. Terminal-specific configuration stays
with the provider. The board remains usable with Taskwarrior alone.
