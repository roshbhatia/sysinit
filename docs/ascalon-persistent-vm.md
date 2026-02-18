# PRD: Ascalon Persistent Development VM

**Status**: In Progress  
**Created**: 2026-02-18  
**Updated**: 2026-02-18  
**Owner**: Rosh Bhatia

---

## Problem Statement

Currently, development work lacks a persistent Linux environment:
- macOS host (lv426) - Primary GUI environment, macOS-specific tooling
- Ephemeral project VMs - Created per-project via flake templates, no persistence
- No seamless way to work in Linux environment for testing/development

**Pain Points**:
1. No persistent Linux development environment for long-running work
2. Cannot easily test NixOS-specific configurations without rebuilding VMs
3. Need Linux environment for Docker workflows, cross-platform testing
4. Ephemeral VMs lose state on rebuild, unsuitable for day-to-day work
5. Inconsistent environments between macOS and target deployment (Linux)

---

## Goals

### Primary Goals
1. **Persistent VM**: Single long-running Lima VM with NixOS that survives restarts
2. **Easy Access**: VM named "default" for `lima` command shortcut
3. **WezTerm Integration**: Named SSH domain "ascalon" for quick terminal access
4. **Socket Sharing**: Docker and 1Password sockets mounted from macOS host
5. **Auto-start**: VM starts automatically on macOS boot via launchd
6. **Home Persistence**: `/home/rbha18.linux/` persists across VM restarts and rebuilds

### Non-Goals
1. **NOT** replacing macOS as primary environment
2. **NOT** running GUI/desktop applications in VM
3. **NOT** replacing per-project ephemeral VMs (those remain for isolated testing)
4. **NOT** creating custom CLI tool (use `limactl` directly)
5. **NOT** forcing NixOS immediately (Ubuntu acceptable temporarily)
6. **NOT** WezTerm daemon/unix socket (SSH domain is sufficient)

---

## Success Criteria

### Must Have (P0)
- [ ] Lima instance named "default" running and accessible
- [ ] Can access VM via `lima` command (shortcut for `limactl shell default`)
- [ ] Can access VM via `ssh lima-default` (Lima auto-generated SSH config)
- [ ] WezTerm SSH domain named "ascalon" connects successfully
- [ ] WezTerm keybindings work: CMD+S (domain picker), CMD+SHIFT+T (new tab in ascalon)
- [ ] Docker socket mounted from macOS Colima (writable)
- [ ] Docker CLI works in VM: `lima docker ps` succeeds
- [ ] 1Password socket mounted from macOS (writable)
- [ ] 1Password CLI works in VM: `lima op whoami` succeeds
- [ ] VM auto-starts on macOS boot via launchd plist
- [ ] `/home/rbha18.linux/` persists across VM restarts
- [ ] sysinit repo mounted at `/Users/rbha18/github/personal/roshbhatia/sysinit` (writable)
- [ ] Documentation complete: PRD and usage guide

### Should Have (P1) - Future Enhancements
- [ ] Full NixOS instead of Ubuntu (currently blocked by nixos-lima boot failures)
- [ ] VM hostname set to "ascalon" (requires NixOS)
- [ ] `nixos-rebuild switch --flake .#ascalon` works inside VM (requires NixOS)
- [ ] Ascalon NixOS config matches macOS package set (golden image parity)
- [ ] WezTerm daemon in VM with unix socket multiplexing (better UX than SSH)

### Nice to Have (P2)
- [ ] Resource limits tuned based on usage patterns
- [ ] Port forwarding configured if needed for services
- [ ] Additional project directories mounted
- [ ] Automated tests for VM lifecycle

