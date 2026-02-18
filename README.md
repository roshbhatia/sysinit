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
nh darwin build   # Build configuration (test without applying)
nh darwin switch  # Apply configuration to system

# Flake operations
nix flake update  # Update flake inputs
nix flake check   # Validate flake

# Format Nix files
nixfmt **/*.nix

# Cleanup old generations
nh clean all
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
