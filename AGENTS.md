# AGENTS.md

Nix-flakes configuration for macOS (Apple Silicon) and NixOS. Reproducible system setup via nix-darwin + home-manager.

## Repository Structure

**Idiomatic Nix flake layout:**
- `flake.nix` - Entry point defining inputs and outputs
- `hosts/` - Per-host configuration directories (lv426, lima-dev, lima-minimal)
  - Each host has `default.nix` (config) and `values.nix` (host-specific values)
- `lib/` - Builder functions and utilities (builders.nix, common.nix, output-builders.nix)
- `modules/` - Reusable modules organized by platform (darwin, nixos, home, shared)
- `profiles/` - Configuration bundles (base, desktop, dev-full, dev-minimal, host-minimal)
- `pkgs/` - Custom package definitions
- `templates/` - Flake templates for VM dev environments

## Essential Commands

### Build/Test/Apply
```bash
nix flake check               # Validate flake configuration
nh os build                   # Test current system config (macOS)
nh os switch                  # Apply current config to system (use with caution)
nh os build .#nostromo        # Build NixOS configuration
nh os switch .#nostromo       # Apply NixOS configuration
```

### Format/Lint
```bash
nix fmt                       # Format all Nix files
nixfmt *.nix                  # Format specific Nix files
```

### Maintenance
```bash
nix flake update              # Update flake inputs
nix profile history           # View generation history
nix-collect-garbage -d        # Cleanup old generations
```

## Always-Followed Rules

- **No Emojis**: Strictly enforced in all code and documentation
- **DRY**: Extract repeated patterns to shared utilities
- **Comments**: Use for complex logic only
- **Testing**: Run `nix flake check` before commits
- **Pre-Commit**: `nix fmt` then `nix flake check` then `nh os build`

## Task & Feature Management
- **Context**: Check `.sysinit/lessons.md` at session start for prior learnings (gitignored scratch space).

## Skills

Domain-specific knowledge is managed as Nix-defined skills in `modules/home/configurations/llm/skills/`. Each skill is a `.nix` file returning SKILL.md content, built into the Nix store alongside external superpowers skills. Skills are loaded on demand by LLM tools.

| Skill | When to use |
|-------|-------------|
| `nix-development` | Writing or modifying Nix code, module patterns, flake structure |
| `lua-development` | Writing or modifying Lua code for Neovim, WezTerm, Hammerspoon |
| `shell-scripting` | Writing or modifying shell scripts in `hack/` or elsewhere |
| `session-completion` | Ending a work session, pushing changes, handing off context |
