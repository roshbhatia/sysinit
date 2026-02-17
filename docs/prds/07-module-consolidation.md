# PRD-07: Module Consolidation and Auto-Import Cleanup

## Overview

Consolidate scattered modules into shared configurations and eliminate redundant imports from host configs by leveraging the existing auto-import pattern in the builder system.

## Problem Statement

After module restructuring, we discovered:
- Ghostty was being uninstalled on work repo despite being installed on personal repo
- Modules were scattered across `modules/desktop/`, `modules/dev/`, and `modules/home/configurations/`
- Host configs had redundant imports for modules that were already auto-imported
- The `modules/shared/lib/lsp-config.nix` file was only used by one module (helix)
- Unclear which modules were shared vs host-specific

**Root Cause:** The builder system already auto-imports modules from specific directories, but modules weren't organized to take advantage of this pattern, and host configs were duplicating these imports.

## Proposed Solution

1. Move all shared home configurations to `modules/home/configurations/` (auto-imported)
2. Keep platform-specific modules in `modules/darwin/home/` or `modules/nixos/home/` (manually imported)
3. Clean up redundant imports from all host configs
4. Inline single-use shared libraries into their consuming modules
5. Document the auto-import pattern for future contributors

## Scope

### In Scope
- Move ghostty and zellij to `modules/home/configurations/`
- Add ghostty and zellij to auto-import list
- Remove redundant imports from lv426, lima-dev, lima-minimal host configs
- Inline `lsp-config.nix` into `helix.nix`
- Remove empty `modules/desktop/` and `modules/dev/` directories
- Document auto-import pattern in `.sysinit/lessons.md`

### Out of Scope
- Creating new lint rules to prevent future redundant imports
- Refactoring other modules
- Changing the builder system itself
- Updating CI/CD checks

## Technical Design

### Auto-Import Architecture

**System-level Darwin configs (auto-imported):**
```
modules/darwin/configurations/default.nix
  -> imported by lib/builders.nix:107
  -> applied to ALL darwin hosts automatically
```

**Home-level configs (auto-imported):**
```
modules/home/configurations/default.nix
  -> imported by modules/darwin/home-manager.nix:24
  -> applied to ALL hosts automatically
```

### Module Organization Pattern

```
modules/
├── darwin/
│   ├── configurations/        # Auto-imported for all Darwin systems
│   │   ├── default.nix        # Import list
│   │   ├── aerospace/
│   │   ├── borders/
│   │   └── sketchybar/
│   └── home/                  # Platform-specific, import manually
│       └── firefox.nix        # macOS desktop only
├── home/
│   └── configurations/        # Auto-imported for ALL hosts
│       ├── default.nix        # Import list
│       ├── ghostty/           # Shared across all hosts
│       ├── wezterm/
│       ├── zellij/
│       ├── git/
│       └── neovim/
└── nixos/
    └── home/                  # Platform-specific, import manually
```

### Host Config Pattern

**Before (redundant imports):**
```nix
# hosts/lv426/default.nix
{
  imports = [
    ../../modules/darwin/configurations/aerospace    # REDUNDANT
    ../../modules/darwin/configurations/borders      # REDUNDANT
    ../../modules/darwin/configurations/sketchybar   # REDUNDANT
  ];
  
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../modules/home/configurations/ghostty      # REDUNDANT
      ../../modules/home/configurations/wezterm      # REDUNDANT
      ../../modules/home/configurations/zsh          # REDUNDANT
      ../../modules/home/configurations/git          # REDUNDANT
      ../../modules/darwin/home/firefox.nix          # OK - darwin-specific
      ../../modules/dev/home/shell/zellij            # WRONG LOCATION
    ];
  };
}
```

**After (minimal, delta-only):**
```nix
# hosts/lv426/default.nix
{
  environment.systemPackages = with pkgs; [ lima ];
  
  home-manager.users.${config.sysinit.user.username} = {
    # No imports needed - everything auto-imported!
    # Firefox is auto-imported via modules/darwin/home/default.nix
  };
}
```

### Changes to Default Import Lists

**modules/home/configurations/default.nix:**
```nix
{
  imports = [
    # ... existing imports ...
    ./ghostty     # ADD
    ./zellij      # ADD
  ];
}
```

### Helix LSP Config Inlining

**Before:**
```
modules/shared/lib/lsp-config.nix         # 612 lines of LSP configs
modules/home/configurations/helix.nix     # imports ../shared/lib/lsp-config.nix
```

**After:**
```
modules/home/configurations/helix.nix     # LSP config inlined directly
```

## Implementation Steps

### 1. Add Zellij to Auto-Import List
```nix
# modules/home/configurations/default.nix
# Add ./zellij to imports (already added ./ghostty)
```

### 2. Inline LSP Config into Helix
- Read `modules/shared/lib/lsp-config.nix`
- Copy `lsp` and `languages` definitions into `helix.nix`
- Remove import from `helix.nix`
- Delete `modules/shared/lib/lsp-config.nix`

