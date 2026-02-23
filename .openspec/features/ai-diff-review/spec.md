# AI Diff Review Workflow

## Summary

Implement a FUSE-based shadow workspace system that intercepts file writes from AI terminal tools, presenting proposed changes in Neovim for explicit accept/reject review before applying to the real repository.

## Problem Statement

Current AI terminal tools (OpenCode, Claude Code, Goose, etc.) write directly to disk when using Edit/Write tools. Users see changes via Neovim's `checktime` polling but have no structured workflow to:
- Preview changes before they're applied
- Accept or reject individual file modifications
- Maintain a clear audit trail of AI-proposed vs human-approved changes

This is a significant UX gap compared to IDE integrations like VS Code Copilot which present inline diffs with accept/reject controls.

## Goals

1. **Universal coverage**: Work with any AI terminal tool, not just those with plugin systems
2. **Blocking review**: AI tool pauses until user approves/rejects each file change
3. **Neovim-native UX**: Leverage existing CodeDiff plugin for familiar diff review experience
4. **Minimal friction**: Fast path for accepting simple changes; detailed review for complex ones
5. **Graceful degradation**: System works even if FUSE is unavailable (falls back to polling)

## Non-Goals

- Hunk-level accept/reject in MVP (file-level only; upgrade path planned)
- Integration with non-terminal AI tools (VS Code extensions, etc.)
- Persistent change history beyond git (rely on git for audit trail)

## Architecture

```
+------------------------------------------------------------------+
|                      AI Terminal Tool                             |
|              (OpenCode / Claude / Goose / etc)                    |
+---------------------------+--------------------------------------+
                            | writes to $AI_WORKSPACE
                            v
+------------------------------------------------------------------+
|                    FUSE Overlay Filesystem                        |
|                      (ai-sandbox-fuse)                            |
|  - Mounts at ~/.cache/ai-workspace/<project>/shadow/              |
|  - Intercepts write() syscalls                                    |
|  - Blocks until approval signal received                          |
|  - Stores pending changes in .ai-meta/pending/                    |
+---------------------------+--------------------------------------+
                            | RPC notification
                            v
+------------------------------------------------------------------+
|                         Neovim                                    |
|  - review.lua receives pending change notification                |
|  - Opens CodeDiff view: original vs proposed                      |
|  - User presses <leader>dA (accept) or <leader>dR (reject)        |
|  - Signals FUSE daemon to unblock/rollback                        |
+------------------------------------------------------------------+
```

## Directory Structure

```
~/.cache/ai-workspace/
+-- <project-hash>/                    # SHA256 of real repo path
    +-- .ai-meta/
    |   +-- origin                     # Path to real repository
    |   +-- socket                     # Unix socket for nvim <-> fuse IPC
    |   +-- pending/
    |   |   +-- <relative-path>.json   # Metadata for each pending change
    |   +-- approved/                  # Staging area for approved changes
    +-- shadow/                        # FUSE mount point (AI sees this as repo)
    +-- base/                          # rsync copy of real repo (read layer)
```

## Components

### 1. ai-sandbox (Shell Wrapper)

**Location**: `hack/ai-sandbox`

**Responsibilities**:
- Create/update shadow workspace structure
- Initial rsync from real repo to base/
- Start FUSE daemon if not running
- Set environment variables (AI_WORKSPACE, NVIM_SOCKET_PATH)
- Launch AI tool with cwd in shadow/
- Cleanup on exit

**Interface**:
```bash
ai-sandbox [--no-fuse] <ai-command> [args...]

# Examples:
ai-sandbox opencode
ai-sandbox claude
ai-sandbox goose chat
```

### 2. ai-sandbox-fuse (FUSE Daemon)

**Location**: `pkgs/ai-sandbox-fuse/` (Rust or Go implementation)

**Responsibilities**:
- Mount overlay filesystem at shadow/
- Read operations: pass through to base/
- Write operations:
  1. Compute diff against base/ version
  2. Store pending change metadata in .ai-meta/pending/
  3. Send RPC notification to Neovim
  4. Block write() syscall until approval/rejection signal
  5. On approval: apply write to base/, sync to real repo
  6. On rejection: discard write, return EPERM to caller

**IPC Protocol** (Unix socket at .ai-meta/socket):
```json
// Daemon -> Neovim: New pending change
{
  "type": "pending",
  "id": "abc123",
  "file": "src/foo.lua",
  "diff": "--- a/src/foo.lua\n+++ b/src/foo.lua\n...",
  "proposed_content": "...",
  "original_content": "..."
}

// Neovim -> Daemon: Approval
{
  "type": "approve",
  "id": "abc123"
}

// Neovim -> Daemon: Rejection
{
  "type": "reject",
  "id": "abc123"
}
```

### 3. review.lua (Neovim Module)

**Location**: `modules/home/programs/neovim/lua/sysinit/utils/ai/review.lua`

