# Quick Start: Theme Configuration Audit & OpenCode Integration

**Date**: 2025-11-06
**Branch**: 003-theme-audit

## Overview

This guide covers how to test and verify the theme configuration audit changes, particularly OpenCode theme integration.

## Prerequisites

- Nix installed with flakes enabled
- nix-darwin configured
- OpenCode installed and enabled (`values.llm.opencode.enabled = true`)
- Access to sysinit repository on branch `003-theme-audit`

## Testing the Changes

### 1. Verify Build Success

Ensure the configuration builds without errors:

```bash
# From repository root
task nix:build
```

**Expected**: Build completes successfully with no evaluation errors.

**If build fails**: Check error message for invalid theme configuration or missing adapters.

---

### 2. Test OpenCode Theme Integration

**Test Scenario**: Verify OpenCode respects system theme

**Steps**:

1. **Check current theme configuration**:
   ```bash
   cat values.nix | grep -A 5 "theme ="
   ```

   Note the current `colorscheme` (e.g., "catppuccin").

2. **Apply configuration**:
   ```bash
   task nix:refresh
   ```

3. **Verify OpenCode config generated correctly**:
   ```bash
   cat ~/.config/opencode/opencode.json | jq '.theme'
   ```

   **Expected**: Should output `"catppuccin"` (matching your palette), not `"system"`.

4. **Launch OpenCode**:
   ```bash
   opencode
   ```

   **Expected**: OpenCode displays with Catppuccin theme colors.

5. **Change theme to test another palette**:
   ```bash
   # Edit values.nix
   nvim values.nix
   # Change: colorscheme = "gruvbox";

   # Rebuild and apply
   task nix:refresh

   # Verify new theme
   cat ~/.config/opencode/opencode.json | jq '.theme'
   # Expected: "gruvbox"

   # Launch OpenCode to verify visually
   opencode
   ```

---

### 3. Test Fallback Themes

**Test Scenario**: Verify Rose Pine and Solarized fall back to "system"

**Steps**:

1. **Set theme to Rose Pine**:
   ```bash
   # Edit values.nix
   nvim values.nix
   # Change: colorscheme = "rose-pine";

   # Rebuild
   task nix:refresh

   # Check generated config
   cat ~/.config/opencode/opencode.json | jq '.theme'
   # Expected: "system"
   ```

2. **Verify system theme appearance**:
   ```bash
   opencode
   ```

   **Expected**: OpenCode adapts to terminal background color (light/dark detection).

3. **Test Solarized** (same process):
   ```bash
   # Set colorscheme = "solarized" in values.nix
   # Rebuild and verify theme = "system"
   ```

---

### 4. Run Validation Audit

**Test Scenario**: Verify all palette-app adapters are defined

**Steps**:

1. **Run audit script**:
   ```bash
   bash specs/003-theme-audit/validation-tests/theme-audit.sh
   ```

2. **Review output**:
   ```
   Theme Adapter Audit Report
   ==========================

   Palette: catppuccin
     ✓ wezterm
     ✓ neovim
     ✓ opencode
     ...

   Summary:
   - Total palettes: 6
   - Total applications: 12
   - Missing adapters: 0
   ```

3. **Expected**: All adapters present, no missing entries.

---

### 5. Test All Palettes

**Test Scenario**: Systematically verify each palette

**Matrix**:

| Palette     | OpenCode Theme | Visual Verification |
|-------------|----------------|---------------------|
| catppuccin  | `"catppuccin"` | Dark purple accent  |
| gruvbox     | `"gruvbox"`    | Warm earthy tones   |
| kanagawa    | `"kanagawa"`   | Dark green-blue     |
| nord        | `"nord"`       | Arctic blue-grey    |
| rose-pine   | `"system"`     | Adapts to terminal  |
| solarized   | `"system"`     | Adapts to terminal  |

**Procedure for each palette**:

```bash
# 1. Edit values.nix
nvim values.nix
# Set: colorscheme = "<palette>";

# 2. Rebuild
task nix:refresh

# 3. Verify config
cat ~/.config/opencode/opencode.json | jq '.theme'

# 4. Visual check
opencode
# Verify theme matches expected appearance

# 5. Test other applications
wezterm  # Check terminal theme
nvim     # Check editor theme
bat --list-themes | grep -i <palette>  # Verify bat theme
```

---

### 6. Test Appearance Mode Switching

**Test Scenario**: Verify light/dark mode switching

**Note**: Only Gruvbox and Solarized have light variants. Other palettes are dark-only.

**Steps for Gruvbox**:

