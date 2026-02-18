# PRD: Lima Persistent Development VM

**Status**: Implementation  
**Created**: 2026-02-18  
**Updated**: 2026-02-18  
**Owner**: Rosh Bhatia

---

## Problem Statement

Development workflow requires a persistent Linux environment alongside macOS:
- macOS (lv426/vorgossos) - Primary GUI environment
- Linux environment needed for Docker workflows, NixOS testing, cross-platform dev

---

## Solution

A Lima VM per environment running NixOS, managed through sysinit's flake:

| Environment | macOS Host | Lima VM | NixOS Hostname |
|-------------|------------|---------|----------------|
| Personal | lv426 | default | nostromo |
| Work | vorgossos | default | demiurge |

### Architecture

```
macOS Host (lv426 or vorgossos)
  |
  +-- Lima VM "default"
        |
        +-- NixOS (via nixos-lima image)
              |
              +-- Configuration: sysinit#nostromo (or work-sysinit#demiurge)
              +-- services.lima.enable = true (lima-init, lima-guestagent)
              +-- Mounts: sysinit repo, Docker socket, 1Password socket
```

### nixos-lima Integration

We leverage [nixos-lima](https://github.com/nixos-lima/nixos-lima) which provides:

1. **Pre-built NixOS image**: `nixos-lima-v0.0.4-aarch64.qcow2`
2. **NixOS module**: `nixosModules.lima` with services for Lima guest support
3. **Setup pattern**: Mount config repo, run `nixos-rebuild --flake`

Our integration in `lib/builders.nix`:

```nix
# When isLima=true, include Lima modules
++ lib.optionals (hostConfig.isLima or false) [
  inputs.nixos-lima.nixosModules.lima  # Provides services.lima
  ../modules/nixos/configurations/lima.nix  # Our boot/filesystem config
]
```

Our `modules/nixos/configurations/lima.nix`:

```nix
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  
  # Enable Lima guest services (lima-init, lima-guestagent)
  services.lima.enable = true;
  
  # Boot config matching nixos-lima image layout
  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
```

---

## Host Configuration

### Personal Flake (hosts/default.nix)

```nix
{
  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    isLima = true;
    username = "rshnbhatia";
    values = {
      hostname = "nostromo";
      theme = { ... };
      git = { ... };
    };
  };
}
```

### Work Flake

```nix
{
  demiurge = {
    system = "aarch64-linux";
    platform = "linux";
    isLima = true;
    username = "rbha18";
    values = {
      hostname = "demiurge";
      theme = { ... };
      git = { ... };
    };
  };
}
```

---

## Lima VM Configuration

### lima.yaml (Personal)

**Location**: `~/.lima/default/lima.yaml`

```yaml
images:
  - location: "https://github.com/nixos-lima/nixos-lima/releases/download/v0.0.4/nixos-lima-v0.0.4-aarch64.qcow2"
    arch: "aarch64"
    digest: "sha512:a274d225c41918da7f1bb0bc1fde8cc713ed0d36954c21cc26ae403d47879a00f4c3d5601c67c647df87f6f321e1b694140b671910b15a011872311b960569b2"

cpus: 6
memory: "12GiB"
disk: "100GiB"

mounts:
  # Sysinit repo (for nixos-rebuild --flake)
  - location: "~/github/personal/roshbhatia/sysinit"
    writable: true
    9p:
      cache: "mmap"
  
  # Docker socket (Colima)
  - location: "~/.colima/default"
    writable: true
    9p:
      cache: "mmap"
  
  # 1Password socket
  - location: "~/Library/Group Containers/2BUA8C4S2C.com.1password/t"
    writable: true
    9p:
      cache: "mmap"

ssh:
  loadDotSSHPubKeys: true
  forwardAgent: true

containerd:
  system: false
  user: false
```

---

## Setup Procedure

### Initial VM Creation

```bash
# Create Lima VM with NixOS image
limactl start --name=default ~/.lima/default/lima.yaml

# Verify NixOS is running
lima cat /etc/os-release  # Should show NixOS
```

### Apply NixOS Configuration

```bash
# From macOS host - apply sysinit NixOS config
limactl shell default -- sudo nixos-rebuild boot \
  --flake /Users/rshnbhatia/github/personal/roshbhatia/sysinit#nostromo

# Restart to apply
limactl stop default && limactl start default

# Verify hostname
lima hostname  # Should show "nostromo"
```

### For Work VM

```bash
# Apply work config
limactl shell default -- sudo nixos-rebuild boot \
  --flake /Users/rbha18/github/work/rbha18_nike/sysinit#demiurge

limactl stop default && limactl start default
lima hostname  # Should show "demiurge"
```

---

## WezTerm Integration

### SSH Domain Configuration

**Location**: `modules/home/configurations/wezterm/lua/sysinit/pkg/core.lua`

```lua
ssh_domains = {
  {
    name = "nostromo",  -- User-facing name in WezTerm
    remote_address = "lima-default",  -- Lima's auto-generated SSH alias
    username = utils.get_username(),
    multiplexing = "None",
  },
}
```

### Keybindings

```lua
CMD+S              -> ShowLauncherArgs({ flags = "FUZZY|DOMAINS" })  -- Domain picker
CMD+SHIFT+T        -> SpawnTab({ DomainName = "nostromo" })          -- New tab in VM
```

---

## Auto-Start (launchd)

**Location**: `~/Library/LaunchAgents/io.lima.default.plist`

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

```bash
launchctl load ~/Library/LaunchAgents/io.lima.default.plist
```

---

## Current State

### What's Done
- [x] Lima VM "default" exists and runs
- [x] Lima yaml has mounts configured (sysinit, Docker, 1Password)
- [x] `hosts/default.nix` defines nostromo with `isLima = true`
- [x] `lib/builders.nix` includes nixos-lima module when `isLima`
- [x] `modules/nixos/configurations/lima.nix` has boot/filesystem config

### What's Incomplete
- [ ] `lima.nix` missing `services.lima.enable = true`
- [ ] VM currently running Ubuntu (needs recreate with NixOS image)
- [ ] WezTerm SSH domain hardcodes IP:port instead of `lima-default`
- [ ] Auto-start launchd plist not created
- [ ] Work flake needs hostname in values

---

## Implementation Tasks

### Phase 1: Fix lima.nix

Add `services.lima.enable = true` to enable Lima guest services.

### Phase 2: Code Cleanup (Personal Repo)

1. Delete `lib/vm-shell.nix` (unused)
2. Delete `templates/` directory (work flake is canonical example)
3. Remove `hostConfig.config` support from `lib/builders.nix`
4. Delete old PRD `docs/ascalon-persistent-vm.md`

### Phase 3: Work Flake Updates

1. Add `hostname` to values for vorgossos and demiurge
2. Remove `config = ./hosts/*.nix` from host definitions
3. Delete `hosts/vorgossos.nix` and `hosts/demiurge.nix`

### Phase 4: Recreate Lima VM

1. Stop and delete current VM
2. Create new VM with nixos-lima image
3. Apply nostromo configuration
4. Verify NixOS boots and services work

### Phase 5: WezTerm + launchd

1. Update SSH domain to use `lima-default`
2. Create and load launchd plist

---

## Validation

```bash
# NixOS verification
lima cat /etc/os-release         # Should show NixOS
lima hostname                    # Should show "nostromo"
lima systemctl status lima-init  # Should be active

# Socket verification
lima docker ps                   # Should connect to Colima
lima op whoami                   # Should connect to 1Password

# WezTerm verification
# CMD+S -> select "nostromo" -> should connect

# Persistence verification
lima bash -c "echo test > ~/persist-check"
limactl stop default && limactl start default
lima cat ~/persist-check         # Should show "test"
```

---

## Success Criteria

### P0 - Must Have
- [ ] NixOS VM running via nixos-lima
- [ ] `services.lima.enable = true` active
- [ ] Docker socket working (`lima docker ps`)
- [ ] 1Password socket working (`lima op whoami`)
- [ ] VM persists data across restarts

### P1 - Should Have
- [ ] WezTerm SSH domain connects via `lima-default`
- [ ] Auto-start on macOS boot
- [ ] Work flake demiurge config works

### P2 - Nice to Have
- [ ] Home-manager integration in VM
- [ ] Full dev tooling parity with macOS

---

## References

### nixos-lima Resources
- Repo: https://github.com/nixos-lima/nixos-lima
- Config Sample: https://github.com/nixos-lima/nixos-lima-config-sample
- Image: `nixos-lima-v0.0.4-aarch64.qcow2`

### File Locations
| Purpose | Path |
|---------|------|
| Host definitions | `hosts/default.nix` |
| Builder logic | `lib/builders.nix` |
| Lima NixOS module | `modules/nixos/configurations/lima.nix` |
| System config | `modules/nixos/configurations/system.nix` |
| WezTerm config | `modules/home/configurations/wezterm/` |
| Lima VM config | `~/.lima/default/lima.yaml` |

### Socket Paths
| Socket | macOS Path |
|--------|------------|
| Docker | `~/.colima/default/docker.sock` |
| 1Password | `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/s.sock` |
