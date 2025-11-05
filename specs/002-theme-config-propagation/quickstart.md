# Quickstart: Theme Configuration Propagation Testing

**Feature**: `002-theme-config-propagation`
**Date**: 2025-11-04

## Overview

This document provides step-by-step testing scenarios for validating theme configuration propagation. Each scenario corresponds to user stories and edge cases defined in the spec.

## Prerequisites

- Nix-darwin environment configured
- Home-manager installed
- Core applications installed: Wezterm, Neovim, Firefox
- Access to `values.nix` for editing
- Task runner configured (for `task nix:build` and `task nix:refresh`)

## Test Scenarios

### Scenario 1: Switch from Dark to Light Mode

**User Story**: US1 - Switch Light/Dark Mode
**Priority**: P1

**Steps**:

1. **Initial State**: Verify current theme is dark mode
   ```bash
   # Check current values.nix
   grep -A 10 "theme = {" values.nix

   # Expected output should show appearance = "dark" (or absence, defaulting to dark)
   ```

2. **Edit Configuration**: Change to light mode
   ```nix
   # Edit values.nix
   {
     theme = {
       appearance = "light";           # NEW: Set to light
       colorscheme = "catppuccin";     # Must support light mode
       # variant will auto-derive to "latte" for catppuccin light mode
     };
   }
   ```

3. **Validate Build**: Test configuration validity
   ```bash
   task nix:build

   # Expected: Build succeeds
   # If palette doesn't support light mode, expect clear error message
   ```

4. **Apply Changes**: Activate new configuration
   ```bash
   task nix:refresh

   # Expected: System rebuilds and switches generation
   ```

5. **Verify Applications**:

   **Wezterm**:
   ```bash
   # Restart Wezterm
   # Visual check: Background should be light, text dark
   # Check theme JSON
   cat ~/.config/wezterm/theme.json | jq '.appearance'
   # Expected: "light"
   ```

   **Neovim**:
   ```bash
   # Launch nvim
   nvim
   # In nvim command mode:
   :echo &background
   # Expected: "light"

   # Visual check: Light background with dark text
   ```

   **Firefox**:
   ```bash
   # Launch Firefox
   # Check about:support → "Application Basics" → "Theme"
   # Expected: Light theme colors applied
   ```

**Success Criteria**:
- ✅ Build succeeds without errors
- ✅ All applications show light theme after restart
- ✅ Colors are consistent across applications
- ✅ Theme JSON files contain `"appearance": "light"`

**Rollback Test**:
```bash
darwin-rebuild --rollback
# All applications should return to previous dark theme
```

---

### Scenario 2: Switch Color Palette

**User Story**: US2 - Change Color Palette
**Priority**: P2

**Steps**:

1. **Initial State**: Note current palette
   ```bash
   grep "colorscheme" values.nix
   # Example output: colorscheme = "catppuccin";
   ```

2. **Edit Configuration**: Change palette
   ```nix
   # Edit values.nix
   {
     theme = {
       appearance = "dark";
       colorscheme = "rose-pine";      # Change to different palette
       # variant will auto-derive to "moon" or "main" for rose-pine dark mode
     };
   }
   ```

3. **Validate Build**:
   ```bash
   task nix:build
   # Expected: Build succeeds
   ```

4. **Apply Changes**:
   ```bash
   task nix:refresh
   ```

5. **Verify Color Changes**:

   **Wezterm**:
   ```bash
   # Check theme JSON
   cat ~/.config/wezterm/theme.json | jq '.colorscheme'
   # Expected: "rose-pine-moon" or "rose-pine-main"

   # Visual check: Rose Pine color palette (softer purples/pinks)
   ```

   **Neovim**:
   ```bash
   nvim
   # In nvim:
   :colorscheme
   # Expected: rose-pine or rose-pine variant

   # Visual check: Rose Pine colors in syntax highlighting
   ```

6. **Switch to Another Palette in Same Session**:
   ```nix
   # Edit values.nix again
   {
     theme = {
       appearance = "dark";
       colorscheme = "gruvbox";
     };
   }
   ```

7. **Rebuild and Verify**:
   ```bash
   task nix:refresh
   # Visual check: All apps now use Gruvbox colors
   ```

**Success Criteria**:
- ✅ Can switch between palettes without errors
- ✅ All applications reflect new palette
- ✅ Multiple palette changes in sequence work correctly
- ✅ Each palette's colors are distinct and recognizable

---

### Scenario 3: Change System Font

**User Story**: US3 - Change System Font
**Priority**: P3

**Steps**:

1. **Initial State**: Check current font
   ```bash
   # If font config exists
   grep -A 5 "font = {" values.nix
   # Or check default (JetBrainsMono Nerd Font)
   ```

2. **Edit Configuration**: Change monospace font
   ```nix
   # Edit values.nix
   {
     theme = {
       appearance = "dark";
       colorscheme = "catppuccin";
       font = {
         monospace = "Fira Code Nerd Font";     # Change to different font
         nerdfontFallback = "Symbols Nerd Font";
       };
     };
   }
   ```