1. **Set dark mode**:
   ```nix
   # values.nix
   theme = {
     appearance = "dark";
     colorscheme = "gruvbox";
   };
   ```

   ```bash
   task nix:refresh
   opencode  # Verify dark Gruvbox
   ```

2. **Set light mode**:
   ```nix
   # values.nix
   theme = {
     appearance = "light";
     colorscheme = "gruvbox";
   };
   ```

   ```bash
   task nix:refresh
   opencode  # Verify light Gruvbox (if OpenCode supports it)
   ```

**Note**: OpenCode's built-in "gruvbox" theme may not distinguish light/dark variants. This is a known limitation documented in research.md.

---

### 7. Test Invalid Configurations

**Test Scenario**: Verify build fails with clear errors

**Test 1: Invalid palette**:
```nix
# values.nix
theme = {
  colorscheme = "nonexistent";
};
```

```bash
task nix:build
# Expected: Error listing available themes
```

**Test 2: Invalid variant**:
```nix
# values.nix
theme = {
  colorscheme = "catppuccin";
  variant = "latte";  # Catppuccin only has "macchiato"
};
```

```bash
task nix:build
# Expected: Error listing available variants for Catppuccin
```

**Test 3: Unsupported appearance**:
```nix
# values.nix
theme = {
  appearance = "light";
  colorscheme = "catppuccin";  # Only supports dark
};
```

```bash
task nix:build
# Expected: Error indicating Catppuccin doesn't support light mode
```

---

## Common Issues

### Issue: OpenCode still shows "system" theme after rebuild

**Diagnosis**:
```bash
cat ~/.config/opencode/opencode.json | jq '.theme'
```

**Possible Causes**:
1. OpenCode config not regenerated (Home Manager issue)
2. Palette adapter not defined
3. Theme library not imported correctly in opencode.nix

**Fix**:
```bash
# Force Home Manager to regenerate
rm ~/.config/opencode/opencode.json
task nix:refresh

# Check if file regenerated
ls -l ~/.config/opencode/opencode.json
```

---

### Issue: Build fails with theme validation error

**Diagnosis**: Read error message carefully - it shows which field failed validation.

**Common Fixes**:
- Ensure `colorscheme` is one of: catppuccin, rose-pine, gruvbox, solarized, kanagawa, nord
- Ensure `appearance` is "light" or "dark"
- Check that palette supports the requested appearance mode

---

### Issue: OpenCode theme doesn't match other applications

**Expected Behavior**:
- Catppuccin, Gruvbox, Kanagawa, Nord: Should match closely (use built-in themes)
- Rose Pine, Solarized: Will differ (use "system" theme in OpenCode)

**Not a Bug**: OpenCode's built-in themes may interpret palette colors differently than other applications. This is documented in constraints.

---

## Verification Checklist

Use this checklist to confirm all acceptance criteria from spec.md:

### User Story 1: OpenCode Reflects System Theme

- [ ] OpenCode displays Catppuccin theme when `colorscheme = "catppuccin"`
- [ ] OpenCode displays Gruvbox theme when `colorscheme = "gruvbox"`
- [ ] OpenCode theme changes after rebuild when switching palettes

### User Story 2: All Themes Work Across Applications

- [ ] Catppuccin works in all applications (Wezterm, Neovim, OpenCode, bat, etc.)
- [ ] Rose Pine works in all applications (OpenCode uses "system")
- [ ] Gruvbox works in all applications
- [ ] Solarized works in all applications (OpenCode uses "system")
- [ ] Kanagawa works in all applications
- [ ] Nord works in all applications
- [ ] Build fails with clear error for invalid palette-variant combinations

### User Story 3: Theme Configuration Validation

- [ ] Invalid palette name causes build failure with available themes listed
- [ ] Invalid variant causes build failure with valid variants listed
- [ ] Unsupported appearance mode causes build failure with clear message
- [ ] All error messages identify the specific field that failed

---

## Next Steps

After verifying all tests pass:

1. **Document findings** in `specs/003-theme-audit/documentation/theme-support.md`
2. **Run full validation suite** across all applications
3. **Create PR** with changes (if applicable)
4. **Update main README** with any new theme information

## Manual Testing Time Estimate

- Basic verification (steps 1-2): 5 minutes
- Comprehensive testing (all steps): 30 minutes
- Full application suite verification: 1 hour

## Automated Testing (Future)

This feature relies on manual testing due to the visual nature of theme verification. Future enhancements could include:
- Screenshot comparison tests
- Color extraction and validation
- Automated application launching and verification

For now, manual testing following this guide is the recommended approach.
