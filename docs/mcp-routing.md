# MCP routing

Sysinit routes its declared MCP servers through agentgateway. Each client uses
the same catalog through a stdio compatibility adapter. Host-owned remote
gateways keep authentication outside the clients.

Repository and third-party plugin MCP files remain separate configuration
sources. This catalog does not rewrite them.

## Runtime

`additionalServers` declares upstream servers. `mcp-catalog.nix` applies host
and client overrides, then `mcp-routing.nix` renders gateway commands.
Disabled servers are omitted, including for clients without an enable flag.

`mcp-gateway` is a Go supervisor. It uses the Go `mcp-remote` adapter for
Streamable HTTP. Local servers get a gateway process per client connection,
with the caller's directory and environment. This preserves Orc session
identity and repository-relative operations.

Each temporary gateway requires a random session key and DNS rebinding checks.
Agentgateway currently binds its data port on all interfaces; the session key
protects that port. Configuration files have mode 0600 inside a private
temporary directory. EOF and signals stop the owned processes.

Set `gateway = true` only for an existing host-owned HTTP gateway. The
supervisor rejects non-loopback URLs for that setting. Put upstream OAuth and
provider-specific policies behind that gateway.

## Clients and checks

Claude Code, Codex, Cursor, Antigravity, OpenCode, Amp, Goose, Copilot, Crush,
Devin, Hermes, and fx receive native stdio registrations. Pi, Atomic, and Prime
use the pinned `pi-mcp-adapter` package and the shared MCP configuration.
The adapter version is 2.20.0 because 2.34.0 imports a runtime API that Atomic
does not expose. Its MCP Apps SDK peer dependency is explicit in Nix.

`~/.config/sysinit/mcp-clients.json` records each client's routed catalog.
To check a server without calling its tools, use its generated command:

```sh
catalog="$HOME/.config/sysinit/mcp-clients.json"
command=$(jq -r '.codex.slack.command' "$catalog")
definition=$(jq -r '.codex.slack.args[0]' "$catalog")
"$command" --probe "$definition"
```

The probe checks initialization and tool discovery. It reports protocol and
tool count. A successful probe does not prove authorization for every tool.
The Go integration tests exercise a real gateway and adapter with a local
fixture, including tool calls, resources, session context, and shutdown.

## LiteLLM comparison

LiteLLM supports [HTTP, SSE, and stdio MCP upstreams](https://docs.litellm.ai/docs/mcp)
and [OAuth with preconfigured client credentials](https://docs.litellm.ai/docs/mcp_oauth).
Its [tool-search interface](https://docs.litellm.ai/docs/mcp_tool_search) can reduce
the tool catalog sent to small-context clients. Model routing and spend
controls are other reasons to evaluate it as a model gateway.

This change retains agentgateway. LiteLLM's advertised transport support does
not establish compatibility with our OAuth providers or preserve a local
caller's working directory. A replacement must pass the same client and
session tests. No model traffic is moved by this change.
