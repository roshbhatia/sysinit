# Quick-Start Improvement Guide

**Priority**: Implement HIGH-PRIORITY improvements for significantly better code quality.

---

## Quick Summary

| Issue | Priority | Time | Impact | Status |
|-------|----------|------|--------|--------|
| Hardcoded paths | 🔴 HIGH | 2-3h | 📈 Medium | Not Started |
| Missing options | 🔴 HIGH | 4-6h | 📈 Medium | Not Started |
| Duplicate comment | 🟢 LOW | 5m | 📊 Minimal | Easy Pick |

---

## Improvement #1: Fix Hardcoded Paths (HIGH PRIORITY)

### Files Affected
```
modules/home/configurations/neovim/default.nix (4 paths)
modules/home/configurations/wezterm/default.nix (2 paths)
modules/darwin/home-specific/configurations/hammerspoon/default.nix (2 paths)
modules/darwin/home-specific/configurations/sketchybar/default.nix (1 path)
```

### Step-by-Step Implementation

#### Step 1: Add configRoot to Values Schema
**File**: `modules/shared/lib/values/default.nix`

Add this option:
```nix
# After the closing brace of the last option, before the closing brace of valuesType
configRoot = mkOption {
  type = types.str;
  description = "Root path to the configuration flake (used for out-of-store symlinks)";
};
```

#### Step 2: Pass configRoot in Flake
**File**: `flake.nix`

Find the `processValues` function call (~235 line) and add configRoot:

```nix
processedVals = processValues {
  inherit utils;
  userValues = hostConfig.values // {
    configRoot = toString ./.;  # Add this line
  };
};
```

Do this for BOTH:
- The default config (~256)
- The darwin configurations (~235)

#### Step 3: Update neovim Module
**File**: `modules/home/configurations/neovim/default.nix`

Find `mkOutOfStoreSymlink` calls and replace:

**Before**:
```nix
let
  themes = import ../../../shared/lib/theme { inherit lib; };
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
```

**After**:
```nix
let
  themes = import ../../../shared/lib/theme { inherit lib; };
  inherit (config.lib.file) mkOutOfStoreSymlink;
  configPath = "${values.configRoot}/modules/home/configurations/neovim";
in
```

Then replace symlink lines:

**Before**:
```nix
xdg.configFile."nvim/init.lua".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";
xdg.configFile."nvim/lua/sysinit/config".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/config";
xdg.configFile."nvim/lua/sysinit/utils".source = mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua/sysinit/utils";
```

**After**:
```nix
xdg.configFile."nvim/init.lua".source = mkOutOfStoreSymlink "${configPath}/init.lua";
xdg.configFile."nvim/lua/sysinit/config".source = mkOutOfStoreSymlink "${configPath}/lua/sysinit/config";
xdg.configFile."nvim/lua/sysinit/utils".source = mkOutOfStoreSymlink "${configPath}/lua/sysinit/utils";
```

#### Step 4: Update wezterm Module
**File**: `modules/home/configurations/wezterm/default.nix`

Same pattern:

```nix
let
  # ... existing code ...
  configPath = "${values.configRoot}/modules/home/configurations/wezterm";
in
```

Replace:
```nix
# Before
home.file.wezterm-config.source = mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/wezterm.lua";
home.file.wezterm-lua.source = mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/wezterm/lua";

# After
home.file.wezterm-config.source = mkOutOfStoreSymlink "${configPath}/wezterm.lua";
home.file.wezterm-lua.source = mkOutOfStoreSymlink "${configPath}/lua";
```

#### Step 5: Update Hammerspoon Module
**File**: `modules/darwin/home-specific/configurations/hammerspoon/default.nix`

Already partially done, but update if needed:

```nix
# Add configPath
configPath = "${values.configRoot}/modules/darwin/home-specific/configurations/hammerspoon";

# Then update paths
home.file.".hammerspoon/init.lua".source = "${configPath}/init.lua";
home.file.".hammerspoon/lua".source = "${configPath}/lua";
```

#### Step 6: Update Sketchybar Module  
**File**: `modules/darwin/home-specific/configurations/sketchybar/default.nix`

Already done, but verify:

```nix
path = "${values.configRoot}/modules/darwin/home-specific/configurations/sketchybar";
```

#### Step 7: Test
```bash
task nix:build
```

---