**Responsibilities**:
- Listen for RPC notifications from FUSE daemon
- Queue pending changes
- Present diff review UI via CodeDiff
- Handle accept/reject keybinds
- Send approval/rejection signals back to daemon
- Show notification badges for pending review count

**Keybindings** (in `<leader>d` namespace):

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>dv` | `review.open_next()` | Open next pending change for review |
| `<leader>dA` | `review.accept()` | Accept current change |
| `<leader>dR` | `review.reject()` | Reject current change |
| `<leader>dL` | `review.list_pending()` | List all pending changes |
| `<leader>dS` | `review.accept_all()` | Accept all pending changes |
| `<leader>dX` | `review.reject_all()` | Reject all pending changes |

### 4. review_rpc.lua (RPC Listener)

**Location**: `modules/home/programs/neovim/lua/sysinit/utils/ai/review_rpc.lua`

**Responsibilities**:
- Connect to FUSE daemon's Unix socket
- Parse incoming JSON messages
- Dispatch to review.lua handlers
- Handle reconnection on daemon restart

### 5. Agent Configuration Updates

**Location**: `modules/home/programs/neovim/lua/sysinit/utils/ai/agents.lua`

**Changes**: Wrap all AI commands with `ai-sandbox`:

```lua
-- Current
{ name = "opencode", cmd = "opencode", ... }

-- Updated
{ name = "opencode", cmd = "ai-sandbox opencode", ... }
```

Alternatively, modify `backends/wezterm.lua` to auto-wrap:

```lua
-- In M.open():
local sandbox_cmd = string.format("ai-sandbox %s", agent_config.cmd)
```

### 6. Nix Package

**Location**: `pkgs/ai-sandbox-fuse/default.nix`

```nix
{ rustPlatform, fuse3, pkg-config }:

rustPlatform.buildRustPackage {
  pname = "ai-sandbox-fuse";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ fuse3 ];
}
```

## Implementation Phases

### Phase 1: Shadow Workspace Infrastructure
- [ ] Create `hack/ai-sandbox` shell script
- [ ] Implement workspace creation and rsync sync
- [ ] Add environment variable setup
- [ ] Test with manual file watching (no FUSE yet)

### Phase 2: Neovim Review UI
- [ ] Create `review.lua` module
- [ ] Integrate with CodeDiff for diff viewing
- [ ] Implement accept/reject keybinds
- [ ] Add pending change queue management
- [ ] Create status line indicator for pending count

### Phase 3: FUSE Daemon
- [ ] Scaffold Rust/Go FUSE project
- [ ] Implement read passthrough
- [ ] Implement write interception with blocking
- [ ] Add Unix socket IPC server
- [ ] Handle approval/rejection signals

### Phase 4: RPC Integration
- [ ] Create `review_rpc.lua` socket client
- [ ] Wire daemon notifications to review.lua
- [ ] Implement bidirectional communication
- [ ] Add reconnection logic

### Phase 5: Agent Integration
- [ ] Update agent configs to use ai-sandbox
- [ ] Test with OpenCode, Claude, Goose
- [ ] Add fallback mode for non-FUSE environments
- [ ] Document usage

## Fallback Mode (No FUSE)

When FUSE is unavailable (e.g., SSH sessions, containers, macOS without macFUSE):

1. `ai-sandbox --no-fuse` uses polling-based approach
2. fswatch monitors shadow/ for changes
3. Changes queue for review but don't block AI tool
4. User reviews asynchronously; changes sync on approval
5. Risk: AI may continue with outdated file state

## Testing Strategy

1. **Unit tests**: review.lua queue management, RPC parsing
2. **Integration tests**: FUSE daemon write interception
3. **E2E tests**: Full flow with mock AI tool writing files
4. **Manual testing**: Real usage with OpenCode, Claude, Goose

## Security Considerations

1. **Socket permissions**: Unix socket readable only by user
2. **Workspace isolation**: Each project gets isolated shadow workspace
3. **No credential leakage**: .ai-meta/ excluded from sync to real repo
4. **Audit trail**: All approved changes go through git in real repo

## Open Questions

1. **FUSE on macOS**: Requires macFUSE (not in nixpkgs). Use osxfuse overlay or require manual install?
2. **Performance**: Large repos may have slow initial rsync. Incremental sync strategy?
3. **Multiple AI sessions**: One FUSE daemon per project, or global coordinator?
4. **Nested changes**: AI modifies file again while previous change pending. Queue or reject?

## Success Criteria

1. AI tool writes are blocked until explicit user approval
2. User can review proposed changes in familiar CodeDiff UI
3. Accepted changes apply atomically to real repository
4. Rejected changes leave real repository untouched
5. System works for all AI terminal tools without per-tool configuration

## References

- [FUSE documentation](https://libfuse.github.io/doxygen/)
- [macFUSE](https://osxfuse.github.io/)
- [CodeDiff.nvim](https://github.com/esmuellert/codediff.nvim)
- [Neovim RPC](https://neovim.io/doc/user/api.html)
