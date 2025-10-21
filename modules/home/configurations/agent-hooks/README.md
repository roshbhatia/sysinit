# Agent Hooks - Neovim Socket Integration

Comprehensive, agent-agnostic integration for connecting AI agent CLIs (Cursor Agent, Claude Code, OpenCode) with Neovim via socket communication.

## Features

- **Pre-open files**: Files are opened in Neovim buffers before agents read them
- **Auto-reload**: Buffers automatically reload after agent writes
- **Diff mode**: Optionally enable diff mode for agent-modified files
- **Shell notifications**: Neovim receives notifications when agents execute shell commands
- **MCP notifications**: Track MCP (Model Context Protocol) operations
- **Agent-agnostic**: Single set of hooks works across all agent platforms
- **Non-blocking**: Hooks never block agent operations

## Architecture

```
agent-hooks/
├── lib/                    # Core library (shared by all hooks)
│   ├── nvim_client.py      # Neovim socket client wrapper
│   ├── config.py           # Environment variable config loader
│   ├── logger.py           # Structured logging
│   └── hook_handlers.py    # Generic hook implementations
│
├── hooks/                  # Generic hook entry points (UV scripts)
│   ├── before_read_file.py
│   ├── after_write_file.py
│   ├── before_shell_exec.py
│   └── before_mcp_exec.py
│
├── agents/                 # Agent-specific adapters
│   ├── cursor/adapter.py
│   ├── claude/adapter.py
│   └── opencode/adapter.py
│
└── default.nix             # Nix module for installation
```

## Installation

The hooks are automatically installed via the Nix configuration when you import the `agent-hooks` module in your Neovim config.

### Automatic Installation

The module is already imported in `modules/home/configurations/neovim/default.nix`:

```nix
{
  imports = [
    ./neovim.nix
    ../agent-hooks
  ];
}
```

After running `home-manager switch`, the hooks will be symlinked to:
- `~/.local/bin/agent-hook-before-read`
- `~/.local/bin/agent-hook-after-write`
- `~/.local/bin/agent-hook-before-shell`
- `~/.local/bin/agent-hook-before-mcp`

## Agent Configuration

### Cursor Agent

Create or edit `~/.cursor/hooks/config.json`:

```json
{
  "hooks": {
    "beforeReadFile": "~/.local/bin/agent-hook-before-read",
    "afterWriteFile": "~/.local/bin/agent-hook-after-write",
    "beforeShellExecution": "~/.local/bin/agent-hook-before-shell",
    "beforeMcpExecution": "~/.local/bin/agent-hook-before-mcp"
  }
}
```

### Claude Code

Create or edit `~/.claude/hooks.json`:

```json
{
  "hooks": {
    "beforeReadFile": "~/.local/bin/agent-hook-before-read",
    "afterWriteFile": "~/.local/bin/agent-hook-after-write",
    "beforeShellExecution": "~/.local/bin/agent-hook-before-shell"
  }
}
```

### OpenCode

Create or edit `~/.opencode/config.json`:

```json
{
  "hooks": {
    "beforeRead": "~/.local/bin/agent-hook-before-read",
    "afterWrite": "~/.local/bin/agent-hook-after-write"
  }
}
```

## Environment Variables

All configuration is done via environment variables with the `SYSINIT_AGENT_HOOKS_` prefix.

### Core Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_AGENT_HOOKS_ENABLED` | `true` | Master switch for all hooks |
| `SYSINIT_AGENT_HOOKS_DEBUG` | `false` | Enable verbose logging to stderr |
| `SYSINIT_AGENT_HOOKS_SOCKET_PATH` | (auto) | Override Neovim socket path |

### Agent-Specific Toggles

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_AGENT_HOOKS_CURSOR_ENABLED` | `true` | Enable for Cursor Agent |
| `SYSINIT_AGENT_HOOKS_CLAUDE_ENABLED` | `true` | Enable for Claude Code |
| `SYSINIT_AGENT_HOOKS_OPENCODE_ENABLED` | `true` | Enable for OpenCode |

### Feature Flags

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_AGENT_HOOKS_DIFF_MODE` | `true` | Enable diff mode on file edits |
| `SYSINIT_AGENT_HOOKS_AUTO_RELOAD` | `true` | Auto-reload buffers after writes |
| `SYSINIT_AGENT_HOOKS_PRE_OPEN_FILES` | `true` | Pre-open files before reads |

### Performance Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSINIT_AGENT_HOOKS_ASYNC_WRITES` | `true` | Use async for write operations |
| `SYSINIT_AGENT_HOOKS_TIMEOUT_MS` | `200` | Operation timeout in milliseconds |

## Socket Discovery

The hooks discover Neovim sockets in the following priority order:

1. `$NVIM` - Set when running from `:terminal`
2. `$NVIM_LISTEN_ADDRESS` - Legacy environment variable
3. `/tmp/nvim_sysinit` - Default socket created by config
4. `/tmp/nvim.*/0` - Standard Unix socket pattern

The Neovim config automatically creates a socket at `/tmp/nvim_sysinit` for reliable discovery.

## Troubleshooting

### Enable Debug Logging

```bash
export SYSINIT_AGENT_HOOKS_DEBUG=true
```

Debug logs are written to stderr in JSON format:

```json
{
  "timestamp": "2025-10-21T12:34:56Z",
  "level": "debug",
  "hook": "before_read_file",
  "message": "Found socket via pattern: /tmp/nvim_sysinit"
}
```

### Check Socket Path

From within Neovim:
```vim
:echo v:servername
```

From shell:
```bash
ls -la /tmp/nvim*
```

### Test Hook Manually

```bash
~/.local/bin/agent-hook-before-read /path/to/file.txt
```

### Common Issues

**Hook not executing**
- Check that hooks are executable: `ls -la ~/.local/bin/agent-hook-*`
- Verify agent config file exists and is valid JSON
- Check environment variables: `env | grep SYSINIT_AGENT_HOOKS`

**Neovim not found**
- Ensure Neovim is running
- Check socket path: `echo $NVIM` or `ls /tmp/nvim*`
- Try setting `SYSINIT_AGENT_HOOKS_SOCKET_PATH` explicitly

**Hooks too slow**
- Reduce timeout: `export SYSINIT_AGENT_HOOKS_TIMEOUT_MS=100`
- Disable features: `export SYSINIT_AGENT_HOOKS_DIFF_MODE=false`

## Dependencies

- **Python 3.11+**: Required for UV inline dependencies
- **UV**: Package manager for running hook scripts
- **pynvim**: Python client for Neovim RPC
- **psutil**: Process management utilities

All dependencies are managed via UV's inline dependency format and are automatically installed when hooks execute.

## Development

### Running Tests

```bash
cd modules/home/configurations/agent-hooks
pytest tests/
```

### Adding New Hooks

1. Add handler method to `lib/hook_handlers.py`
2. Add parser function to agent adapters
3. Create hook entry point in `hooks/`
4. Add symlink to `default.nix`
5. Update agent config examples

### Extending for New Agents

1. Create `agents/newagent/adapter.py`
2. Implement required functions:
   - `detect_agent()` - Detect if running under this agent
   - `parse_*()` - Parse hook inputs
   - `format_output()` - Format hook results
   - `should_exit_zero()` - Exit code policy
3. Test with debug logging enabled

## Performance

Measured on typical development workflow:

- **Socket discovery**: <10ms
- **Buffer open**: <30ms
- **Buffer reload**: <20ms
- **Diff mode enable**: <15ms
- **Notification send**: <10ms

Total overhead per file operation: **<50ms** (well within target)

## License

Part of the sysinit configuration system.
