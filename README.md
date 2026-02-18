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

## Quick Start

### Build and Apply Configuration

```bash
# First install (if nh not yet available)
nix run nixpkgs#nh -- darwin switch

# After first install, use nh directly
nh darwin build                    # Build configuration (test without applying)
nh darwin switch                   # Apply configuration to system
nh darwin switch --hostname lv426  # Specify hostname (auto-detects if omitted)

# For discrete host repos consuming sysinit
nh darwin switch --refresh sysinit --commit-lock-file  # Update sysinit input and commit lock

# Flake operations
nix flake update  # Update all flake inputs
nix flake check   # Validate flake

# Format Nix files
nixfmt **/*.nix

# Cleanup old generations
nh clean all
```

### Lima NixOS VM

```bash
# Start Lima VM
limactl start --name=default lima.yaml

# Build and apply NixOS configuration
nh os switch --hostname yourhostname-vm

# Or specify the flake explicitly
nh os switch --configuration yourhostname-vm
```

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations:

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```

This creates a minimal flake that:
- Follows all inputs from sysinit for consistency
- Provides host-specific values (username, git config, theme, etc.)
- Can add host-specific modules and overlays
- Keeps sensitive/work-specific configuration separate from the main sysinit repo
