# PRD-02: Module Options Decentralization

## Overview

Eliminate the monolithic `modules/shared/lib/schema.nix` (294 lines) by allowing each module to define its own options in a decentralized manner.

## Problem Statement

Current architecture:
- `modules/shared/lib/schema.nix` defines ALL configuration options for ALL modules
- Single point of change for any new option
- Tight coupling between schema and modules
- Hard to add/remove modules without touching global schema
- 294 lines of centralized configuration

This violates Unix philosophy of modularity and creates a maintenance bottleneck.

## Proposed Solution

Each module defines its own options in a local `options.nix` file, namespaced under `config.sysinit.*` to avoid conflicts.

## Scope

### In Scope
- Extract options from schema.nix into per-module options.nix files
- Namespace all options under `sysinit.*`
- Update modules to use `config.sysinit.*` instead of `values.*`
- Delete `modules/shared/lib/schema.nix` when complete

### Out of Scope
- Changing module functionality
- Refactoring module internals
- Changing flake structure

### Rationale

This refactoring is essential for true Unix philosophy alignment:
- Eliminates single point of failure (centralized schema)
- Enables modules to be truly independent
- Allows modules to be added/removed without touching global config
- Makes dependency chains explicit through imports

## Technical Design

### Before (Centralized)

```nix
# modules/shared/lib/schema.nix (294 lines)
{ lib }:
{
  valuesType = types.submodule {
    options = {
      git = {
        name = mkOption { ... };
        email = mkOption { ... };
        username = mkOption { ... };
      };
      
      theme = {
        colorscheme = mkOption { ... };
        variant = mkOption { ... };
        # ...
      };
      
      darwin = {
        borders.enable = mkOption { ... };
        # ...
      };
      
      # ... 294 lines total
    };
  };
}

# modules/home/configurations/git/default.nix
{ values, ... }: {
  programs.git = {
    userName = values.git.name;
    userEmail = values.git.email;
  };
}
```

### After (Decentralized)

```nix
# modules/home/configurations/git/options.nix (NEW)
{ lib, ... }:
{
  options.sysinit.git = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git user name";
    };
    
    email = lib.mkOption {
      type = lib.types.str;
      description = "Git user email";
    };
    
    username = lib.mkOption {
      type = lib.types.str;
      description = "Git/GitHub username";
    };
    
    # ... other git options
  };
}

# modules/home/configurations/git/default.nix (UPDATED)
{ config, lib, pkgs, ... }:
{
  imports = [ ./options.nix ];  # Import own options
  
  programs.git = {
    enable = true;
    userName = config.sysinit.git.name;
    userEmail = config.sysinit.git.email;
  };
}

# modules/shared/lib/schema.nix (DELETED when all modules migrated)
```

### Migration Strategy

Migrate modules one at a time:

1. **Pick a simple module** (e.g., git)
2. Create `options.nix` in module directory
3. Extract relevant options from `schema.nix`
4. Add `sysinit.*` namespace
5. Update module to import `./options.nix`
6. Update module to use `config.sysinit.*`
7. Test module works
8. Commit
9. Repeat for next module

### Namespace Structure

```
config.sysinit.
├── git.*              # Git configuration
├── editor.*           # Editor settings (neovim, helix)
├── shell.*            # Shell configuration
├── theme.*            # Theme settings
├── darwin.*           # macOS-specific options
└── nixos.*            # NixOS-specific options
```

### Modules to Migrate

Priority order (easiest to hardest):

1. **git** (simple, well-contained)
2. **bat** (minimal options)
3. **fzf** (straightforward)
4. **direnv** (simple)
5. **eza** (minimal)
6. **neovim** (medium complexity)
7. **theme** (complex, many dependents)
8. **darwin** (platform-specific)

## Acceptance Criteria

All criteria must pass for PRD completion.

**Per-Module Completion** (for each of 8 modules: git, bat, fzf, direnv, eza, neovim, theme, darwin)
- Module has `options.nix` file in its directory
- All options namespaced under `config.sysinit.<module>`
- Module's `default.nix` imports `./options.nix`
- Module uses `config.sysinit.*` instead of `values.*`
- Module builds without errors
- Module functionality unchanged (tested manually)
- Git commit created: "refactor: decentralize <module> options"

