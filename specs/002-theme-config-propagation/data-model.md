# Data Model: Theme Configuration Propagation

**Feature**: `002-theme-config-propagation`
**Date**: 2025-11-04
**Status**: Complete

## Overview

This document defines the data structures and entities for the theme configuration propagation system. In the context of Nix configuration management, "data model" refers to the shape of configuration options, validation rules, and the relationships between theme entities.

## Core Entities

### 1. ThemeConfiguration

Central user-facing configuration that defines all theme-related settings.

**Location**: `values.nix` (user configuration) + `modules/lib/values/default.nix` (schema)

**Attributes**:
```nix
{
  theme = {
    # NEW: Appearance mode (light or dark)
    appearance = "dark" | "light";  # Default: "dark"

    # EXISTING: Colorscheme selection
    colorscheme = string;  # Default: "catppuccin"

    # EXISTING: Palette variant (will become derived from appearance mapping)
    variant = string;  # Default: "macchiato"

    # NEW: Font configuration
    font = {
      monospace = string;          # Default: "JetBrainsMono Nerd Font"
      nerdfontFallback = string;   # Default: "Symbols Nerd Font"
    };

    # EXISTING: Transparency settings
    transparency = {
      enable = bool;   # Default: true
      opacity = float; # Default: 0.85
      blur = int;      # Default: 80
    };
  };
}
```

**Validation Rules**:
- `appearance`: Must be "light" or "dark"
- `colorscheme`: Must exist in available palettes
- `variant`: Must exist in selected colorscheme's variants (may become auto-derived)
- `font.monospace`: Must be non-empty string (font availability checked at runtime)
- `font.nerdfontFallback`: Must be non-empty string
- `transparency.opacity`: Must be between 0.0 and 1.0
- `transparency.blur`: Must be non-negative integer

**Relationships**:
- Used by → PaletteDefinition (via colorscheme)
- Used by → ApplicationAdapter (all apps read this config)
- Validated by → ThemeValidator

### 2. PaletteDefinition

Defines color values and metadata for a specific color scheme.

**Location**: `modules/lib/theme/palettes/*.nix`

**Attributes**:
```nix
{
  meta = {
    name = string;           # Display name (e.g., "Catppuccin")
    id = string;             # Identifier (e.g., "catppuccin")
    variants = [string];     # List of available variants (e.g., ["latte", "macchiato", "mocha"])
    supports = [string];     # EXISTING: Appearance modes (e.g., ["light", "dark"])

    # NEW: Maps appearance mode to variant name
    appearanceMapping = {
      light = string | null;        # Variant for light mode, null if unsupported
      dark = string | [string];     # Variant(s) for dark mode, null if unsupported
    };

    author = string;         # Author/maintainer
    homepage = string;       # URL to palette source
  };

  palettes = {
    # Each variant has a palette definition
    variantName = {
      # Base colors
      base = hexColor;
      mantle = hexColor;
      crust = hexColor;

      # Surface colors
      surface0 = hexColor;
      surface1 = hexColor;
      surface2 = hexColor;

      # Overlay colors
      overlay0 = hexColor;
      overlay1 = hexColor;
      overlay2 = hexColor;

      # Text colors
      text = hexColor;
      subtext0 = hexColor;
      subtext1 = hexColor;

      # Accent colors
      rosewater = hexColor;
      flamingo = hexColor;
      pink = hexColor;
      mauve = hexColor;
      red = hexColor;
      maroon = hexColor;
      peach = hexColor;
      yellow = hexColor;
      green = hexColor;
      teal = hexColor;
      sky = hexColor;
      sapphire = hexColor;
      blue = hexColor;
      lavender = hexColor;
    };
  };

  # Function to map palette colors to semantic meaning
  semanticMapping = palette: { /* ... */ };

  # Application-specific adapters
  appAdapters = {
    wezterm = variant: string;   # Returns theme identifier for wezterm
    neovim = variant: string;    # Returns theme identifier for neovim
    firefox = variant: string;   # Returns theme identifier for firefox
  };
}
```

**Validation Rules**:
- All hex colors must match `#[0-9a-fA-F]{6}` format
- `variants` list must not be empty
- `supports` must contain "light" and/or "dark"
- `appearanceMapping.light` must reference a variant in `variants` or be null
- `appearanceMapping.dark` must reference variant(s) in `variants` or be null
- At least one appearance mode must be supported

**Relationships**:
- Referenced by → ThemeConfiguration (via colorscheme field)
- Used by → ApplicationAdapter (to generate app configs)
- Validated by → PaletteValidator

### 3. ApplicationAdapter

Transforms theme configuration into application-specific format.

**Location**: `modules/lib/theme/adapters/*.nix`

**Attributes**:
```nix
{
  # Generates application-specific configuration
  createAppConfig = theme: themeConfig: overrides: {
    # App-specific structure
    palette = PaletteColors;
    semanticColors = SemanticColors;
    config = MergedConfig;
    # ... app-specific fields
  };

  # Generates JSON theme file for application
  generateAppJSON = theme: themeConfig: {
    colorscheme = string;
    variant = string;
    appearance = "light" | "dark";  # NEW
    font = FontConfig;              # NEW
    transparency = TransparencyConfig;
    palette = PaletteColors;
    semanticColors = SemanticColors;
    ansi = AnsiColorMapping;
  };
}
```

**Supported Applications**:
- `wezterm`: Terminal emulator (colors + font)
- `neovim`: Text editor (colors + font + background mode)
- `firefox`: Web browser (theme colors)

