# Theme Library API Contract

**Date**: 2025-11-06
**Branch**: 003-theme-audit

## Overview

This document defines the contract between theme palette definitions and the theme library functions. This is not a REST/GraphQL API but a Nix function interface contract.

## Core Functions

### `getTheme`

**Signature**: `string -> ThemePalette`

**Purpose**: Retrieve a theme palette definition by ID

**Input**:
- `themeId` (string): Palette identifier (e.g., "catppuccin", "gruvbox")

**Output**: Theme palette attribute set with structure:
```nix
{
  meta = { name, id, variants, supports, appearanceMapping, author, homepage };
  palettes = { <variant> = { <color> = <hex>; }; };
  semanticMapping = <function>;
  appAdapters = { <app> = <theme-config>; };
}
```

**Errors**:
- Throws if `themeId` not found in `themes` attribute set
- Error message: "Theme '${themeId}' not found. Available themes: ${available}"

**Contract Requirements**:
- Theme file MUST exist in `modules/lib/theme/palettes/${themeId}.nix`
- Theme MUST be registered in `themes` attribute set in `default.nix`
- Theme structure MUST match schema defined in data-model.md

---

### `validateThemeConfig`

**Signature**: `ThemeConfig -> ValidatedThemeConfig`

**Purpose**: Validate and enrich user theme configuration

**Input**:
```nix
{
  colorscheme = string;
  variant = string;
  appearance = string | null;  # Optional
  font = attrs | null;          # Optional
  transparency = attrs;
  presets = [ string ];
  overrides = attrs;
}
```

**Output**: Validated and enriched configuration with derived variant:
```nix
{
  colorscheme = string;
  variant = string;  # Possibly derived from appearance
  appearance = string | null;
  font = attrs | null;
  transparency = attrs;
  presets = [ string ];
  overrides = attrs;
}
```

**Validation Rules**:
1. `colorscheme` MUST exist in registered themes
2. `variant` MUST exist in theme's `meta.variants`
3. If `appearance` specified, theme MUST support it (in `meta.supports`)
4. If `appearance` + `variant` incompatible, derive correct variant via `deriveVariantFromAppearance`
5. Font configuration (if present) MUST pass `validators.validateFont`

**Errors**:
- Invalid colorscheme: Lists available themes
- Invalid variant: Lists available variants for theme
- Unsupported appearance: Shows what theme supports
- Font validation failure: Shows specific validation error

**Side Effects**: None (pure function)

---

### `getAppTheme`

**Signature**: `string -> string -> string -> (string | attrs)`

**Purpose**: Resolve application-specific theme identifier from palette adapter

**Input**:
- `app` (string): Application name (e.g., "opencode", "wezterm")
- `colorscheme` (string): Palette ID (e.g., "catppuccin")
- `variant` (string): Variant name (e.g., "macchiato")

**Output**: Theme identifier or configuration for the application
- String: Theme name (e.g., "catppuccin", "Gruvbox dark, hard")
- Attrs: Configuration object (for neovim, firefox, sketchybar)

**Resolution Logic**:
1. Get theme palette via `getTheme(colorscheme)`
2. Look up `theme.appAdapters[app]`
3. If adapter is string: return as-is
4. If adapter is function: call with `variant` parameter
5. If adapter is attrs with variant key: return `adapter[variant]`
6. If adapter is attrs without variant key: return attrs as-is
7. If adapter not found: return `"${colorscheme}-${variant}"`

**Errors**:
- If theme doesn't exist: throws from `getTheme`
- If adapter type is unexpected: falls back to `"${colorscheme}-${variant}"`

**Contract for Palette Adapters**:
- MUST define adapter for all supported applications
- String adapters: Use when theme name is constant across variants
- Function adapters: Use when theme name includes variant
- Attrs adapters: Use when different themes per variant OR structured config needed

---

### `deriveVariantFromAppearance`

**Signature**: `string -> (string | null) -> string -> string`

**Purpose**: Derive correct variant based on appearance mode preference

**Input**:
- `colorscheme` (string): Palette ID
- `appearance` (string | null): Desired appearance ("light" or "dark" or null)
- `currentVariant` (string): Current/requested variant

