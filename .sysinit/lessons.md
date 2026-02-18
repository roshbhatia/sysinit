# Sysinit Module Consolidation - Lessons Learned

## Problem Discovery

**Date:** 2026-02-17

**Trigger:** After restructuring modules, Ghostty was being uninstalled on work repo despite being installed on personal repo.

**Root Cause:** Modules were scattered across different directories with unclear import patterns:
- Some modules auto-imported via `modules/darwin/configurations/default.nix` (aerospace, borders, sketchybar, stylix)
- Some modules auto-imported via `modules/home/configurations/default.nix` (wezterm, git, zsh, neovim)
- Some modules manually imported per-host (ghostty, zellij)
- Host configs had redundant imports that were already auto-imported

## Architecture Pattern Discovery

### Auto-Import Mechanism

**System-level Darwin configs:**
```
modules/darwin/configurations/default.nix
  -> imported by lib/builders.nix:107
  -> applied to ALL darwin hosts automatically
```

**Home-level configs:**
```
modules/home/configurations/default.nix
  -> imported by modules/darwin/home-manager.nix:24
  -> applied to ALL hosts automatically
```

### Module Organization Rules

1. **Shared home configurations**: `modules/home/configurations/` - Auto-imported for ALL hosts
2. **Platform-specific home configs**: `modules/darwin/home/` or `modules/nixos/home/` - Import explicitly in hosts
3. **System-level darwin configs**: `modules/darwin/configurations/` - Auto-imported for ALL darwin hosts
4. **Shared libraries**: `modules/shared/lib/` - Only for truly shared utilities used by multiple modules

### Host Config Philosophy

Host configs should be MINIMAL - only import host-specific overrides. Everything else is automatically shared.

**Good host config pattern:**
```nix
# hosts/lv426/default.nix
{
  environment.systemPackages = with pkgs; [ lima ];  # Host-specific packages
  
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../modules/darwin/home/firefox.nix  # Only macOS desktop-specific module
    ];
  };
}
```

**Anti-pattern (what we had before):**
```nix
# hosts/lv426/default.nix
{
  imports = [
    ../../modules/darwin/configurations/aerospace  # REDUNDANT - auto-imported
    ../../modules/darwin/configurations/borders    # REDUNDANT - auto-imported
    ../../modules/darwin/configurations/sketchybar # REDUNDANT - auto-imported
  ];
  
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../modules/home/configurations/ghostty  # REDUNDANT - should be auto-imported
      ../../modules/home/configurations/wezterm  # REDUNDANT - auto-imported
      ../../modules/home/configurations/zsh      # REDUNDANT - auto-imported
      ../../modules/home/configurations/git      # REDUNDANT - auto-imported
      ../../modules/darwin/home/firefox.nix      # OK - darwin-specific
      ../../modules/dev/home/shell/zellij        # WRONG LOCATION - should be shared
    ];
  };
}
```

## Changes Made

### Modules Consolidated (Moved to shared)
- `modules/desktop/home/ghostty` → `modules/home/configurations/ghostty`
- `modules/dev/home/shell/zellij` → `modules/home/configurations/zellij`

### Empty Directories Removed
- `modules/desktop/` - No longer needed
- `modules/dev/` - No longer needed

### Shared Library Cleanup
- `modules/shared/lib/lsp-config.nix` - Only used by helix, should be inlined

## Remaining Work

### 1. Add Zellij to Auto-Import List
```nix
# modules/home/configurations/default.nix
imports = [
  # ... existing imports ...
  ./zellij  # Add this alphabetically after wezterm
];
```

### 2. Inline Helix LSP Config
The `lsp-config.nix` is not truly "shared" if only one module uses it. Inline directly into `helix.nix`.

### 3. Clean Up Host Configs

**lv426:** Remove all redundant imports, keep only firefox
**lima-dev:** Remove all imports (everything is auto-imported)
**lima-minimal:** Remove all imports (everything is auto-imported)

## Key Principles Learned

1. **DRY at the architecture level**: Don't repeat imports across hosts
2. **Convention over configuration**: Use auto-import patterns instead of explicit imports
3. **Host configs are deltas**: Only specify what's unique to that host
4. **Shared lib is for utilities**: Not for single-module configurations
5. **Platform-specific stays platform-specific**: Keep macOS-only modules in `modules/darwin/home/`

## Testing Strategy

1. Build personal repo: `task nix:build`
2. Check work repo still works: Switch to work repo, verify configuration
3. Verify no packages lost: Check `home-manager packages` output before/after
4. Validate flake: `nix flake check`

## Future Improvements

1. **Document auto-import pattern**: Add comments in `lib/builders.nix` explaining the pattern
2. **Lint rule**: Create a check to warn about redundant imports in host configs
3. **Template**: Add a host config template showing the minimal pattern
4. **CI check**: Ensure no modules exist outside of standardized locations

## References

- Auto-import for darwin: `lib/builders.nix:107`
- Auto-import for home: `modules/darwin/home-manager.nix:24`
- Builder pattern: `lib/builders.nix`
- Host configs: `hosts/*/default.nix`

---

# Module Reorganization - Build Fixes (2026-02-18)

## Git Configuration Error

**Problem:** After the initial reorganization, build failed with:
```
error: The option `home-manager.users.rshnbhatia.sysinit.git.name' was accessed but has no value defined.
```

**Root Cause:** Git options were defined in `modules/home/programs/git/options.nix` and imported at the system level (`modules/darwin/default.nix:9`), but not imported in the home-manager context. The git module (`modules/home/programs/git/default.nix`) runs in home-manager context and needs `config.sysinit.git` options to be defined there.

**Fix Applied:**
1. Import git options in home-manager configurations:
   - `modules/darwin/home-manager.nix` - Added `../home/programs/git/options.nix` import
   - `modules/nixos/home-manager.nix` - Added `../home/programs/git/options.nix` import

2. Set git config values in home-manager user configuration:
   - Added `sysinit.git = values.git;` in both darwin and nixos home-manager configs

**Key Insight:** NixOS module options have different scopes:
- **System-level options** (darwin/nixos): Set via `config.sysinit.*` in builders
- **Home-manager options**: Must be imported AND set separately in home-manager user config
- Modules that run in home-manager context need their options defined at that level

**Files Modified:**
- `modules/darwin/home-manager.nix` - Import git options, set git config
- `modules/nixos/home-manager.nix` - Import git options, set git config

**Commit:** `fbd2c62e2` - "fix: import git options and set git config in home-manager context"

## Stale Import Paths

**Problem:** After moving modules, several import paths were still pointing to old locations.

**Fixes Applied:**
1. `modules/options/theme.nix`:
   - Changed `import ../theme` → `import ../lib/theme.nix`
   - Removed duplicate metadata import

2. `modules/darwin/sketchybar.nix`:
   - Fixed relative path: `../home/sketchybar/helpers/menus` → `./home/sketchybar/helpers/menus`

3. `lib/builders.nix`:
   - Changed `hostConfig.sysinit.git` → `values.git` (git config now comes from values)

4. `hosts/default.nix`:
   - Refactored to function accepting `common` and `overrides`
   - Removed invalid `sysinit.git` keys from metadata
   - Simplified to only include `username` and `values`

**Commit:** `67a875822` - "fix: update module import paths after reorganization"

## Status: COMPLETE

All builds passing:
- `task nix:validate` - Passed
- `task nix:build` - Passed (lv426/macOS)
- `task nix:build:lv426` - Passed

The module reorganization is complete and working. Ready to test on work repo.