**Relationships**:
- Consumes → PaletteDefinition
- Consumes → ThemeConfiguration
- Produces → Application Config Files

### 4. SemanticColorMapping

Maps palette colors to semantic roles for consistent usage across applications.

**Location**: Generated by `theme.semanticMapping` function in each palette

**Attributes**:
```nix
{
  # Background colors
  background = {
    primary = hexColor;      # Main background
    secondary = hexColor;    # Alternate background
    tertiary = hexColor;     # Third-level background
  };

  # Foreground colors
  foreground = {
    primary = hexColor;      # Main text
    secondary = hexColor;    # Secondary text
    tertiary = hexColor;     # Dimmed text
  };

  # UI elements
  ui = {
    border = hexColor;
    selection = hexColor;
    cursor = hexColor;
    lineNumber = hexColor;
  };

  # Diagnostic colors
  diagnostic = {
    error = hexColor;
    warning = hexColor;
    info = hexColor;
    hint = hexColor;
  };

  # Syntax highlighting
  syntax = {
    keyword = hexColor;
    function = hexColor;
    string = hexColor;
    number = hexColor;
    comment = hexColor;
    variable = hexColor;
    type = hexColor;
    constant = hexColor;
    operator = hexColor;
  };

  # Git colors
  git = {
    added = hexColor;
    modified = hexColor;
    removed = hexColor;
  };
}
```

**Relationships**:
- Generated from → PaletteDefinition
- Consumed by → ApplicationAdapter

### 5. FontConfiguration

Defines font settings for monospace contexts.

**Location**: `values.nix` (user config) + embedded in theme JSON

**Attributes**:
```nix
{
  monospace = string;          # Primary monospace font family
  nerdfontFallback = string;   # Fallback for nerd font glyphs

  # Future expansion (out of scope for this feature)
  # size = int;
  # weight = "normal" | "bold" | int;
  # ligatures = bool;
}
```

**Validation Rules**:
- `monospace`: Non-empty string, validated format: "[Family Name] Nerd Font"
- `nerdfontFallback`: Non-empty string

**Relationships**:
- Part of → ThemeConfiguration
- Used by → ApplicationAdapter (wezterm, neovim)

### 6. ThemeValidator

Validates theme configuration at Nix evaluation time.

**Location**: `modules/lib/validation/default.nix` + `modules/lib/theme/default.nix`

**Functions**:
```nix
{
  # Validates appearance mode is "light" or "dark"
  validateAppearanceMode = appearance: bool;

  # Validates palette supports requested appearance mode
  validatePaletteAppearance = colorscheme: appearance: {
    valid = bool;
    error = string | null;
    availableModes = [string];
  };

  # Validates palette definition structure
  validatePalette = palette: bool;

  # Main theme config validator (EXISTING - will enhance)
  validateThemeConfig = config: config | throw error;

  # Validates font configuration format
  validateFont = fontConfig: bool;
}
```

**Error Message Template**:
```
Theme validation failed: {specific_error}

Current configuration:
  appearance: {value}
  colorscheme: {value}
  variant: {value}

{context_specific_details}

Please {suggested_fix}
```

**Relationships**:
- Validates → ThemeConfiguration
- Validates → PaletteDefinition
- Used by → Theme system during Nix evaluation

## State Transitions

### Theme Configuration Update Flow

```
User edits values.nix
        ↓
Nix evaluation begins
        ↓
ThemeValidator.validateThemeConfig()
        ↓
    [Invalid] → Build fails with error message
        ↓
    [Valid]
        ↓
PaletteDefinition loaded based on colorscheme
        ↓
Appearance mode mapped to variant
        ↓
ApplicationAdapters generate configs for each app
        ↓
Theme JSON files written to Nix store
        ↓
Nix build succeeds
        ↓
User runs: task nix:refresh
        ↓
nix-darwin activates new generation
        ↓
Applications restart/relaunch with new theme
```

## Derivation Strategy

Some values can be derived rather than explicitly configured:

**Auto-Derived Values**:
- `variant`: Can be derived from `appearance` + `colorscheme` using `appearanceMapping`
  - If user specifies `variant` explicitly, that takes precedence (backward compatibility)
  - If user specifies only `appearance`, system looks up variant from `appearanceMapping`

**Example Logic**:
```nix
effectiveVariant =
  if config.theme.variant != null then
    config.theme.variant  # User explicit choice
  else
    let palette = getTheme config.theme.colorscheme;
        mapping = palette.meta.appearanceMapping.${config.theme.appearance};
    in
      if isList mapping then head mapping  # Use first variant for appearance
      else mapping;                        # Use the single variant
```

## Backward Compatibility

**Existing Configurations**:
- Current `theme.variant` field remains functional
- New `theme.appearance` field is optional (derived from variant if not specified)
- Existing palette files work without `appearanceMapping` (generates from `supports` field)

**Migration Path**:
1. Add `theme.appearance` to values.nix (optional)
2. Update palettes to include `appearanceMapping` (backward compatible)
3. Existing `variant` usage continues to work
4. New users can use `appearance` + `colorscheme` instead of `variant`

## Summary

The data model centers around:
1. **ThemeConfiguration**: User-facing options in values.nix
2. **PaletteDefinition**: Color scheme definitions with light/dark support
3. **ApplicationAdapter**: Transforms theme to app-specific format
4. **SemanticColorMapping**: Consistent color roles across apps
5. **FontConfiguration**: Monospace font settings with fallbacks
6. **ThemeValidator**: Build-time validation with clear errors

All entities are represented as Nix attribute sets with strong typing via the Nix type system. Validation occurs at evaluation time before any system changes are applied.
