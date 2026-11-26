# Temporary Python migration deferrals

Nushell owns new and substantially changed automation. The following items need
a separate utility boundary before their Python implementation can be removed.
Upstream Python applications and language development tools retain their own
runtime dependencies.

| Files | Required utility boundary |
| --- | --- |
| `checks/shell/atuin.py`, `checks/shell/atuin-nushell.py`, `checks/shell/nushell-wezterm.py`, `checks/workflows/tq-browser.py`, `checks/workflows/tq-picker.py`, `checks/agents/threads-picker.py` | PTY allocation, terminal resize ioctls, multiplexed input/output, and terminal-screen assertions. Preserve real interactive behavior rather than replacing these checks with static assertions. |
| `checks/agents/codex-daemon.py` | Stateful WebSocket RPC over a Unix socket, correlated responses, and server process lifetime. |
| `checks/agents/codex-mcp-capabilities.py` | Duplex JSON-RPC over child stdin/stdout with correlated responses and timeouts. |

Private machine transport and authorization deferrals are recorded separately in
sysinit.laurel. Revisit these items when the corresponding native utility API is
defined; their presence does not justify adding new Python automation.
