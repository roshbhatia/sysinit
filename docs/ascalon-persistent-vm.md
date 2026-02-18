# PRD: Ascalon Persistent NixOS VM

**Status**: In Progress  
**Created**: 2026-02-18  
**Owner**: Rosh Bhatia

---

## Problem Statement

Currently, development work is split between:
- macOS host (lv426) - Full GUI environment, heavy resource usage
- Ephemeral project VMs - Created per-project via flake templates, no persistence

**Pain Points**:
1. No persistent Linux development environment
2. WezTerm runs on macOS, not designed for remote multiplexing
3. Cannot switch between macOS GUI and headless VM workflow seamlessly
4. Project VMs are ephemeral - lose state on rebuild
5. Inconsistent environments between macOS and Linux VMs

---

## Goals

### Primary Goals
1. **Persistent VM**: Single long-running NixOS VM that survives rebuilds
2. **Golden Image Parity**: Ascalon mirrors macOS environment (same packages, same config)
3. **WezTerm Daemon**: WezTerm runs as daemon in VM, macOS GUI connects via socket
4. **Auto-start**: VM starts automatically on macOS boot
5. **Socket Sharing**: Docker, 1Password, WezTerm sockets mounted from macOS

### Non-Goals
1. Not replacing macOS as primary environment
2. Not running GUI applications in VM
3. Not replacing per-project ephemeral VMs (those remain for testing)
4. Not multi-VM management (single persistent VM only)

---

## Success Criteria

### Must Have (P0)
- [ ] Ascalon VM builds successfully via `nix build .#nixosConfigurations.ascalon.config.system.build.toplevel`
- [ ] Ascalon uses full NixOS (not Ubuntu + home-manager)
- [ ] nixos-lima integration working (lima-init, lima-guestagent services)
- [ ] Lima YAML configuration created at `~/.lima/ascalon/lima.yaml`
- [ ] VM auto-starts on macOS boot
- [ ] `/home/dev` persists across VM rebuilds
- [ ] Docker CLI in VM connects to macOS Colima socket
- [ ] 1Password CLI in VM works via mounted socket
- [ ] Can enter VM via `limactl shell ascalon` or `ascalon` CLI tool
- [ ] `nixos-rebuild switch --flake .#ascalon` works inside VM

### Should Have (P1)
- [ ] WezTerm daemon runs in VM as systemd service
- [ ] WezTerm GUI on macOS connects to VM daemon via unix socket
- [ ] `ascalon` CLI tool with commands: shell, status, start, stop, restart, rebuild, destroy
- [ ] Ascalon has same packages as macOS (cli-tools, dev-tools, language-managers, language-runtimes)
- [ ] Resource limits configured: 6 CPUs, 12GB RAM, 50GB disk
- [ ] VM hostname set to "ascalon"
- [ ] SSH access works from macOS

### Nice to Have (P2)
- [ ] Port forwarding configured via lima-guestagent
- [ ] Shared filesystem mount for projects (e.g., ~/Projects)
- [ ] Documentation in docs/ascalon-vm-usage.md
- [ ] Automated tests for VM build/start/connect workflow

---

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  macOS Host (lv426)                                         │
│  - Full environment: CLI tools, dev tools, language runtimes│
│  - Colima: Docker daemon                                    │
│  - Lima: VM manager                                         │
│  - WezTerm GUI: Connects to Ascalon daemon                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          │ Mounts shared via Lima:
                          │ - /var/run/docker.sock → Colima
                          │ - 1Password agent socket
                          │ - WezTerm daemon socket
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Ascalon - Full NixOS VM (via nixos-lima)                  │
│  - nixos-lima module: lima-init + lima-guestagent          │
│  - WezTerm daemon (systemd service)                        │
│  - Docker CLI → macOS Colima socket                        │
│  - 1Password CLI → macOS agent socket                      │
│  - Language runtimes: Node, Python, Go, Rust, Bun          │
│  - Same config as macOS (golden image parity)              │
│  - Persistent /home/dev across rebuilds                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. NixOS Configuration (`hosts/ascalon/default.nix`)
- Full NixOS system (not Ubuntu)
- nixos-lima integration via flake input
- QEMU guest profile
- Boot configuration for Lima/QEMU
- Persistent filesystems with auto-resize
- Home-manager configuration for `dev` user
- Same package imports as macOS

#### 2. Lima Configuration (`~/.lima/ascalon/lima.yaml`)
- Base image: nixos-lima pre-built QCOW2
- Resources: 6 CPUs, 12GB RAM, 50GB disk
- Socket mounts:
  - Docker: `~/.colima/default/docker.sock` → `/var/run/docker.sock`
  - 1Password: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
  - WezTerm: `~/.local/share/wezterm/wezterm.sock`
- Provisioning script: `nixos-rebuild boot --flake .#ascalon`
- Auto-start: `autostart: true`

#### 3. WezTerm Daemon Module (`modules/nixos/home/wezterm-daemon/`)
- Systemd user service: `wezterm-daemon.service`
- Unix domain socket configuration
- Auto-start on login
- WezTerm config for daemon mode

#### 4. macOS WezTerm Integration (`modules/darwin/home/wezterm/`)
- Unix domain configuration pointing to Lima socket
- Keybinding: CMD+SHIFT+A to attach to Ascalon
- Automatic connection on startup (optional)

#### 5. CLI Tool (`bin/ascalon`)
- Wrapper around `limactl` commands
- Subcommands: shell, status, start, stop, restart, rebuild, destroy
- Installed via home-manager on macOS

### Package Distribution

