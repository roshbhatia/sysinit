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
- `hack/` - Build/format/maintenance scripts called by Taskfile

## Essential Commands

### Build/Test/Apply
```bash
task nix:build                # Test current system config (default: lv426/macOS)
task nix:build:lv426          # Build/test macOS config specifically
task nix:build:all            # Build all system configurations
task nix:build:work           # Dry-run build for work config (reduced resources)
task nix:refresh              # Apply current config to system (use with caution)
task nix:refresh:lv426        # Apply macOS config
task nix:refresh:work         # Apply work config
```

### Format/Lint
```bash
task fmt                      # Format all (Nix, Lua, Shell)
task fmt:nix                  # Format Nix files only
task fmt:nix:check            # Check Nix formatting (no changes)
task fmt:lua                  # Format Lua files only
task fmt:lua:check            # Check Lua formatting (no changes)
task fmt:lua:lint             # Run LSP diagnostics on Lua
task fmt:lua:validate         # Full Lua validation (format + lint)
task fmt:sh                   # Format shell scripts
task fmt:sh:check             # Check shell formatting (no changes)
task fmt:all:check            # Check all formatting without changes
```

### Validation/Testing
```bash
task nix:validate             # Validate flake configuration
nix flake check               # Direct flake validation
```

### Maintenance
```bash
task nix:update               # Update flake inputs and commit
task nix:clean                # Cleanup old generations
task nix:config               # Copy nix configs to /etc/nix/
task nix:config:user          # Setup user-level nix.conf
task nix:secrets:init         # Initialize secrets with GitHub token
task docs:values              # Generate values.nix documentation
```

## Always-Followed Rules

- **No Emojis**: Strictly enforced in all code and documentation
- **DRY**: Extract repeated patterns to shared utilities
- **Comments**: Use for complex logic only
- **Testing**: Run `task nix:build` before commits
- **Pre-Commit**: `task fmt:all:check` then `task nix:validate` then `task nix:build`
- **Hostname-based tasks**: When on work machine (hostname: APKR2N5D495296), use `task nix:build:work` and `task nix:refresh:work` instead of lv426 equivalents

## Task & Feature Management

- **Beads**: Git-backed task tracking via `bd` CLI. Use `bd ready` to see tasks, `bd create` for new ones, `bd close` when done. Always `bd sync && git push` before ending sessions. Use `--json` for machine output. Never use `bd edit` (interactive); use `bd update --title/--notes/--status` instead.
- **Features**: Start non-trivial features with `plan <name>` to create spec in `openspec/`. Get explicit approval before implementing. Link to beads: `bd create --external-ref openspec:<name>`. 
- **Context**: Check `.sysinit/lessons.md` at session start for prior learnings (gitignored scratch space).

## Skills

Domain-specific knowledge is managed as Nix-defined skills in `modules/home/configurations/llm/skills/`. Each skill is a `.nix` file returning SKILL.md content, built into the Nix store alongside external superpowers skills. Skills are loaded on demand by LLM tools.

| Skill | When to use |
|-------|-------------|
| `nix-development` | Writing or modifying Nix code, module patterns, flake structure |
| `lua-development` | Writing or modifying Lua code for Neovim, WezTerm, Hammerspoon |
| `shell-scripting` | Writing or modifying shell scripts in `hack/` or elsewhere |
| `session-completion` | Ending a work session, pushing changes, handing off context |