**Output**: Resolved variant name that matches appearance mode

**Resolution Logic**:
1. If `appearance` is null: return `currentVariant` (backward compatibility)
2. Check if `currentVariant` is compatible with `appearance` via `appearanceMapping`
3. If compatible: return `currentVariant`
4. If incompatible: derive from `appearanceMapping[appearance]`
5. If theme doesn't support `appearance`: throw with error

**Errors**:
- Theme doesn't support appearance: "Cannot derive variant: colorscheme '${colorscheme}' does not support appearance mode '${appearance}'"

**Example**:
```nix
# Gruvbox with light appearance requested but dark variant provided
deriveVariantFromAppearance "gruvbox" "light" "dark"
# Returns: "light" (from appearanceMapping.light)

# Catppuccin only supports dark, light requested
deriveVariantFromAppearance "catppuccin" "light" "macchiato"
# Throws: Catppuccin does not support light mode
```

---

## Application-Specific Contracts

### OpenCode Adapter Contract

**Location**: `palette.appAdapters.opencode`

**Type**: String (simple adapter)

**Expected Values**:
- For palettes with OpenCode built-in theme: palette name (e.g., `"catppuccin"`)
- For palettes without OpenCode theme: `"system"` (fallback)

**Implementation Requirements**:
```nix
# In catppuccin.nix, gruvbox.nix, kanagawa.nix, nord.nix
appAdapters = {
  # ... other adapters
  opencode = "catppuccin";  # Use lowercase palette name
};

# In rose-pine.nix, solarized.nix
appAdapters = {
  # ... other adapters
  opencode = "system";  # Fallback to system theme
};
```

**Validation**:
- MUST be defined in all palette files
- MUST be string type (not function or attrs)
- SHOULD be lowercase (OpenCode convention)

**Usage in opencode.nix**:
```nix
let
  themes = import ../../lib/theme { inherit lib; };
  validatedTheme = themes.validateThemeConfig values.theme;
  opencodeTheme = themes.getAppTheme "opencode"
                   validatedTheme.colorscheme
                   validatedTheme.variant;
in
{
  xdg.configFile."opencode/opencode.json" = {
    text = builtins.toJSON {
      theme = opencodeTheme;  # Resolved theme name
      # ... other config
    };
  };
}
```

---

## Validation Script Contract

### Theme Audit Script

**Location**: `specs/003-theme-audit/validation-tests/theme-audit.sh`

**Purpose**: Verify all palette-app adapter combinations are defined

**Input**: None (reads from modules/lib/theme/palettes/)

**Output**: Report of missing adapters

**Format**:
```
Theme Adapter Audit Report
==========================

Palette: catppuccin
  ✓ wezterm
  ✓ neovim
  ✓ opencode
  ✗ some-new-app (MISSING)

Palette: rose-pine
  ✓ wezterm
  ✓ opencode
  ...

Summary:
- Total palettes: 6
- Total applications: 12
- Missing adapters: 2
```

**Exit Code**:
- 0: All adapters defined
- 1: Some adapters missing

**Contract Requirements**:
- MUST check all palettes in `modules/lib/theme/palettes/*.nix`
- MUST check for all applications listed in theme library
- MUST report missing adapters (not throw errors)
- SHOULD be runnable as part of pre-commit hook (optional)

---

## Backward Compatibility

**Guarantees**:
1. Existing palette files without `opencode` adapter continue to work (getAppTheme falls back)
2. Existing application configs using theme library are unaffected
3. values.nix structure unchanged (no new required fields)

**Breaking Changes**: None

**Deprecations**: None

---

## Testing Contract

**Build-Time Tests** (Nix evaluation):
- All palette files parse successfully
- `getTheme` returns valid structure for each palette
- `validateThemeConfig` accepts valid configs, rejects invalid ones
- `getAppTheme` resolves theme names for all palette-app combinations

**Manual Tests** (documented in quickstart.md):
- Visual verification of theme application
- OpenCode displays correct theme after rebuild
- Theme changes propagate to all applications

**Validation Tests** (theme-audit.sh):
- All adapters defined
- No missing palette-app combinations
- Report generation succeeds