| Package Category | macOS | Ascalon | Ephemeral VMs |
|-----------------|-------|---------|---------------|
| cli-tools | ✓ | ✓ | ✓ |
| dev-tools | ✓ | ✓ | ✓ |
| language-managers | ✓ | ✓ | ✓ |
| language-runtimes | ✓ | ✓ | - (use shell.nix) |
| macos-tools | ✓ | - | - |

### File Structure

```
sysinit/
├── flake.nix                          # Add nixos-lima input
├── hosts/
│   ├── ascalon/
│   │   ├── default.nix                # NixOS configuration
│   │   └── values.nix                 # Host-specific values
│   └── _base/
│       └── nixos.nix                  # Base NixOS config
├── modules/
│   ├── home/packages/                 # Package categories (already done)
│   └── nixos/home/
│       └── wezterm-daemon/            # WezTerm daemon module (new)
│           └── default.nix
├── lib/
│   └── builders.nix                   # Add nixos-lima module import
├── bin/
│   └── ascalon                        # CLI tool (new)
├── templates/
│   └── ascalon.yaml                   # Lima YAML template (new)
└── docs/
    ├── ascalon-persistent-vm.md       # This PRD
    └── ascalon-vm-usage.md            # Usage guide (future)
```

---

## Implementation Plan

### Phase 1: Core VM Build (P0)
1. Fix lib import in `hosts/ascalon/default.nix` ✓
2. Resolve NixOS build errors
3. Validate `nix build .#nixosConfigurations.ascalon` succeeds
4. Commit working NixOS configuration

### Phase 2: Lima Integration (P0)
1. Create `templates/ascalon.yaml` Lima configuration
2. Test VM creation: `limactl start --name=ascalon templates/ascalon.yaml`
3. Verify SSH access
4. Test socket mounts (Docker, 1Password)
5. Verify `/home` persistence across rebuilds

### Phase 3: WezTerm Daemon (P1)
1. Create `modules/nixos/home/wezterm-daemon/default.nix`
2. Add systemd service for WezTerm daemon
3. Mount WezTerm socket via Lima YAML
4. Configure macOS WezTerm to connect to VM
5. Test multiplexing workflow

### Phase 4: CLI Tool (P1)
1. Create `bin/ascalon` shell script
2. Implement subcommands: shell, status, start, stop, restart, rebuild, destroy
3. Install via home-manager on macOS
4. Test all commands

### Phase 5: Documentation (P2)
1. Create usage guide: `docs/ascalon-vm-usage.md`
2. Add troubleshooting section
3. Document workflow differences vs macOS

---

## Testing Strategy

### Build Testing
```bash
# Test NixOS configuration builds
nix build .#nixosConfigurations.ascalon.config.system.build.toplevel

# Test flake validation
nix flake check
```

### VM Testing
```bash
# Create VM
limactl start --name=ascalon templates/ascalon.yaml

# Enter VM
limactl shell ascalon

# Test inside VM
docker ps                    # Should connect to Colima
op --version                 # Should connect to 1Password
whoami                       # Should be 'dev'
```

### Persistence Testing
```bash
# Create test file
echo "test" > /home/dev/test.txt

# Rebuild VM
nixos-rebuild switch --flake ~/sysinit#ascalon

# Verify file persists
cat /home/dev/test.txt       # Should still exist
```

### WezTerm Testing
```bash
# From macOS WezTerm
# Press CMD+SHIFT+A
# Should attach to Ascalon sessions
```

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| nixos-lima build failures | High | Use pre-built images, debug step-by-step |
| Socket mount permissions | Medium | Test with Lima examples, use proper user mapping |
| VM performance issues | Medium | Configure resource limits, monitor usage |
| WezTerm socket connection fails | Medium | Fall back to SSH-based connection initially |
| State loss on rebuild | High | Separate /home from system partition, test persistence |

---

## Open Questions

1. **Image distribution**: Use pre-built nixos-lima images or build custom?
   - **Decision**: Start with pre-built, customize via Lima YAML provisioning

2. **Project file sharing**: Mount ~/Projects from macOS or keep separate?
   - **Decision**: Keep separate initially, add mount in Phase 5 if needed

3. **Multiple VMs**: Support multiple persistent VMs or just one?
   - **Decision**: Single VM (Ascalon) only, use ephemeral VMs for projects

4. **WezTerm socket location**: Where to mount in VM?
   - **Decision**: Default location `~/.local/share/wezterm/wezterm.sock`

---

## Dependencies

- nixos-lima flake: `github:nixos-lima/nixos-lima`
- Lima installed on macOS (already available)
- Colima running on macOS (already configured)
- 1Password CLI installed (already available)
- WezTerm installed (already configured)

---

## Acceptance Criteria Checklist

Before marking this feature complete, verify:

- [ ] All P0 criteria met (Must Have)
- [ ] All P1 criteria met (Should Have)
- [ ] VM builds without errors
- [ ] VM starts automatically on macOS boot
- [ ] Can connect via `ascalon` CLI tool
- [ ] Docker commands work in VM
- [ ] 1Password CLI works in VM
- [ ] WezTerm GUI connects to VM daemon
- [ ] `/home/dev` persists across rebuilds
- [ ] Documentation complete
- [ ] No regressions on macOS host (lv426)
- [ ] Work machine compatibility verified (APKR2N5D495296)

---

## Future Enhancements (Not in Scope)

- Multi-VM management interface
- GUI application support via X11/Wayland forwarding
- Automated backup/restore of VM state
- Integration with remote development servers
- VM snapshots for quick rollback
