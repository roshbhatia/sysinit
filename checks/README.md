# Repository checks

`default.nix` owns the check inventory. Nushell owns fixture setup, process
orchestration, and ordinary assertions. Nix supplies pinned dependencies and
configuration fixtures.

Use `lib.nix` for a Nushell check and `native.nix` for a sequence of runtime
probes. The native runner creates an isolated home and XDG directories, copies
declared fixtures, and fails when a probe fails. Keep relative Nushell imports
inside the source directory passed to the interpreter.

Native probes retain the API they exercise:

| Runtime | Coverage |
| --- | --- |
| Lua and Neovim | Desktop integrations, editor APIs, language servers, and Tree-sitter |
| Emacs Lisp | Mail commands and rendering through ERT |
| JavaScript and TypeScript | Plugins through Bun and Node.js |
| Bash, Zsh, and Fish | Each shell's completion API |
| Python | PTYs, terminal emulation, asynchronous MCP stdio, and Unix WebSockets |

The retained Python files are `atuin.py`, `atuin-nushell.py`,
`threads-picker.py`, `tq-browser.py`, `tq-picker.py`,
`nushell-wezterm.py`, `codex-mcp-capabilities.py`, and `codex-daemon.py`.
Replacing these probes requires an equivalent terminal or protocol test
utility. Ordinary filesystem and configuration checks belong in Nushell.

`hack/lint.nu` runs semantic checks, including the Statix and Deadnix diagnostics
used by none-ls. `hack/format.nu --check` formats a temporary copy of tracked
files and leaves the checkout unchanged. Their `.sh` entrypoints preserve the
commands used by hooks and CI.