---

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  macOS Host (lv426 / APKR2N5D495296)                        │
│  - Primary environment with full tooling                     │
│  - Colima: Docker daemon at ~/.colima/default/docker.sock   │
│  - Lima: VM manager                                          │
│  - 1Password: Agent socket at ~/Library/Group Containers/   │
│    2BUA8C4S2C.com.1password/t/s.sock                        │
│  - WezTerm GUI: SSH domain "ascalon" → lima-default         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          │ Lima Mounts (writable):
                          │ - ~/.colima/default/ → Docker socket
                          │ - ~/Library/.../t/ → 1Password socket
                          │ - ~/github/.../sysinit → Project files
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Ascalon - Lima VM "default" (Ubuntu 25.10, target: NixOS) │
│  - Accessible via: lima, ssh lima-default, WezTerm          │
│  - Docker CLI → macOS Colima socket (writable)              │
│  - 1Password CLI → macOS agent socket (writable)            │
│  - Persistent home: /home/rbha18.linux/                     │
│  - Project mount: /Users/.../sysinit (writable)             │
│  - Resources: 6 CPUs, 12GB RAM, 50GB disk                   │
└─────────────────────────────────────────────────────────────┘
```

### Key Naming Decisions

**Why "default" for Lima instance?**
- Enables `lima` command shortcut (equivalent to `limactl shell default`)
- Cleaner than `limactl shell ascalon` every time
- Lima auto-generates SSH config with host alias `lima-default`

**Why "ascalon" for WezTerm domain?**
- User-facing name in WezTerm UI
- Meaningful and memorable (project codename)
- Separates VM instance name from user-facing identity

**Why "ascalon" for NixOS hostname?**
- When we migrate to NixOS, hostname will be "ascalon"
- Keeps user-facing consistency
- VM infrastructure name ("default") vs logical host identity ("ascalon")

### Key Components

#### 1. Lima Configuration (`~/.lima/default/lima.yaml`)

**Current State**:
```yaml
images:
  - location: "nixos-lima-aarch64.qcow2"  # BROKEN - falls back to Ubuntu 25.10
    arch: "aarch64"

cpus: 6
memory: "12GiB"
disk: "50GiB"

mounts:
  - location: "~/github/personal/roshbhatia/sysinit"
    writable: true
  # MISSING: Docker socket mount
  # MISSING: 1Password socket mount
```

**Target State**:
```yaml
images:
  - location: "nixos-lima-aarch64.qcow2"  # Or standard NixOS ISO
    arch: "aarch64"

cpus: 6
memory: "12GiB"
disk: "50GiB"

mounts:
  - location: "~/github/personal/roshbhatia/sysinit"
    writable: true
  
  # Docker socket (writable - VM sends commands to Colima)
  - location: "~/.colima/default"
    writable: true
  
  # 1Password socket (writable - VM authenticates with agent)
  - location: "~/Library/Group Containers/2BUA8C4S2C.com.1password/t"
    writable: true
```

#### 2. WezTerm SSH Domain (`modules/darwin/home/wezterm/`)

**Current State (BROKEN)**:
```lua
-- modules/darwin/home/wezterm/lua/sysinit/pkg/core.lua
ssh_domains = {
  {
    name = "ascalon",
    remote_address = "127.0.0.1:62068",  -- HARDCODED PORT - WRONG
    username = utils.get_username(),
    multiplexing = "None",
  },
}
```

**Target State**:
```lua
ssh_domains = {
  {
    name = "ascalon",
    remote_address = "lima-default",  -- Uses Lima SSH config
    username = utils.get_username(),
    multiplexing = "None",
  },
}
```

**Why this works**:
- Lima auto-generates SSH config at `~/.lima/default/ssh.config`
- Includes host alias `lima-default` with correct port, keys, etc.
- Port changes on VM restart - Lima handles it automatically
- WezTerm SSH backend reads standard SSH config

#### 3. Auto-Start launchd Plist (`~/Library/LaunchAgents/`)

**Create**: `~/Library/LaunchAgents/io.lima.default.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.lima.default</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/limactl</string>
        <string>start</string>
        <string>default</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

**Load**: `launchctl load ~/Library/LaunchAgents/io.lima.default.plist`

#### 4. NixOS Configuration (`hosts/ascalon/default.nix`)

**Current State**: 
- Configuration exists and validates (`nix flake check` passes)
- Cannot build on macOS (requires Linux builder or binary cache)
- Uses nixos-lima module via conditional import in `lib/builders.nix`

