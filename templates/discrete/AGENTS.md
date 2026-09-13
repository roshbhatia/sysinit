# AGENTS.md

Nix-flakes configuration for discrete host setup consuming `roshbhatia/sysinit`.

## Minimal Nix flake layout
- `flake.nix` - Entry point consuming sysinit as input
- `hosts/` - Host configuration (update `default.nix` for your system)
- `modules/` - Host-specific module overrides (darwin, nixos, overlays)
- `AGENTS.md` - This file

## Essential Commands

### Build/Test/Apply
```bash
nix flake check               # Validate flake configuration
nh darwin build .#<hostname>  # Build a macOS configuration
nh darwin switch .#<hostname> # Apply a macOS configuration
nh os build .#<hostname>      # Build a NixOS configuration
nh os switch .#<hostname>     # Apply a NixOS configuration
```

### Format/Lint
```bash
nix fmt                       # Format all Nix files
nixfmt *.nix                  # Format specific Nix files
```

### Maintenance
```bash
nix flake update              # Update flake inputs
nix flake update sysinit      # Update only the sysinit input
nix profile history           # View generation history
nix-collect-garbage -d        # Cleanup old generations
```

## Before a commit

Run `nix fmt`, then `nix flake check`, then the `build` command for the host
kind you changed.

## Inheriting from sysinit

This flake consumes `roshbhatia/sysinit` and can:
- Override modules in `modules/darwin/` and `modules/nixos/`
- Add overlays in `overlays/default.nix`
- Customize host values in `hosts/default.nix`

See sysinit's AGENTS.md and README.md for more details on the base configuration.
