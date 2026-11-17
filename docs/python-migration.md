# Temporary Python migration deferrals

Nushell owns new and substantially changed automation. The following items need
a separate utility boundary before their Python implementation can be removed.
They are temporary migration blockers, not permanent language exceptions. The
practical migration removes 44 Python files here and seven in sysinit.laurel.
The 12 files below and six private scripts and fixtures remain deferred.
Upstream Python applications and language development tools retain their own
runtime dependencies; they are not repository-owned scripts.

| Files | Required utility boundary |
| --- | --- |
| `checks/atuin.py`, `checks/atuin-nushell.py`, `checks/nushell-wezterm.py`, `checks/task-queue-browser.py`, `checks/task-queue-picker.py`, `checks/threads-picker.py` | PTY allocation, terminal resize ioctls, multiplexed input/output, and terminal-screen assertions. Preserve real interactive behavior rather than replacing these checks with static assertions. |
| `checks/codex-daemon.py` | Stateful WebSocket RPC over a Unix socket, correlated responses, and server process lifetime. |
| `checks/codex-mcp-capabilities.py` | Duplex JSON-RPC over child stdin/stdout with correlated responses and timeouts. |
| `modules/home/programs/slk-setup.py`, `checks/slk.py` | Lossless TOML edits that preserve user comments and formatting. Assess an existing native utility built on `toml_edit` before designing another editor. |
| `modules/home/programs/llm/harnesses/codex-native-tools.py` and its embedded fixtures in `checks/codex-config.nix` | Lossless TOML migration, backups, and idempotent completion markers. Nushell's parse-and-serialize path does not preserve the existing text contract. |
| `checks/log-retention.py` | A persistent open writer descriptor across rotations. Reopening the file for each write would weaken the current test. |

Private machine transport and authorization deferrals are recorded separately in
sysinit.laurel. Revisit these items when the corresponding native utility API is
defined; their presence does not justify adding new Python automation.