**Future State** (when NixOS boots):
- Full NixOS system with nixos-lima integration
- `lima-init` service configures VM from Lima cloud-init
- `lima-guestagent` service handles vsock port forwarding
- Home-manager integration for user environment
- Matches macOS package set for consistency

### Socket Mount Details

#### Docker Socket
**Location**: `~/.colima/default/docker.sock`  
**Mount**: `~/.colima/default/` directory (contains socket)  
**Writable**: **YES** - VM needs to write to socket to send Docker commands  
**Test Command**: `lima docker ps`

#### 1Password Socket
**Location**: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock`  
**Mount**: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/` directory  
**Writable**: **YES** - VM needs to write to socket to authenticate and retrieve secrets  
**Test Command**: `lima op whoami`  
**Note**: Team ID `2BUA8C4S2C.com.1password` is stable Apple identifier, safe to hardcode

### WezTerm Keybindings

**Configured in**: `modules/darwin/home/wezterm/lua/sysinit/pkg/keybindings.lua`

```lua
CMD+S              -> ShowLauncherArgs({ flags = "FUZZY|DOMAINS" })  -- Domain picker UI
CTRL+T / CMD+T     -> SpawnTab("CurrentPaneDomain")                  -- New tab (current domain)
CTRL+SHIFT+T       -> SpawnTab({ DomainName = "ascalon" })           -- New tab (Ascalon)
CMD+SHIFT+T        -> SpawnTab({ DomainName = "ascalon" })           -- New tab (Ascalon)
```

---

## Implementation Phases

### Phase 1: WezTerm Connection Fix (P0) - CRITICAL
**Status**: Blocked - WezTerm cannot connect due to hardcoded port

**Tasks**:
1. Update WezTerm SSH domain config to use `lima-default` instead of `127.0.0.1:62068`
2. Apply home-manager configuration: `task nix:refresh:work`
3. Restart WezTerm
4. Test: CMD+S → select "ascalon" → should connect
5. Test: CMD+SHIFT+T → should spawn new tab in Ascalon VM

**Validation**:
```bash
# From WezTerm after connecting to ascalon domain
whoami              # Should show: rbha18
uname -a            # Should show: Linux ... Ubuntu 25.10 ... aarch64
pwd                 # Should show: /home/rbha18.linux
```

### Phase 2: Socket Mounts (P0) - CORE FUNCTIONALITY
**Status**: Pending

**Tasks**:
1. Stop Lima VM: `limactl stop default`
2. Edit Lima YAML: `~/.lima/default/lima.yaml`
3. Add Docker socket mount: `~/.colima/default` (writable: true)
4. Add 1Password socket mount: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t` (writable: true)
5. Start Lima VM: `limactl start default`
6. Test Docker: `lima docker ps` (should connect to Colima daemon)
7. Test 1Password: `lima op whoami` (should authenticate via macOS agent)

**Validation**:
```bash
# Test Docker socket
lima docker ps
lima docker run --rm hello-world

# Test 1Password socket
lima op whoami
lima op item list
```

### Phase 3: Auto-Start Configuration (P0) - CONVENIENCE
**Status**: Pending

**Tasks**:
1. Create launchd plist: `~/Library/LaunchAgents/io.lima.default.plist`
2. Load plist: `launchctl load ~/Library/LaunchAgents/io.lima.default.plist`
3. Test: Reboot macOS
4. Verify VM auto-started: `limactl list` (should show "Running")

**Validation**:
```bash
# After macOS reboot (without manual start)
limactl list        # Should show: default    Running    ...
lima uname -a       # Should connect successfully
```

### Phase 4: Documentation (P0) - KNOWLEDGE PRESERVATION
**Status**: Pending

**Tasks**:
1. Finalize PRD with accurate architecture and current state
2. Create usage guide: `docs/ascalon-vm-usage.md`
3. Document workflow patterns and commands
4. Add troubleshooting section
5. Commit all documentation

### Phase 5: Cleanup (P1) - CODE HYGIENE
**Status**: Pending

**Tasks**:
1. Archive old beads tasks (VM Cattle, VM Docker)
2. Remove `templates/ascalon-simple.yaml` (superseded by working `default` instance)
3. Keep `templates/ascalon.yaml` as reference for future NixOS migration
4. Update `.sysinit/lessons.md` with final learnings

### Phase 6: NixOS Migration (P1) - FUTURE ENHANCEMENT
**Status**: Blocked - nixos-lima image fails to boot

**Options**:
1. **Standard NixOS ISO**: Download minimal NixOS ISO and configure manually
2. **Debug nixos-lima**: Investigate why pre-built image fails to boot
3. **Stay on Ubuntu**: Keep Ubuntu, revisit NixOS later

**Recommended**: Option 3 - Get VM fully functional on Ubuntu first, NixOS is enhancement

---

## Testing Strategy

### Connection Testing
```bash
# Test Lima access
limactl list
lima uname -a
ssh lima-default uname -a

