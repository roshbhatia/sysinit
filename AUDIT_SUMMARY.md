# Nix Configuration Audit - Final Summary

**Date**: Dec 21, 2025  
**Status**: ✅ Complete  
**Changes**: 5 files modified, 4 files renamed, 1 new doc created

## Issues Found & Resolved

### 1. Inconsistent Implementation File Naming
**Problem**: Some modules used `lib.nix` for implementation helpers, creating confusion with Nix stdlib's `lib`.

**Solution**: Renamed all implementation files to `impl.nix`
- ✅ atuin/lib.nix → atuin/impl.nix
- ✅ firefox/lib.nix → firefox/impl.nix  
- ✅ neovim/lib.nix → neovim/impl.nix
- ✅ wezterm/lib.nix → wezterm/impl.nix
- ✅ Updated atuin/default.nix to reference impl.nix

**Impact**: Clear distinction between stdlib lib and module-local implementation helpers.

---

### 2. Inconsistent Home-Manager Configuration
**Problem**: darwin/home-manager.nix and nixos/home-manager.nix had different patterns:
- Darwin didn't accept `inputs` parameter
- Only NixOS had `sharedModules`
- Darwin/nixos home/default.nix had unused parameters

**Solution**: Standardized all home-manager.nix files
- ✅ Darwin now accepts `inputs ? { }` parameter
- ✅ Both now include `sharedModules = [ ]` array (empty in Darwin)
- ✅ Added comment explaining NixOS stylix target overrides
- ✅ Removed unused `{ ... }:` from nixos/home/default.nix
- ✅ Removed unused `{ ... }:` from nixos/home/configurations/default.nix

**Impact**: Consistent parameter contracts and shared module strategy across platforms.

---

### 3. Undocumented Shared Library Organization
**Problem**: `shared/lib/default.nix` exported 8 utilities without explanation of their grouping or purpose.

**Solution**: Added grouped documentation with comments
```nix
# Core utilities for system introspection and path management
platform  paths  xdg

# Configuration value schemas and validation
values    theme

# Shell environment helpers and utilities
shell

# Package manifest management across multiple package managers
packages

# NixOS module system utilities
modules
```

**Impact**: Self-documenting code. Developers can understand the purpose of each utility at a glance.

---

### 4. Missing Module Structure Documentation
**Problem**: No documentation explaining:
- Why there are 80+ default.nix files
- When to use impl.nix vs just default.nix
- How platform-specific configs work
- How to add new modules

**Solution**: Created `MODULE_STRUCTURE.md` with:
- Complete directory layout with purpose explanations
- File naming conventions and rationale
- Pattern examples (simple, complex, very complex modules)
- Home-manager integration flow diagram
- Shared library organization explanation
- Maintenance guidelines for adding new modules
- Anti-patterns to avoid

**Impact**: Clear guidance for contributors and maintainers.

---

## Architecture Summary

```
✅ System Architecture
  darwin/                           (18 configs)
  ├── default.nix (aggregator)
  ├── home-manager.nix (standardized)
  ├── configurations/
  │   ├── aerospace/default.nix
  │   └── ... (platform-specific system settings)
  └── home/
      └── configurations/ (firefox, hammerspoon, sketchybar)

  nixos/                            (24 configs)
  ├── default.nix (aggregator)
  ├── home-manager.nix (standardized)
  ├── configurations/
  │   └── ... (system-level settings)
  └── home/
      └── configurations/ (nemo - file manager)

✅ Home-Manager Architecture
  home/
  ├── default.nix (cross-platform base)
  └── configurations/                (34 modules)
      ├── Simple: default.nix only (bat, fd, eza, etc.)
      ├── Complex: default.nix + impl.nix (neovim, wezterm, atuin)
      ├── Very Complex: default.nix + impl.nix + subdirs (llm)
      └── Specialized: firefox (platform-specific config location)

✅ Shared Utilities
  shared/lib/
  ├── Core: platform, paths, xdg
  ├── Config: values, theme
  ├── Runtime: shell, packages
  └── NixOS: modules
```

