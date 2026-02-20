# AGENTS.md

Nix-flakes configuration for discrete host setup consuming `roshbhatia/sysinit`.

## Repository Structure

**Minimal Nix flake layout:**
- `flake.nix` - Entry point consuming sysinit as input
- `hosts/` - Host configuration (update `default.nix` for your system)
- `modules/` - Host-specific module overrides (darwin, nixos, overlays)
- `lima.yaml` - Optional Lima VM configuration
- `AGENTS.md` - This file

## Essential Commands

### Build/Test/Apply
```bash
nix flake check               # Validate flake configuration
nh os build                   # Test current system config (macOS)
nh os switch                  # Apply current config to system (use with caution)
nh os build .#<hostname>      # Build NixOS configuration
nh os switch .#<hostname>     # Apply NixOS configuration
```

### Format/Lint
```bash
nix fmt                       # Format all Nix files
nixfmt *.nix                  # Format specific Nix files
```

### Maintenance
```bash
nix flake update              # Update flake inputs
nix flake lock --update-input sysinit  # Update just sysinit
nix profile history           # View generation history
nix-collect-garbage -d        # Cleanup old generations
```

## Always-Followed Rules

- **No Emojis**: Strictly enforced in all code and documentation
- **DRY**: Extract repeated patterns to shared utilities
- **Comments**: Use for complex logic only
- **Testing**: Run `nix flake check` before commits
- **Pre-Commit**: `nix fmt` then `nix flake check` then `nh os build`

## Lima VM Setup

1. Create persistent storage:
   ```bash
   mkdir -p ~/.local/share/lima/<hostname>-nix
   ```

2. Create and start instance:
   ```bash
   limactl create --name=<hostname> lima.yaml
   limactl start <hostname>
   ```

3. Configure from inside VM:
   ```bash
   limactl shell <hostname>
   cd /path/to/repo
   nh os switch '.#nixosConfigurations.<hostname>'
   ```

## Inheriting from sysinit

This flake consumes `roshbhatia/sysinit` and can:
- Override modules in `modules/darwin/` and `modules/nixos/`
- Add overlays in `overlays/default.nix`
- Customize host values in `hosts/default.nix`

See sysinit's AGENTS.md and README.md for more details on the base configuration.
