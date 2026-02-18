# Ascalon VM Usage Guide

## Overview

Ascalon is a persistent Lima VM running Ubuntu (target: NixOS) that provides a consistent Linux development environment alongside macOS.

## Quick Start

### Starting Ascalon

```bash
limactl start ascalon
```

### Checking Status

```bash
limactl list
# or
limactl list ascalon
```

### Entering the VM

**Option 1: Via limactl**
```bash
limactl shell ascalon
```

**Option 2: Via WezTerm**
- Press `CMD+S` to open domain picker
- Select "ascalon" from the list
- Or press `CMD+SHIFT+T` to spawn a new tab directly in Ascalon

### Stopping the VM

```bash
limactl stop ascalon
```

### Restarting the VM

```bash
limactl stop ascalon && limactl start ascalon
```

## VM Configuration

**Resources:**
- CPUs: 4 (default Lima, can be configured to 6)
- Memory: 4GB (default Lima, can be configured to 12GB)
- Disk: 100GB (auto-expandable)
- SSH Port: Dynamic (check with `limactl list ascalon`)

**Mounted Directories:**
- `~/github/personal/roshbhatia/sysinit` → `/Users/rbha18/github/personal/roshbhatia/sysinit` (writable)

**User:**
- Username: `rbha18` (matches macOS user)
- Home: `/home/rbha18.linux/`
- Persistent across VM restarts

## WezTerm Integration

### Keybindings

| Keybinding | Action |
|------------|--------|
| `CMD+S` | Open domain picker (fuzzy search) |
| `CTRL+T` | New tab in current domain |
| `CMD+T` | New tab in current domain |
| `CTRL+SHIFT+T` | New tab in Ascalon domain |
| `CMD+SHIFT+T` | New tab in Ascalon domain |

### SSH Domain

Ascalon is configured as an SSH domain in WezTerm:
- Domain name: `ascalon`
- Connection: Via dynamic SSH port (managed by Lima)
- Multiplexing: Disabled (direct connection)

## File Persistence

**What persists:**
- `/home/rbha18.linux/` - User home directory
- All user files and configurations
- Package installations (within the VM)

**What doesn't persist:**
- System packages installed via `apt` (unless made persistent in future NixOS config)
- VM state before first login

## Common Tasks

### Accessing Mounted Repository

```bash
limactl shell ascalon
cd ~/github/personal/roshbhatia/sysinit  # Mounted from macOS
```

### Installing Packages (Ubuntu)

```bash
limactl shell ascalon
sudo apt update
sudo apt install <package>
```

### Checking SSH Port

```bash
limactl list ascalon
# Look for SSH column: 127.0.0.1:<port>
```

### Viewing Lima Logs

```bash
# Serial console logs
tail -f ~/.lima/ascalon/serial*.log

# Host agent logs
tail -f ~/.lima/ascalon/ha.stdout.log
tail -f ~/.lima/ascalon/ha.stderr.log
```

## Troubleshooting

### VM Won't Start

```bash
# Check status
limactl list ascalon

# View logs
cat ~/.lima/ascalon/ha.stderr.log

# Force delete and recreate
limactl delete ascalon --force
limactl start --name=ascalon templates/ascalon.yaml
```

### Can't Connect via WezTerm

1. Check SSH port changed: `limactl list ascalon`
2. SSH domain is configured for dynamic port resolution
3. Try direct connection: `limactl shell ascalon`
4. Restart WezTerm to refresh domain connections

### File Not Found in VM

Lima mounts directories at their macOS paths. Example:
- macOS: `~/github/personal/roshbhatia/sysinit`
- VM: `/Users/rbha18/github/personal/roshbhatia/sysinit`

User home in VM is `/home/rbha18.linux/`, not `/home/rbha18/`.

### Port Conflicts

Lima automatically assigns available ports. If you need a specific port:

```bash
limactl stop ascalon
# Edit ~/.lima/ascalon/lima.yaml
# Change ssh.localPort to desired port
limactl start ascalon
```

## Planned Features

### When NixOS is Working

Once nixos-lima image issues are resolved:
- Declarative NixOS configuration via sysinit repo
- `nixos-rebuild switch --flake .#ascalon` from within VM
- Full parity with macOS package set
- Home-manager integration

### WezTerm Daemon (Future)

When WezTerm daemon multiplexing is implemented:
- Persistent terminal sessions in VM
- Reconnect to sessions after VM restart
- Better performance than SSH-based connection

## Advanced Configuration

### Customize Resources

Edit `templates/ascalon.yaml`:

```yaml
cpus: 6
memory: "12GiB"
disk: "50GiB"
```

Then recreate:

```bash
limactl delete ascalon --force
limactl start --name=ascalon templates/ascalon.yaml
```

### Add More Mounts

Edit `~/.lima/ascalon/lima.yaml`:

```yaml
mounts:
  - location: "~/Projects"
    writable: true
```

Then restart:

```bash
limactl stop ascalon
limactl start ascalon
```

### Enable Auto-Start on macOS Boot

Lima doesn't support autostart directly, but you can use macOS launchd:

```bash
# Create ~/Library/LaunchAgents/io.lima.ascalon.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>io.lima.ascalon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/limactl</string>
        <string>start</string>
        <string>ascalon</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>

# Load the agent
launchctl load ~/Library/LaunchAgents/io.lima.ascalon.plist
```

## Tips

1. **Fast Access**: Add alias to shell: `alias ascalon='limactl shell ascalon'`
2. **Check Before Work**: Always `limactl list` to see current SSH port
3. **Persistence**: Store important data in `/home/rbha18.linux/`, not `/tmp/`
4. **Synced Configs**: Use sysinit mount to access dotfiles from macOS
5. **WezTerm Picker**: `CMD+S` is fastest way to switch between local and Ascalon

## Resources

- [Lima Documentation](https://lima-vm.io/docs/)
- [WezTerm SSH Domains](https://wezfurlong.org/wezterm/multiplexing.html)
- [Ascalon PRD](./ascalon-persistent-vm.md)