**Schema Removal**
- All 8 modules successfully migrated
- No references to `values.*` in module code (except flake/common.nix)
- `modules/shared/lib/schema.nix` file deleted
- All imports of schema.nix removed from flake files

**System Validation**
- `task nix:validate` passes
- `task nix:build:lv426` succeeds
- `task nix:build:arrakis` succeeds
- `task nix:refresh:lv426` applies successfully
- All functionality from PRD-01 still works
- Git config shows correct name/email
- Neovim launches successfully
- Theme colors applied correctly
- No error messages in system logs

## Testing Procedure

### Per-Module Test

```bash
# After migrating each module:

# 1. Build test
task nix:build:lv426

# 2. Apply
task nix:refresh:lv426

# 3. Test module functionality
# For git:
git config user.name    # Should show your name
git config user.email   # Should show your email

# For neovim:
nvim --version         # Should launch

# For theme:
# Check colors in terminal/apps

# 4. Commit
git add modules/home/configurations/git/
git commit -m "refactor: decentralize git options"
```

### Final Test

```bash
# After all modules migrated:

# 1. Verify schema.nix can be deleted
rg "schema\.nix" flake/
# Should only appear in imports that will be removed

# 2. Delete schema.nix
rm modules/shared/lib/schema.nix

# 3. Update imports in flake/
# Remove schema references

# 4. Full build test
task nix:validate
task nix:build:lv426
task nix:build:arrakis

# 5. Apply
task nix:refresh:lv426

# 6. Full regression test
# Test all modules (see regression testing section)
```

## Implementation Steps

### Phase 1: Git Module (Example)

1. **Create options file**
   ```bash
   touch modules/home/configurations/git/options.nix
   ```

2. **Extract options from schema.nix**
   ```nix
   # Copy git section from schema.nix to git/options.nix
   # Add sysinit namespace
   ```

3. **Update git/default.nix**
   ```nix
   # Add: imports = [ ./options.nix ];
   # Change: values.git.* → config.sysinit.git.*
   ```

4. **Test**
   ```bash
   task nix:build:lv426
   task nix:refresh:lv426
   git config user.name  # Verify works
   ```

5. **Commit**
   ```bash
   git add modules/home/configurations/git/
   git commit -m "refactor: decentralize git options"
   ```

### Phase 2: Repeat for Other Modules

Follow same process for:
- bat
- fzf
- direnv
- eza
- neovim
- theme
- darwin

### Phase 3: Cleanup

1. **Remove schema.nix**
   ```bash
   rm modules/shared/lib/schema.nix
   ```

2. **Update flake imports**
   ```bash
   # Remove schema.nix imports from:
   # - flake/builders.nix
   # - flake/common.nix (if present)
   ```

3. **Final test**
   ```bash
   task nix:validate
   task nix:build:all
   ```

4. **Final commit**
   ```bash
   git add .
   git commit -m "refactor: complete options decentralization

   - Removed modules/shared/lib/schema.nix
   - All modules now define their own options
   - Options namespaced under config.sysinit.*"
   ```

## Rollback Plan

### Per-Module Rollback

```bash
# If a module migration breaks:
git revert HEAD
task nix:refresh:lv426
```

### Full Rollback

```bash
# If entire migration causes issues:
git log --oneline | grep "decentralize"
# Find first decentralization commit

git revert <commit-range>
task nix:refresh:lv426
```

## Dependencies

**Blocks**: PRD-06
**Blocked By**: PRD-01

The profile system must exist first. This PRD blocks the minimal host implementation because we want clean module boundaries before stripping down the host.

## Time Estimate

- Per simple module: 30 minutes
- Per complex module: 1-2 hours
- Total: 8-12 hours (~1 week with testing)

## Success Metrics

- No more centralized schema file
- Each module self-contained
- Can add/remove modules without touching global config
- No user-facing changes (transparent refactor)

## Notes

- Migrate modules one at a time with tests after each
- Git module is the simplest, start there
- Theme module is most complex, save for last
- Each module migration is independently committable
- Can pause at any point and resume later