3. **Validate Build**:
   ```bash
   task nix:build
   # Expected: Build succeeds (font availability checked at runtime)
   ```

4. **Apply Changes**:
   ```bash
   task nix:refresh
   ```

5. **Verify Font Changes**:

   **Wezterm**:
   ```bash
   # Restart Wezterm
   # Visual check: Font should be Fira Code with ligatures

   # Check theme JSON
   cat ~/.config/wezterm/theme.json | jq '.font.monospace'
   # Expected: "Fira Code Nerd Font"
   ```

   **Neovim**:
   ```bash
   nvim
   # Visual check: Font should match Wezterm
   # Check theme JSON
   cat ~/.config/nvim/theme.json | jq '.font.monospace'
   # Expected: "Fira Code Nerd Font"
   ```

6. **Test Font Fallback**: Use non-existent font
   ```nix
   # Edit values.nix
   {
     theme = {
       font = {
         monospace = "NonExistentFont Nerd Font";
       };
     };
   }
   ```

7. **Rebuild and Verify Fallback**:
   ```bash
   task nix:refresh
   # Applications should fall back to JetBrainsMono Nerd Font
   # No crashes or errors
   ```

**Success Criteria**:
- ✅ Font changes apply to Wezterm and Neovim
- ✅ Font setting propagates through theme JSON
- ✅ Non-existent fonts fall back gracefully
- ✅ Nerd font glyphs render correctly

---

### Scenario 4: Invalid Palette + Appearance Combination

**Edge Case**: Missing Light/Dark Variant
**Priority**: P1 (Validation)

**Steps**:

1. **Edit Configuration**: Request unsupported combination
   ```nix
   # Edit values.nix
   {
     theme = {
       appearance = "light";
       colorscheme = "nord";      # Assuming nord only supports dark
     };
   }
   ```

2. **Attempt Build**:
   ```bash
   task nix:build

   # Expected: Build FAILS with clear error message
   ```

3. **Verify Error Message**:
   ```
   Expected error format:

   Theme validation failed: Palette 'nord' does not support appearance mode 'light'.

   Available appearance modes for 'nord': dark

   Palettes supporting 'light' mode:
     - catppuccin
     - rose-pine
     - gruvbox
     - solarized

   Please either:
     1. Change appearance to "dark", or
     2. Change colorscheme to a light-mode compatible palette
   ```

4. **Fix Configuration**: Choose valid combination
   ```nix
   {
     theme = {
       appearance = "light";
       colorscheme = "gruvbox";   # Supports light mode
     };
   }
   ```

5. **Rebuild**:
   ```bash
   task nix:build
   # Expected: Build succeeds
   ```

**Success Criteria**:
- ✅ Build fails immediately at evaluation time
- ✅ Error message clearly states the problem
- ✅ Error message lists available options
- ✅ Error message suggests actionable fixes
- ✅ No system changes occur when validation fails

---

### Scenario 5: Malformed Configuration Values

**Edge Case**: Invalid Configuration
**Priority**: P1 (Validation)

**Test Cases**:

#### 5a. Invalid Appearance Mode
```nix
{
  theme = {
    appearance = "twilight";  # Invalid: not "light" or "dark"
  };
}
```
**Expected**: Build fails with error: `appearance must be "light" or "dark", got "twilight"`

#### 5b. Invalid Colorscheme
```nix
{
  theme = {
    colorscheme = "nonexistent-palette";
  };
}
```
**Expected**: Build fails with error: `Theme 'nonexistent-palette' not found. Available themes: catppuccin, kanagawa, rose-pine, gruvbox, solarized, nord`

#### 5c. Invalid Transparency Opacity
```nix
{
  theme = {
    transparency = {
      opacity = 1.5;  # Invalid: must be 0.0-1.0
    };
  };
}
```
**Expected**: Build fails with type error or range validation error

#### 5d. Empty Font String
```nix
{
  theme = {
    font = {
      monospace = "";  # Invalid: empty string
    };
  };
}
```
**Expected**: Build fails with validation error: "Font name cannot be empty"

**Success Criteria**:
- ✅ Each invalid config fails at build time
- ✅ Error messages specify which field is invalid
- ✅ Error messages show the invalid value
- ✅ No partial system updates occur

---

### Scenario 6: Multiple Theme Changes in Sequence

**Integration Test**: Theme Stability
**Priority**: P1

**Steps**:

1. **Initial**: Dark Catppuccin
   ```nix
   { theme = { appearance = "dark"; colorscheme = "catppuccin"; }; }
   ```
   Apply: `task nix:refresh`

2. **Change 1**: Light Rose Pine
   ```nix
   { theme = { appearance = "light"; colorscheme = "rose-pine"; }; }
   ```
   Apply: `task nix:refresh`

3. **Change 2**: Dark Gruvbox + New Font
   ```nix
   {
     theme = {
       appearance = "dark";
       colorscheme = "gruvbox";
       font = { monospace = "Hack Nerd Font"; };
     };
   }
   ```
   Apply: `task nix:refresh`