## Improvement #2: Add Module Options (HIGH PRIORITY)

### Template
Use this template for all home configuration modules:

```nix
{ config, lib, pkgs, values, ... }:
with lib;
{
  options.programs.myapp = {
    enable = mkEnableOption "description of what myapp does";
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Configuration options for myapp";
    };
  };

  config = mkIf config.programs.myapp.enable {
    # Your existing configuration here
    programs.myapp = {
      enable = true;
      # ... rest ...
    };
  };
}
```

### Phase 1: Start with Tier 1 (Highest Impact)

**Tier 1 modules** (in priority order):
1. zsh
2. neovim
3. wezterm
4. git
5. llm
6. utils

### Example: Adding options to zsh module

**File**: `modules/home/configurations/zsh/default.nix`

**Before**:
```nix
{ config, lib, pkgs, values, ... }:
{
  programs.zsh = {
    enable = true;
    # ... rest of config ...
  };
}
```

**After**:
```nix
{ config, lib, pkgs, values, ... }:
with lib;
{
  options.programs.zsh = {
    enable = mkEnableOption "zsh shell configuration";
    
    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "zsh configuration options";
    };
  };

  config = mkIf config.programs.zsh.enable {
    programs.zsh = {
      enable = true;
      # ... rest of config ...
    };
  };
}
```

### Benefits Immediately Visible
```bash
# Users can now do:
{ config, ... }:
{
  programs.zsh.enable = false;  # Disable zsh if desired!
}
```

---

## Improvement #3: Remove Duplicate Comment (LOW PRIORITY)

**File**: `flake.nix`

**Line 41-42**:
```nix
# Remove one of these:
# Centralized user/host configuration
# Centralized user/host configuration
```

Keep one, delete the duplicate.

---

## Implementation Timeline

### Option A: Quick Win (1-2 hours)
- [x] Remove duplicate comment
- [ ] Fix hardcoded paths

### Option B: Comprehensive (6-8 hours)
- [x] Remove duplicate comment
- [ ] Fix hardcoded paths
- [ ] Add options to Tier 1 modules (zsh, neovim, wezterm, git, llm, utils)

### Option C: Complete (10-14 hours)
- [x] All of Option B
- [ ] Add options to Tier 2 modules
- [ ] Add options to Tier 3 modules
- [ ] Polish & standardize patterns

---

## Testing Checklist

After each change:
```bash
# 1. Build
task nix:build

# 2. Check specific module
nix eval '.#darwinConfigurations.lv426.config.programs.zsh'

# 3. Full system (if on macOS)
task nix:refresh
```

---

## Common Mistakes to Avoid

1. ❌ Forgetting `mkIf` around the config section
   ```nix
   # WRONG
   config = {
     programs.zsh = { enable = true; };  # Will always enable
   };
   
   # RIGHT
   config = mkIf config.programs.zsh.enable {
     programs.zsh = { enable = true; };  # Only when enabled
   };
   ```

2. ❌ Not declaring the option if you want it configurable
   ```nix
   # WRONG
   config = {
     programs.zsh = { enable = true; };  # No way to disable
   };
   
   # RIGHT
   options.programs.zsh.enable = mkEnableOption "zsh";
   config = mkIf config.programs.zsh.enable { ... };
   ```

3. ❌ Hardcoding paths in new modules
   ```nix
   # WRONG
   mkOutOfStoreSymlink "${HOME}/path/to/repo/file"
   
   # RIGHT
   mkOutOfStoreSymlink "${values.configRoot}/modules/.../file"
   ```

---

## Progress Tracking

Create a checklist as you implement:

```markdown
### HIGH PRIORITY
- [ ] Add configRoot to values schema
- [ ] Pass configRoot in flake.nix
- [ ] Fix neovim paths
- [ ] Fix wezterm paths
- [ ] Fix hammerspoon paths
- [ ] Add options to zsh
- [ ] Add options to neovim
- [ ] Add options to wezterm
- [ ] Add options to git
- [ ] Add options to llm
- [ ] Add options to utils

### LOW PRIORITY
- [ ] Remove duplicate comment
- [ ] Standardize lib pattern
- [ ] Complete schema docs
```

---

## Questions?

Refer to:
- **CODE_AUDIT.md** — Detailed analysis
- **modules/README.md** — Module patterns
- **STRUCTURE.md** — Overall organization

