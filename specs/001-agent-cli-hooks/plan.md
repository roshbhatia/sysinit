# Implementation Plan: Neovim Agent CLI Hooks Integration

**Branch**: `001-agent-cli-hooks` | **Date**: 2025-10-11 | **Spec**: [specs/001-agent-cli-hooks/spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-agent-cli-hooks/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement deep Neovim integration with AI agent CLI tools (Cursor Agent, Claude Code, OpenCode) by leveraging the Neovim socket API to provide VSCode/Cursor-like features including: buffer diffing, automatic buffer opening, automated reloading, and real-time synchronization. The implementation will use Python scripts with UV's inline dependency format, pluggable across all three agent platforms, and installed via symlinks using the mkOutOfStoreSymlink pattern already established in this repository.

## Technical Context

**Language/Version**: Python 3.11+ (with UV inline dependency format)  
**Primary Dependencies**: 
- `pynvim` - Neovim Python client for socket communication
- `psutil` - Process management and detection
- Agent-specific: Cursor Agent hooks, Claude Code hooks, OpenCode API clients

**Storage**: N/A (stateless scripts, configuration via environment variables)  
**Testing**: pytest (unit tests for hook handlers, integration tests with mock Neovim socket)  
**Target Platform**: macOS (Darwin) - primary; Linux support recommended for portability  
**Project Type**: Single project (CLI utilities/integration scripts)  
**Performance Goals**: 
- Hook execution <50ms for synchronous operations (file reads, buffer checks)
- Async operations (buffer loading) <200ms
- Neovim socket communication <100ms round-trip

**Constraints**: 
- Must not block agent operations
- Must gracefully handle Neovim not running
- Must support concurrent Neovim instances via socket paths
- Must use UV's inline dependency format (no separate requirements.txt)
- Must be installable via Nix mkOutOfStoreSymlink pattern

**Scale/Scope**: 
- 3 agent platforms (Cursor, Claude Code, OpenCode)
- ~5-8 hook types (beforeReadFile, afterReadFile, beforeShellExecution, etc.)
- Support for typical development workflows (10-50 open buffers)
- Handle files up to several MB efficiently

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Single Purpose**: Each hook script handles one specific integration point (beforeReadFile, afterReadFile, etc.)  
**Simplicity**: Python scripts with inline dependencies, no complex build system  
**Existing Patterns**: Uses established mkOutOfStoreSymlink pattern from wezterm/neovim/sketchybar configs  
**No Duplication**: Centralizes Neovim socket logic in shared utility module  
**Minimal Dependencies**: Core dependencies (pynvim, psutil) are lightweight and well-maintained  
**Integration Over Invention**: Leverages existing Neovim API and agent hook systems  
**Configuration Management**: Follows existing environment variable pattern (SYSINIT_* prefix)

## Project Structure

### Documentation (this feature)

```
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
modules/home/configurations/
├── neovim/                          # Existing Neovim configuration
│   ├── neovim.nix                   # Will reference new hooks directory
│   └── lua/sysinit/                 # Existing Lua config
│
└── agent-hooks/                     # NEW: Agent integration scripts
    ├── default.nix                  # Nix module for symlink installation
    │
    ├── lib/                         # Core library (shared by all hooks)
    │   ├── __init__.py              # Package marker
    │   ├── nvim_client.py           # Neovim socket client wrapper
    │   ├── config.py                # Environment variable config loader
    │   ├── logger.py                # Logging utilities
    │   └── hook_handlers.py         # Generic hook handler implementations
    │
    ├── hooks/                       # Generic hook entry points (UV scripts)
    │   ├── before_read_file.py      # Generic read hook (calls lib)
    │   ├── after_write_file.py      # Generic write hook (calls lib)
    │   ├── before_shell_exec.py     # Generic shell hook (calls lib)
    │   └── before_mcp_exec.py       # Generic MCP hook (calls lib)
    │
    ├── agents/                      # Agent-specific configuration/adapters
    │   ├── cursor/
    │   │   ├── config.json          # Cursor hook registration manifest
    │   │   └── adapter.py           # Cursor-specific input/output handling
    │   ├── claude/
    │   │   ├── config.json          # Claude hook registration manifest
    │   │   └── adapter.py           # Claude-specific input/output handling
    │   └── opencode/
    │       ├── config.json          # OpenCode registration manifest
    │       └── adapter.py           # OpenCode-specific input/output handling
    │
    └── tests/                       # Test suite
        ├── test_nvim_client.py      # Unit tests for client
        ├── test_hook_handlers.py    # Unit tests for handlers
        ├── test_hooks.py            # Integration tests
        ├── test_adapters.py         # Tests for agent adapters
        └── fixtures/                # Test data
```

**Structure Decision**: Library-first approach eliminates code duplication. All hook logic lives in `lib/hook_handlers.py` with generic hook entry points in `hooks/` that work across all platforms. Agent-specific differences are isolated to thin adapter layers in `agents/*/adapter.py`. The UV scripts in `hooks/` use inline dependencies and import from `lib/`, with the library path added via PYTHONPATH or UV's module resolution. This follows DRY principles while maintaining the established mkOutOfStoreSymlink pattern for Nix installation.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

No complexity violations detected. This feature follows established patterns and adds focused functionality without introducing architectural complexity.

## Implementation Phases

### Phase 0: Research & Discovery
**Deliverable**: `specs/001-agent-cli-hooks/research.md`

Research topics:
1. **Neovim Socket API**
   - Remote API architecture and RPC protocol
   - Buffer management APIs (open, reload, diff)
   - Socket discovery mechanisms ($NVIM, $NVIM_LISTEN_ADDRESS)
   - Error handling for disconnected/missing sockets
   
2. **Agent Hook Systems**
   - Cursor Agent hooks: registration, execution model, environment
   - Claude Code hooks: API differences from Cursor
   - OpenCode API: integration patterns, capabilities
   - Common patterns and platform-specific quirks
   
3. **UV Inline Dependencies**
   - PEP 723 inline script metadata format
   - Dependency version pinning strategies
   - UV execution model and caching
   
4. **pynvim Library**
   - Connection management and error handling
   - Buffer operations: edit, reload, diff mode
   - Async vs sync API usage
   - Performance characteristics

### Phase 1: Design & Contracts
**Deliverables**: `specs/001-agent-cli-hooks/{data-model.md,quickstart.md,contracts/}`

Design artifacts:
1. **Data Model** (`data-model.md`)
   - Neovim socket discovery algorithm
   - Hook input/output schemas per platform
   - Configuration schema (environment variables)
   - Error response formats
   
2. **API Contracts** (`contracts/`)
   - `nvim_client.py` interface specification
   - Hook script interface (stdin/stdout/exit codes)
   - Configuration loading contract
   - Logging interface
   
3. **Quickstart Guide** (`quickstart.md`)
   - Installation via Nix
   - Per-agent setup instructions
   - Environment variable reference
   - Troubleshooting common issues

### Phase 2: Implementation Tasks
**Deliverable**: `specs/001-agent-cli-hooks/tasks.md` (generated by `/speckit.tasks`)

High-level task breakdown:
1. **Core Library Implementation**
   - Implement `lib/nvim_client.py` with socket discovery
   - Implement `lib/config.py` with environment variable loading
   - Implement `lib/logger.py` with structured logging
   - Implement `lib/hook_handlers.py` with all generic hook logic
   
2. **Agent Adapter Layer**
   - Implement `agents/cursor/adapter.py` for Cursor-specific I/O
   - Implement `agents/claude/adapter.py` for Claude-specific I/O
   - Implement `agents/opencode/adapter.py` for OpenCode-specific I/O
   - Create agent configuration manifests (config.json)
   
3. **Generic Hook Entry Points**
   - Implement `hooks/before_read_file.py` (calls lib, detects agent)
   - Implement `hooks/after_write_file.py` (calls lib, detects agent)
   - Implement `hooks/before_shell_exec.py` (calls lib, detects agent)
   - Implement `hooks/before_mcp_exec.py` (calls lib, detects agent)
   - Add UV inline dependencies to all hook scripts
   
4. **Nix Integration**
   - Create `agent-hooks/default.nix` with mkOutOfStoreSymlink
   - Set up PYTHONPATH for lib/ directory access
   - Update `modules/home/configurations/default.nix` to import
   - Add environment variables to appropriate shell configs
   
5. **Testing & Validation**
   - Write unit tests for core library (nvim_client, hook_handlers)
   - Write unit tests for each agent adapter
   - Write integration tests with mock Neovim
   - Manual testing with each agent platform
   - Performance validation (<50ms sync, <200ms async)
   
6. **Documentation**
   - Document library architecture and extension points
   - Document hook behavior and limitations
   - Add troubleshooting guide
   - Update main README with feature reference

## Key Technical Decisions

### 1. UV Inline Dependencies vs requirements.txt
**Decision**: Use UV inline dependency format (PEP 723)  
**Rationale**: 
- Single-file distribution simplifies Nix symlink strategy
- No separate requirements file to track
- Version pinning at script level ensures reproducibility
- Aligns with UV's intended use case for standalone scripts

### 2. Socket Discovery Strategy
**Decision**: Check `$NVIM` → `$NVIM_LISTEN_ADDRESS` → default socket paths  
**Rationale**:
- `$NVIM` is set when script runs from Neovim terminal
- `$NVIM_LISTEN_ADDRESS` is legacy but still used
- Default paths (`/tmp/nvim.*/0`) cover most cases
- Graceful degradation when Neovim not running

### 3. Library-First Architecture with Adapter Pattern
**Decision**: Shared library (`lib/hook_handlers.py`) with thin agent adapters  
**Rationale**:
- Eliminates code duplication across platforms
- Single source of truth for hook logic
- Agent differences isolated to I/O parsing (adapter pattern)
- Easy to add new agent platforms
- Simplifies testing (test library once, not per-platform)
- Generic hooks in `hooks/` work for all agents via detection

### 4. Generic Hooks with Runtime Agent Detection
**Decision**: Single set of hook scripts that detect calling agent at runtime  
**Rationale**:
- Eliminates need for per-agent hook scripts (DRY)
- Agents register same hook paths, scripts detect context
- Detection via environment variables or process inspection
- Falls back to generic behavior if agent unknown
- Reduces symlink count in Nix configuration

### 5. Synchronous vs Asynchronous Execution
**Decision**: Synchronous for reads, asynchronous for writes/shell  
**Rationale**:
- Read hooks benefit from buffer pre-loading (sync acceptable)
- Write hooks shouldn't block agent (fire-and-forget async)
- Shell hooks are notifications (async)
- Prevents agent hangs on slow Neovim responses

### 6. Error Handling Philosophy
**Decision**: Fail gracefully, never block agent operations  
**Rationale**:
- Hook failures shouldn't break agent workflows
- Log errors but return success exit codes
- Neovim unavailability is not a fatal error
- User experience degrades gracefully to normal mode

## Integration Points

### Environment Variables
```bash
# Core configuration
SYSINIT_AGENT_HOOKS_ENABLED=true          # Master switch
SYSINIT_AGENT_HOOKS_DEBUG=false           # Verbose logging
SYSINIT_AGENT_HOOKS_SOCKET_PATH=""        # Override socket discovery

# Per-agent toggles
SYSINIT_AGENT_HOOKS_CURSOR_ENABLED=true
SYSINIT_AGENT_HOOKS_CLAUDE_ENABLED=true
SYSINIT_AGENT_HOOKS_OPENCODE_ENABLED=true

# Feature flags
SYSINIT_AGENT_HOOKS_DIFF_MODE=true        # Enable diff mode on edits
SYSINIT_AGENT_HOOKS_AUTO_RELOAD=true      # Auto-reload on external changes
```

### Nix Module Integration
```nix
# modules/home/configurations/agent-hooks/default.nix
{ config, lib, pkgs, ... }:

let
  agentHooksPath = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/agent-hooks";
in
{
  home.file = {
    # Generic hook entry points (shared by all agents)
    ".local/bin/agent-hook-before-read" = {
      source = lib.mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_read_file.py";
      executable = true;
    };
    ".local/bin/agent-hook-after-write" = {
      source = lib.mkOutOfStoreSymlink "${agentHooksPath}/hooks/after_write_file.py";
      executable = true;
    };
    ".local/bin/agent-hook-before-shell" = {
      source = lib.mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_shell_exec.py";
      executable = true;
    };
    ".local/bin/agent-hook-before-mcp" = {
      source = lib.mkOutOfStoreSymlink "${agentHooksPath}/hooks/before_mcp_exec.py";
      executable = true;
    };
    
    # Symlink the entire lib directory for imports
    ".local/lib/python/agent_hooks" = {
      source = lib.mkOutOfStoreSymlink "${agentHooksPath}/lib";
    };
  };
  
  # Environment variables added to shell configs
  home.sessionVariables = {
    SYSINIT_AGENT_HOOKS_ENABLED = "true";
    PYTHONPATH = "$HOME/.local/lib/python:${"\${PYTHONPATH:-}"}";
  };
}
```

### Agent Hook Registration
All platforms register the same generic hook scripts:

**Cursor**: `~/.cursor/hooks/config.json`
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

**Claude Code**: `~/.claude/hooks.json`
```json
{
  "hooks": {
    "beforeReadFile": "~/.local/bin/agent-hook-before-read",
    "afterWriteFile": "~/.local/bin/agent-hook-after-write",
    "beforeShellExecution": "~/.local/bin/agent-hook-before-shell"
  }
}
```

**OpenCode**: `~/.opencode/config.json`
```json
{
  "hooks": {
    "beforeRead": "~/.local/bin/agent-hook-before-read",
    "afterWrite": "~/.local/bin/agent-hook-after-write"
  }
}
```

**Note**: All agents use the same hook scripts. Runtime agent detection happens via environment variables or process inspection, with adapters handling platform-specific I/O formats.

## Success Criteria

### Functional Requirements
- Files open in Neovim buffers before agent reads them
- Buffers automatically reload after agent writes
- Diff mode activates for agent-modified files
- Shell commands trigger Neovim notifications
- Works across all three agent platforms

### Performance Requirements
- Hook execution <50ms for synchronous operations
- Async operations complete <200ms
- No perceptible agent workflow delays
- Handles 50+ open buffers efficiently

### Quality Requirements
- Graceful degradation when Neovim not running
- Clear error messages in debug mode
- Unit test coverage >80%
- Integration tests for each hook type
- Documentation covers common issues

### Integration Requirements
- Installs via Nix mkOutOfStoreSymlink pattern
- Environment variables follow SYSINIT_* convention
- Works with existing Neovim configuration
- No conflicts with existing Neovim plugins
- Compatible with multiple Neovim instances
