# Local history and agent Threads

Atuin owns Ctrl-R history search in Nushell, zsh, Bash, and Fish. fzf still owns
file/directory pickers and fuzzy completion. Up-arrow history remains native to
each shell. Shell history and captured agent sessions stay on each machine;
automatic sync and update checks are disabled. No account is required.

## Configuration and parity

The previous `modules/home/programs/atuin.nix`, removed in `3a6f645f8`, enabled
zsh integration and a compact 13-row picker with preview, help, and tabs hidden.
It returned the selected command for editing instead of executing it. The
restored module keeps the compact, editable selection behavior, validated against
the pinned Atuin 18.24.2, and adds all four shell integrations. The owner-selected
layout caps both pickers at eight rows and places the search bar at the top.
Long commands have a preview capped at two rows within that height. The native
theme uses the same shared foreground and accent palette as fzf, retaining the
terminal background. Help and tabs remain hidden.
`auto_hide_height = 0` keeps the search field, cursor, and preview visible at
eight rows; the upstream default otherwise selects its ultracompact layout.

| Behavior | Configuration |
| --- | --- |
| Fuzzy history search | `search_mode = "fuzzy"` |
| Commands from every local shell | `search.shells = "all"`, `filter_mode = "global"` |
| Compact, editable selection | `inline_height = 8`, `enter_accept = false` |
| Search bar and row details | `invert = true`; duration, time, and command columns |
| Picker editing mode | `keymap_mode = "vim-insert"`; type immediately, then Esc for j/k navigation and i to resume typing |
| Ctrl-R ownership | fzf history binding disabled; native Atuin integration loaded afterward |
| zsh-vi-mode | Atuin loads after its lazy fzf callback; Ctrl-R also works in Vi normal mode |
| Local service | Home Manager owns launchd on macOS and the systemd user service/socket on Linux |

Nix writes `~/.config/atuin/config.toml`. `ATUIN_CONFIG_DIR` points shells, the
daemon, and the MCP server at that file, independently of Atuin's newer
`~/.atuin` default. Data lives in `~/.local/share/atuin`. Original shell-history
files remain available; Atuin does not replace or truncate them.

## Agent Threads

The Nix-owned daemon captures new or continued sessions from Claude Code, Codex,
OpenCode, and Pi. Atuin also supports Omp, which this repository does not install.
Capture keeps conversations and tool inputs/outputs, as selected by the owner.
Atuin applies its native redaction and per-tool-payload size limit of 64 KiB.
The original harness transcript remains available for content Atuin omits.

Use the native commands directly:

```sh
atuin resume
atuin threads list --style json
atuin threads search --help
atuin threads show <id> --style json
atuin resume <id> --print
atuin resume <id> --in codex --print
```

Nushell's `threads` command opens compact fzf pickers for the action and captured
thread: resume in its original harness, continue in another installed harness,
fork a new session, or inspect the conversation. Conversion offers the installed
entries in the shared harness registry that Atuin supports: Claude, Codex,
OpenCode, Pi, and Omp. The thread picker searches all captured local threads.
Canceling any picker leaves the session alone.
Original-harness resume uses `--as-is`, matching the local-only setup and avoiding
sync catch-up checks against a service this machine does not use.

`threads --print` prints the selected resume command instead of launching it.
Atuin still creates a new session when forking or converting with `--print`.
Arguments pass through to the native interface, so `threads list --style json |
from json` and `threads resume <id> --print` compose with other Nushell commands.
The launcher uses Atuin's resume operation directly; it does not evaluate a
printed shell command or create a `sy` workspace, Pueue job, or terminal pane.

The native `atuin resume` picker starts in the current workspace and falls back to all threads when
that workspace has none. It inherits the eight-row inline height. `--print`
reviews a resume command without starting a harness. Resuming does not change Taskwarrior task
ownership, select a new `sy` workspace, or create a Pueue attempt. The
`local-workflows` skill describes those execution boundaries.

The shared MCP catalog registers `atuin mcp` for the installed harnesses through
the existing routing layer. Its tools search local shell history and captured
threads. MCP thread reads summarize tool calls; native Threads capture/resume
retains the configured inputs and outputs. A harness can consume the MCP even
when Atuin cannot capture that harness's own transcript format.

Standalone shell-output capture, PTY wrapping, and the `?` Atuin AI binding remain
disabled. They are separate features and are not needed for Threads.

## Import existing history

Atuin records new shell commands after a shell loads its updated configuration.
To import a shell's existing history once on a machine, run the matching native
importer:

```sh
atuin import zsh
atuin import bash
atuin import fish
atuin import nu
```

Use `atuin import nu-hist-db` for Nushell's SQLite format. On macOS, the Nushell
importers look under `~/Library/Application Support/nushell`, even when Nushell
itself uses XDG. Importing managed XDG history uses a temporary `HOME` containing
a link at that native location, with `ATUIN_CONFIG_DIR` still pointing at the
real managed configuration and its absolute data directory. Neither original
history file is moved or overwritten. The deployment evidence records the exact
imports performed on this machine.

Threads capture starts with new or continued sessions. Historical backfill is
explicit: `atuin threads import --harness codex` imports the older Codex sessions;
omit `--harness` to import every supported harness. This can duplicate substantial
transcript data, so it is not an activation step.

In Nushell, consume structured results without a second wrapper:

```nu
atuin threads list --style json | from json
storage usage ~/.local/share/atuin --depth 1
```

Full thread storage has no configured automatic deletion policy. File logs keep
Atuin's native four-day retention. Inspect data size through the existing
`storage` commands before choosing a history-retention policy. Nix owns settings,
MCP registration, and the daemon; avoid native setup commands that rewrite them.

## References

- [Atuin Threads announcement](https://blog.atuin.sh/threads-agent-sessions/)
- [Threads reference](https://docs.atuin.sh/main/ai/threads/)
- [Configuration reference](https://docs.atuin.sh/main/configuration/config/)
- [MCP reference](https://docs.atuin.sh/main/ai/mcp/)

The configuration and integration checks use the pinned binary, rather than
assuming the documentation for the main branch matches the installed release.