### 3. Clean Up lv426 Host Config
Remove ALL redundant imports:
- Lines 5-10: Darwin system imports (aerospace, borders, sketchybar, stylix, desktop)
- Lines 18-23: Home imports (ghostty, wezterm, zsh, git, zellij, firefox)

Keep only:
- `environment.systemPackages` with lima

Note: Firefox is auto-imported via `modules/darwin/home/default.nix` for ALL Darwin systems.

### 4. Clean Up lima-dev Host Config
Remove all home-manager imports (all 13 are auto-imported):
- ghostty, wezterm, git, zsh, neovim, helix, fzf, direnv, bat, eza, fd, zoxide, ast-grep

### 5. Clean Up lima-minimal Host Config
Remove all home-manager imports (all 4 are auto-imported):
- neovim, git, zsh, zellij

## Acceptance Criteria

1. `task nix:build` succeeds on personal repo
2. Ghostty is installed on both personal and work repos
3. Zellij is installed on all hosts (lv426, lima-dev, lima-minimal)
4. Firefox is installed on all Darwin hosts (lv426, work)
5. No packages are lost after cleanup (verify with `home-manager packages`)
6. `nix flake check` passes validation
7. lv426 host config has NO home-manager imports (all auto-imported)
8. lima-dev and lima-minimal have no home-manager imports
9. `modules/shared/lib/lsp-config.nix` does not exist
10. Helix still works with all language servers
11. `modules/desktop/` and `modules/dev/` directories do not exist
12. Work repo build succeeds and gets all shared modules automatically

## Testing

### Build Test
```bash
cd /Users/rbha18/github/personal/roshbhatia/sysinit
task nix:build
# Expected: Build succeeds with no errors
```

### Package Verification
```bash
# Before changes
home-manager packages | sort > /tmp/packages-before.txt

# After changes
home-manager packages | sort > /tmp/packages-after.txt

# Compare
diff /tmp/packages-before.txt /tmp/packages-after.txt
# Expected: No missing packages (only order changes acceptable)
```

### Helix LSP Test
```bash
# Open a file in helix
hx test.nix

# Type some code, verify LSP features work:
# - Autocomplete
# - Go to definition
# - Diagnostics

# Check language servers are running
:lsp-workspace-command
# Expected: LSP servers active for current file type
```

### Ghostty Test
```bash
# Verify ghostty is installed
which ghostty
# Expected: /nix/store/.../bin/ghostty or ~/.nix-profile/bin/ghostty

# Launch ghostty
ghostty
# Expected: Terminal opens successfully
```

### Work Repo Test
```bash
cd /Users/rbha18/github/work/rbha18_nike/sysinit
task nix:build:work
# Expected: Build succeeds, ghostty still present
```

## Rollback

If something breaks:

```bash
# 1. Revert commits
git log --oneline  # Find commit hash before changes
git reset --hard <hash>

# 2. Rebuild system
task nix:refresh:lv426

# 3. Verify system works
task nix:build
```

## Dependencies

### Blocks
- None (this is cleanup work)

### Blocked By
- None (independent of other PRDs)

## Notes

### Key Principles Discovered

1. **DRY at the architecture level**: Don't repeat imports across hosts
2. **Convention over configuration**: Use auto-import patterns instead of explicit imports
3. **Host configs are deltas**: Only specify what's unique to that host
4. **Shared lib is for utilities**: Not for single-module configurations
5. **Platform-specific stays platform-specific**: Keep macOS-only modules in `modules/darwin/home/`

### Auto-Import Pattern Reference

**System-level Darwin:**
- Location: `modules/darwin/configurations/default.nix`
- Builder: `lib/builders.nix:107`
- Scope: ALL darwin hosts

**Home-level configs:**
- Location: `modules/home/configurations/default.nix`
- Builder: `modules/darwin/home-manager.nix:24`
- Scope: ALL hosts (darwin + nixos)

### Modules Moved

| From | To | Reason |
|------|-----|--------|
| `modules/desktop/home/ghostty` | `modules/home/configurations/ghostty` | Shared across all hosts |
| `modules/dev/home/shell/zellij` | `modules/home/configurations/zellij` | Shared across all hosts |

### Empty Directories Removed

- `modules/desktop/` - No remaining modules
- `modules/dev/` - No remaining modules
- `modules/shared/lib/` - Only contained single-use lsp-config.nix

### Future Improvements

1. **Document auto-import pattern**: Add comments in `lib/builders.nix` explaining the mechanism
2. **Lint rule**: Create a check to warn about redundant imports in host configs
3. **Template**: Add a host config template showing the minimal pattern
4. **CI check**: Ensure no modules exist outside standardized locations
5. **Module location validator**: Script to verify modules are in correct directories

### Work Repo Implications

The work repo (`rbha18_nike/sysinit`) should:
- Pull all changes from personal repo automatically
- Only override work-specific settings in `hosts/work/values.nix`
- Not duplicate any module imports (rely on auto-import)

## References

- Auto-import for darwin: `lib/builders.nix:107`
- Auto-import for home: `modules/darwin/home-manager.nix:24`
- Builder pattern: `lib/builders.nix`
- Host configs: `hosts/*/default.nix`
- Lessons learned: `.sysinit/lessons.md`