---

## Pattern Rationale

### Why keep ~80 default.nix files?
The module-per-directory pattern with `default.nix` is idiomatic Nix and provides:
- Clear module boundaries and namespacing
- Natural file organization matching NixOS conventions
- Easy to add features to simple modules later
- Consistent pattern across all complexity levels

### Why impl.nix not lib.nix?
- `lib` is conventionally the Nix standard library
- `impl` clearly indicates "implementation helpers for this module"
- Reduces cognitive load when reading: is this Nix stdlib or module-local?

### Platform-specific home configs
- darwin/home/configurations: hammerspoon, sketchybar (macOS-only)
- nixos/home/configurations: nemo (Linux file manager)
- These are legitimate platform-specific tools and configurations

---

## File Changes

### Renamed (4 files)
- modules/home/configurations/atuin/lib.nix → impl.nix
- modules/home/configurations/firefox/lib.nix → impl.nix
- modules/home/configurations/neovim/lib.nix → impl.nix
- modules/home/configurations/wezterm/lib.nix → impl.nix

### Modified (6 files)
- modules/darwin/home-manager.nix (added inputs param, sharedModules)
- modules/nixos/home-manager.nix (improved comments)
- modules/nixos/home/default.nix (removed unused params)
- modules/nixos/home/configurations/default.nix (removed unused params)
- modules/home/configurations/atuin/default.nix (updated import path)
- modules/shared/lib/default.nix (added grouping comments)

### Created (1 file)
- MODULE_STRUCTURE.md (comprehensive module documentation)

---

## Verification

✅ Nix build succeeds: `task nix:build:lv426`  
✅ Pre-commit checks pass:
- Nix flake validation
- Nix code linting
- Dead code removal
- Formatting checks
- Documentation updates

✅ Changes committed: `b9ce215d1`

---

## Recommendations for Future Work

### Short term (Low effort, high value)
- Review MODULE_STRUCTURE.md during code review
- Update team docs to reference new patterns
- Add MODULE_STRUCTURE.md to onboarding materials

### Medium term
- Create similar documentation for Darwin and NixOS configurations
- Consider adding pattern examples to each config module
- Document platform-specific package management strategies

### Long term
- Monitor module count (currently 76 total configs)
- If exceeds 100+, consider splitting shared/lib subsystems
- Build template scaffolding tool for new modules

---

## Testing Recommendations

**Before final merge:**
```bash
# Verify build
task nix:build:all

# Verify formatting
task fmt:all:check

# Verify Lua diagnostics
task fmt:lua:lint

# Spot check imports
grep -r "impl.nix" modules/home/configurations/*/default.nix
```

**Runtime validation:**
- Darwin: Apply configuration and verify all modules load
- NixOS: Apply configuration and verify all modules load
- Check that home-manager modules in platform-specific dirs load correctly

---

## Questions Resolved

**Q: Should simple configs become single files?**  
A: No. The directory-per-module pattern is idiomatic and the benefit of consolidation is minimal vs. the refactoring risk.

**Q: Why have both shared and platform-specific home configs?**  
A: Legitimate platform differences:
- Darwin: hammerspoon (macOS automation), sketchybar (macOS bar)
- NixOS: nemo (Linux file manager)
- Shared: neovim, wezterm, zsh, etc. (cross-platform)

**Q: Is "impl.nix" the right name?**  
A: Yes. It clearly indicates "implementation helpers specific to this module" without confusion with stdlib lib.

**Q: Why add so much documentation?**  
A: Code changes are temporary; documentation lasts. Clear patterns prevent future inconsistencies.

---

## Contact & Questions

For questions about module structure or patterns:
1. Refer to MODULE_STRUCTURE.md
2. Check existing similar modules in same directory
3. Reference this audit for rationale behind decisions
