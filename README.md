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

## Quick Start

### Build and Apply Configuration

```bash
# First install (if nh not yet available)
nix run nixpkgs#nh -- darwin switch

# After first install, use nh directly
nh darwin build   # Build configuration (test without applying)
nh darwin switch  # Apply configuration to system

# Update flake inputs
nix flake update

# Format Nix files
nixfmt **/*.nix

# Validate flake
nix flake check
```

### Work Repository

For work-specific configurations, see the work repo which consumes this flake as an input.