# Test WezTerm access
# In WezTerm: CMD+S → select "ascalon" → should connect
# In WezTerm: CMD+SHIFT+T → should spawn tab in Ascalon
```

### Socket Testing
```bash
# Docker socket
lima docker --version
lima docker ps
lima docker run --rm alpine:latest echo "Hello from Ascalon"

# 1Password socket
lima op --version
lima op whoami
lima op item get "Example Login" --fields password
```

### Persistence Testing
```bash
# Create test file
lima bash -c "echo 'persistence-test-$(date +%s)' > ~/test-persistence.txt"

# Restart VM
limactl stop default && limactl start default

# Verify file persists
lima cat ~/test-persistence.txt  # Should show original content
```

### Auto-Start Testing
```bash
# Before reboot
limactl stop default

# Reboot macOS

# After reboot (no manual intervention)
limactl list                     # Should show: default    Running
lima uptime                      # Should show low uptime (just started)
```

---

## Current State Summary

### What Works
- Lima VM "default" running Ubuntu 25.10
- Accessible via: `lima`, `ssh lima-default`, `limactl shell default`
- Home directory persists: `/home/rbha18.linux/`
- Project directory mounted: `/Users/rbha18/github/personal/roshbhatia/sysinit`
- Resources configured: 6 CPUs, 12GB RAM, 50GB disk

### What's Broken
- WezTerm SSH domain uses hardcoded IP:port (current: 127.0.0.1:62068, actual: 127.0.0.1:62451)
- Docker socket not mounted - `lima docker ps` fails
- 1Password socket not mounted - `lima op whoami` fails
- VM doesn't auto-start on macOS boot
- Running Ubuntu instead of NixOS (nixos-lima image boot failure)

### What's Incomplete
- Documentation needs updates (outdated PRD, incomplete usage guide)
- Old beads tasks need archival
- Template files need cleanup
- No validation tests automated

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Socket mount permissions | High | Both Docker and 1Password sockets require writable mounts, verified in testing |
| WezTerm connection fails after VM restart | Medium | Use Lima SSH alias (`lima-default`) instead of hardcoded IP:port |
| Lima port changes break WezTerm | Medium | FIXED by using `lima-default` SSH alias (Lima manages port automatically) |
| NixOS migration never happens | Low | Ubuntu is acceptable - VM still provides persistent Linux environment |
| VM auto-start fails silently | Medium | Test with reboot, verify launchd logs |
| Docker socket path incorrect | High | Verified Colima socket at `~/.colima/default/docker.sock` |

---

## Constraints & Assumptions

### Constraints
1. **macOS Only**: Cannot build NixOS from macOS (requires remote builder or binary cache)
2. **Lima Limitations**: Port changes on restart, socket mounts require directory-level mounts
3. **Team ID Stability**: `2BUA8C4S2C.com.1password` is stable, safe to hardcode
4. **No CLI Tool**: Decided against `bin/ascalon` wrapper, use `limactl` directly

### Assumptions
1. User is `rbha18` on both macOS and Lima VM
2. Home directory in VM is `/home/rbha18.linux/` (Lima convention)
3. Colima is running on macOS (Docker daemon)
4. 1Password app is running on macOS (agent socket)
5. WezTerm is primary terminal on macOS

---

## Dependencies

### Required
- Lima: VM management (installed, working)
- Colima: Docker daemon on macOS (installed, working)
- 1Password: CLI and agent (installed, working)
- WezTerm: Terminal emulator (installed, configured)

### Optional
- nixos-lima: For full NixOS integration (currently broken)
- NixOS ISO: Alternative to nixos-lima for manual NixOS setup

---

## Acceptance Criteria Checklist

Before marking this feature complete, verify:

**Phase 1 (WezTerm):**
- [ ] WezTerm CMD+S shows "ascalon" in domain picker
- [ ] WezTerm CMD+SHIFT+T spawns new tab in Ascalon
- [ ] Connection survives VM restart (uses lima-default SSH alias)

**Phase 2 (Sockets):**
- [ ] `lima docker ps` succeeds (connects to Colima)
- [ ] `lima docker run --rm hello-world` succeeds
- [ ] `lima op whoami` succeeds (connects to 1Password)
- [ ] `lima op item list` succeeds

**Phase 3 (Auto-Start):**
- [ ] VM auto-starts after macOS reboot
- [ ] `limactl list` shows "default" as "Running" after boot
- [ ] No manual intervention required

**Phase 4 (Documentation):**
- [ ] PRD accurately reflects current state
- [ ] Usage guide created and complete
- [ ] Troubleshooting section added
- [ ] All docs committed

**Phase 5 (Cleanup):**
- [ ] Old beads tasks archived
- [ ] Unused template files removed or documented
- [ ] `.sysinit/lessons.md` updated

**Phase 6 (Future - NixOS):**
- [ ] NixOS boots successfully in Lima
- [ ] `nixos-rebuild switch --flake .#ascalon` works
- [ ] VM hostname is "ascalon"
- [ ] nixos-lima services running (lima-init, lima-guestagent)