4. **Change 3**: Light Solarized + Different Transparency
   ```nix
   {
     theme = {
       appearance = "light";
       colorscheme = "solarized";
       transparency = { enable = true; opacity = 0.95; blur = 100; };
     };
   }
   ```
   Apply: `task nix:refresh`

5. **Final**: Back to Dark Catppuccin (full circle)
   ```nix
   { theme = { appearance = "dark"; colorscheme = "catppuccin"; }; }
   ```
   Apply: `task nix:refresh`

**Verification After Each Change**:
- Check theme JSON files contain correct values
- Verify all applications render correctly
- Confirm no configuration drift or corruption
- Test that rollback works at any point

**Success Criteria**:
- ✅ All 5 theme changes apply successfully
- ✅ No build errors throughout sequence
- ✅ No application crashes or rendering issues
- ✅ Theme settings persist across system restart
- ✅ Can rollback to any previous generation

---

### Scenario 7: System Restart Persistence

**Integration Test**: Theme Persistence
**Priority**: P1

**Steps**:

1. **Set Theme**:
   ```nix
   {
     theme = {
       appearance = "light";
       colorscheme = "rose-pine";
       font = { monospace = "Fira Code Nerd Font"; };
       transparency = { opacity = 0.90; };
     };
   }
   ```

2. **Apply**:
   ```bash
   task nix:refresh
   ```

3. **Verify Before Restart**:
   - Launch all applications
   - Confirm theme is applied correctly

4. **Restart System**:
   ```bash
   sudo shutdown -r now
   ```

5. **Verify After Restart**:
   - Launch all applications
   - Confirm theme is still applied correctly
   - Check theme JSON files unchanged

6. **Check Current Generation**:
   ```bash
   darwin-rebuild --list-generations
   # Verify current generation matches pre-restart
   ```

**Success Criteria**:
- ✅ Theme settings persist after restart
- ✅ No configuration drift
- ✅ All applications use correct theme on launch
- ✅ Generation number unchanged

---

## Quick Validation Checklist

Use this checklist for rapid theme validation:

### Visual Checks
- [ ] Wezterm: Background matches appearance mode (light/dark)
- [ ] Wezterm: Text color contrasts properly with background
- [ ] Wezterm: Font matches configured font
- [ ] Neovim: Colorscheme matches palette
- [ ] Neovim: Background mode matches appearance (`:echo &background`)
- [ ] Neovim: Font matches configured font
- [ ] Firefox: Theme colors match palette
- [ ] Firefox: UI elements readable in chosen mode
- [ ] Shell prompt: Colors consistent with theme

### File Checks
- [ ] `~/.config/wezterm/theme.json` exists and valid JSON
- [ ] `~/.config/nvim/theme.json` exists and valid JSON
- [ ] Theme JSON files contain correct `appearance` field
- [ ] Theme JSON files contain correct `colorscheme` field
- [ ] Theme JSON files contain correct `font` configuration

### Build Checks
- [ ] `task nix:build` completes without errors
- [ ] `task nix:refresh` completes without errors
- [ ] No warnings in build output
- [ ] Nix store contains new generation

### Rollback Check
- [ ] `darwin-rebuild --rollback` restores previous theme
- [ ] All applications revert to previous appearance

## Performance Benchmarks

Expected performance for theme changes:

- **Build Time**: < 5 seconds for theme-only changes
- **Activation Time**: < 30 seconds for full darwin-rebuild switch
- **Application Restart**: Immediate theme application on launch
- **Error Detection**: Instant (at Nix evaluation, before any builds)

## Troubleshooting

### Theme not applying to Wezterm
```bash
# Check theme JSON
cat ~/.config/wezterm/theme.json

# Check Wezterm config references theme JSON
grep -r "theme.json" ~/.config/wezterm/

# Verify symlink (if applicable)
ls -la ~/.config/wezterm/theme.json

# Restart Wezterm completely (not just new window)
```

### Theme not applying to Neovim
```bash
# Check theme JSON
cat ~/.config/nvim/theme.json

# Check nvim loads theme
nvim -c "lua print(vim.inspect(require('theme')))"

# Verify colorscheme set
nvim -c "colorscheme"
```

### Build fails with cryptic error
```bash
# Get detailed error output
nix-build --show-trace

# Check values.nix syntax
nix eval --file values.nix

# Validate theme config in isolation
nix-instantiate --eval -E 'with import <nixpkgs> {}; (import ./values.nix).theme'
```

### Font not changing
```bash
# Verify font installed
fc-list | grep -i "your-font-name"

# Check theme JSON has font config
cat ~/.config/wezterm/theme.json | jq '.font'

# Test font in Wezterm config
# Open Wezterm, press Cmd+K to open debug console
# Check for font warnings
```

## Summary

These test scenarios cover:
- **US1**: Light/dark mode switching (Scenario 1)
- **US2**: Color palette changes (Scenario 2)
- **US3**: Font configuration (Scenario 3)
- **Edge Cases**: Validation errors (Scenarios 4, 5)
- **Integration**: Stability and persistence (Scenarios 6, 7)

Run all scenarios to ensure complete theme configuration propagation functionality.
