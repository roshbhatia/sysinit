# Shared Codex app-server

Nix runs the installed Codex binary as a user service on its standard local Unix
socket. New interactive CLI sessions reuse that server. `codex agents` browses
its sessions. Taskwarrior/Pueue executions still use `codex exec` and their
existing task/attempt lifecycle.

```sh
codex app-server daemon version
codex agents
codex --no-daemon
```

`--no-daemon` selects a separate CLI session when needed. Existing ChatGPT desktop
app-server processes retain their own lifecycle and bundled executable.

## Service ownership

| Platform | Inspect | Logs |
| --- | --- | --- |
| macOS | `launchctl print gui/$(id -u)/org.nix-community.home.codex-app-server` | `~/Library/Logs/codex-app-server.error.log` |
| Linux | `systemctl --user status codex-app-server` | `journalctl --user -u codex-app-server` |

The service launches `codex app-server --listen unix:// --managed-daemon` using
the Nix-pinned executable. The final flag enables native loaded-thread recovery
on shutdown. It follows Codex's own daemon launch arguments and is checked against
the pinned version. macOS log rotation checks every five minutes, rotates above
10 MB, and keeps three archives; Linux uses the user journal.

`features.daemon_auto_start` stays disabled. Codex still discovers an existing
server; disabling installation avoids creating another daemon package under
`~/.codex/packages`. Nix owns the binary and service. Native daemon `bootstrap`,
`update`, `restart`, and `stop` manage Codex's separate package/PID backend; use
the platform service manager for this server instead.

The standard socket is `~/.codex/app-server-control/app-server-control.sock` and
accepts WebSocket connections over Unix sockets. It is private to the local user.
`codex app-server proxy` forwards transport bytes; it does not convert JSONL into
WebSocket messages. Protocol clients use the native app-server WebSocket protocol.

Service restarts can interrupt active turns. Finish shared-server work before
switching a Codex version or restarting its service. Shutdown has a five-minute
service-manager allowance. The managed-daemon flag retains recovery state; it does
not guarantee that an interrupted tool execution can be repeated safely.

References: [Codex app-server](https://learn.chatgpt.com/docs/app-server),
[Codex developer commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli).
