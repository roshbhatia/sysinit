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

# Regular use (with NH_FLAKE set)
nh darwin switch                                              # Apply configuration
nh darwin switch --refresh --commit-lock-file                 # Update inputs and commit
nh darwin test                                                # Test without activation
nh darwin build                                               # Build without activation

# Cleanup
nh clean all                                                  # Clean old generations
nh clean all --keep 3 --keep-since 7d                         # Keep last 3 or within 7 days
```

### Environment Variables

Set these in your shell or via the NixOS/home-manager module:

```bash
export NH_FLAKE="$HOME/path/to/flake"      # Auto-detect flake location
export NH_SHOW_ACTIVATION_LOGS=1           # Show activation output (useful for debugging)
```

### Lima NixOS VM

```bash
# Start Lima VM
limactl start --name=default lima.yaml

# Build and apply NixOS configuration
lima -- nh os switch --refresh '#nostromo'
lima -- nh os test                          # Test without activation
```

### Creating a Discrete Host Repository

To create a separate repository that consumes this flake for host-specific configurations (i.e., my work machine):

```bash
nix flake init -t github:roshbhatia/sysinit#discrete
```

