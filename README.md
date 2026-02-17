# sysinit

```ascii
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖
          ▜███▙       ▜███▙  ▟███▛
           ▜███▙       ▜███▙▟███▛
            ▜███▙       ▜██████▛
     ▟█████████████████▙ ▜████▛     ▟▙
    ▟███████████████████▙ ▜███▙    ▟██▙
           ▄▄▄▄▖           ▜███▙  ▟███▛
          ▟███▛             ▜██▛ ▟███▛
         ▟███▛               ▜▛ ▟███▛
▟███████████▛                  ▟██████████▙
▜██████████▛                  ▟███████████▛
      ▟███▛ ▟▙               ▟███▛
     ▟███▛ ▟██▙             ▟███▛
    ▟███▛  ▜███▙           ▝▀▀▀▀
    ▜██▛    ▜███▙ ▜██████████████████▛
     ▜▛     ▟████▙ ▜████████████████▛
           ▟██████▙       ▜███▙
          ▟███▛▜███▙       ▜███▙
         ▟███▛  ▜███▙       ▜███▙
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘
```

This comprises most of my dotfiles, managed (mostly) by `nix`.

## Structure

- `flake.nix` - Flake entry point
- `hosts/` - Per-host configurations (lv426, lima-dev, lima-minimal)
- `lib/` - Nix builder functions and utilities
- `modules/` - Reusable NixOS/Darwin/home-manager modules
- `profiles/` - Reusable configuration bundles
- `pkgs/` - Custom package definitions
- `templates/` - Project templates (VM dev environments)
- `hack/` - Build and maintenance scripts

## Install Dependencies

```bash
xcode-select --install && \
/bin/bash -c "$(curl -fsSL \
https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
eval "$(/opt/homebrew/bin/brew shellenv)" && \
brew install go-task/tap/go-task
```

## Installing Neovim only 

```bash
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/setup/neovim.sh | bash
```

## Quick Start

### System Configuration
```bash
task nix:build      # Build configuration (test without applying)
task nix:refresh    # Apply configuration changes
task nix:update     # Update dependencies
task fmt            # Format all code

# See all available tasks
task --list
```

### Development VMs

Add automatic VM management to any project:

```bash
# In your project directory
curl -fsSL https://raw.githubusercontent.com/roshbhatia/sysinit/main/vm.nix > vm.nix
echo "use nix vm.nix" >> .envrc
direnv allow

# VM auto-creates and connects on first directory entry
```

**What happens:**
- VM auto-creates on first `cd` to directory
- VM auto-starts if stopped
- Project directory mounted in VM at same path
- Automatically imports existing `shell.nix` dependencies if present

**Customize VM resources** (edit `vm.nix`):
```nix
cpus = 8;           # Default: 4
memory = "16GiB";   # Default: 8GiB
ports = [3000];     # Default: [3000 8080 5173 5432]
```

**Disable auto-entry** (in `.envrc`):
```bash
export SYSINIT_NO_AUTO_VM=1
```

**Manual VM controls:**
```bash
limactl list                  # Show all VMs
limactl stop <project>-dev    # Stop VM
limactl delete <project>-dev  # Delete VM
```
