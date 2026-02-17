# PRD Updates Summary

## Changes Made (Feb 17, 2026)

### PRD-05: Project-Scoped VM Management
**Major architectural change**: Replaced CLI-based approach with direnv/shell.nix hook-based approach.

**Old approach**: Manual `sysinit-vm` CLI tool
- User runs `sysinit-vm init`, `sysinit-vm start`, `sysinit-vm shell`
- Requires remembering commands
- Bash script with manual orchestration

**New approach**: Automatic via Nix flake templates + direnv
- User runs `nix flake init -t github:user/sysinit#vm-dev`
- direnv auto-loads on `cd`
- VM auto-creates, auto-starts, auto-enters
- Zero manual commands for normal workflow
- Nix-native, composable, team-friendly

**Key components**:
- `lib/vm-shell.nix`: Nix library with VM lifecycle functions
- `templates/vm-dev/`: Full dev template with shell.nix
- `templates/vm-minimal/`: Lightweight template
- Enhanced direnv config with VM detection

### Arrakis Removal
Removed references to `arrakis` NixOS host configuration throughout PRDs:
- PRD-00: Removed from non-goals
- PRD-01: Removed arrakis configuration examples and tests
- PRD-02: Removed arrakis build validation
- PRD-03: Removed arrakis regression tests
- PRD-06: Removed from out-of-scope

**Rationale**: arrakis was a NixOS desktop system no longer in use. Lima VMs (PRD-03) will provide NixOS environments going forward.

## Implementation Status

All PRDs remain **Not Started**. These are documentation-only updates to clarify the architectural approach before beginning implementation.

## Next Steps

1. Review updated PRD-05 approach
2. Confirm direnv/shell.nix workflow meets requirements
3. Begin PRD-01 implementation when ready