---

## Future Enhancements (Not in Scope)

### WezTerm Unix Domain Socket
- WezTerm daemon running in VM as systemd service
- Unix domain socket multiplexing (better than SSH)
- Persistent sessions survive network interruptions
- **Blocked by**: Requires NixOS with systemd service configuration

### Golden Image Parity
- Ascalon package set matches macOS exactly
- Same CLI tools, dev tools, language runtimes
- **Blocked by**: Requires NixOS with home-manager

### Advanced Features
- Multiple persistent VMs for different workflows
- VM snapshots for quick rollback
- Port forwarding for web services
- Automated backup/restore of VM state
- Integration with remote development servers

---

## References

### File Locations
- Lima config: `~/.lima/default/lima.yaml`
- Lima SSH config: `~/.lima/default/ssh.config`
- WezTerm config: `modules/darwin/home/wezterm/lua/sysinit/pkg/core.lua`
- WezTerm keybindings: `modules/darwin/home/wezterm/lua/sysinit/pkg/keybindings.lua`
- Ascalon NixOS config: `hosts/ascalon/default.nix`
- Builder logic: `lib/builders.nix`
- launchd plist: `~/Library/LaunchAgents/io.lima.default.plist`

### Socket Paths
- Docker: `~/.colima/default/docker.sock`
- 1Password: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock`

### Commands
- VM access: `lima`, `limactl shell default`, `ssh lima-default`
- VM lifecycle: `limactl list`, `limactl start default`, `limactl stop default`
- VM info: `limactl list`, `limactl show-ssh default`
- launchd: `launchctl load <plist>`, `launchctl unload <plist>`, `launchctl list | grep lima`

---

## Changelog

**2026-02-18 (Initial)**:
- Created PRD with full NixOS vision
- Defined architecture with WezTerm daemon
- Planned CLI tool and golden image parity

**2026-02-18 (Revised)**:
- Adjusted scope based on nixos-lima boot failure
- Accepted Ubuntu as temporary base OS
- Removed CLI tool from requirements (use limactl directly)
- Prioritized socket mounts and WezTerm connection fix
- Clarified naming strategy (default/ascalon/lima-default)
- Documented current state and blockers
- Split into phased approach with clear acceptance criteria
