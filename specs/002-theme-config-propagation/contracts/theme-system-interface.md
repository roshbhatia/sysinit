# Theme System Interface Contract

**Feature**: `002-theme-config-propagation`
**Date**: 2025-11-04

## Overview

This document defines the interface contracts between the theme system and various consumers (applications, validators, utilities). While not traditional API contracts, these define the expected inputs, outputs, and behaviors.

## 1. Values Configuration Contract

### Input: User Configuration (`values.nix`)

**Contract**: Users provide theme configuration following this schema.

```nix
{
  theme = {
    appearance = "light" | "dark";           # NEW: Required appearance mode
    colorscheme = string;                    # Required: Must be valid palette ID
    variant = string | null;                 # Optional: Auto-derived if null
    font = {
      monospace = string;                    # Optional: Defaults to "JetBrainsMono Nerd Font"
      nerdfontFallback = string;             # Optional: Defaults to "Symbols Nerd Font"
    };
    transparency = {
      enable = bool;                         # Optional: Defaults to true
      opacity = float;                       # Optional: Defaults to 0.85
      blur = int;                            # Optional: Defaults to 80
    };
  };
}
```

**Guarantees**:
- All fields have sensible defaults
- Invalid configurations fail at Nix evaluation time
- Error messages indicate which field is invalid and why

**Example Valid Configurations**:

```nix
# Minimal configuration (all defaults)
{ theme = {}; }

# Light mode with specific palette
{
  theme = {
    appearance = "light";
    colorscheme = "rose-pine";
  };
}

# Full configuration
{
  theme = {
    appearance = "dark";
    colorscheme = "catppuccin";
    variant = "macchiato";  # Optional override
    font = {
      monospace = "TX-02 Nerd Font";
      nerdfontFallback = "Symbols Nerd Font";
    };
    transparency = {
      enable = true;
      opacity = 0.90;
      blur = 60;
    };
  };
}
```

## 2. Palette Definition Contract

### Input: Palette Module (`modules/lib/theme/palettes/*.nix`)

**Contract**: Palette files must export this structure.

```nix
{
  meta = {
    name = string;              # Required: Display name
    id = string;                # Required: Unique identifier (lowercase-kebab)
    variants = [string];        # Required: Non-empty list of variant names
    supports = [string];        # Required: ["light"] and/or ["dark"]
    appearanceMapping = {       # NEW Required: Maps appearance to variant
      light = string | null;    # Variant name for light mode, or null
      dark = string | null;     # Variant name for dark mode, or null
    };
    author = string;            # Required: Palette author
    homepage = string;          # Required: Source URL
  };

  palettes = {
    variantName = {             # Required: At least one variant
      # Base colors (required)
      base = hexColor;
      mantle = hexColor;
      crust = hexColor;

      # Surface colors (required)
      surface0 = hexColor;
      surface1 = hexColor;
      surface2 = hexColor;

      # Overlay colors (required)
      overlay0 = hexColor;
      overlay1 = hexColor;
      overlay2 = hexColor;

      # Text colors (required)
      text = hexColor;
      subtext0 = hexColor;
      subtext1 = hexColor;

      # Accent colors (required)
      red = hexColor;
      green = hexColor;
      yellow = hexColor;
      blue = hexColor;
      # ... (additional accent colors optional but recommended)
    };
  };

  semanticMapping = palette: { /* Semantic color mapping */ };

  appAdapters = {
    wezterm = variant: string;
    neovim = variant: string;
    firefox = variant: string;
  };
}
```

**Guarantees**:
- All hex colors validated at build time
- Variant names must be unique within palette
- `appearanceMapping` must reference defined variants or be null
- At least one appearance mode must be supported

**Validation Rules**:
- Hex colors match `#[0-9a-fA-F]{6}`
- `appearanceMapping.light` in `variants` or is null
- `appearanceMapping.dark` in `variants` or is null
- If `appearanceMapping.light` is null, "light" not in `supports`
- If `appearanceMapping.dark` is null, "dark" not in `supports`

## 3. Application Adapter Contract

### Input: Theme Configuration + Palette
### Output: Application-Specific Configuration

**Contract**: Adapters transform theme configuration into app-specific format.

### Function Signatures

```nix
{
  # Create application configuration object
  createAppConfig = theme: themeConfig: overrides: {
    # Returns app-specific configuration
    meta = ThemeMeta;
    palette = PaletteColors;
    semanticColors = SemanticColors;
    config = MergedConfig;
    colorscheme = string;          # "{colorscheme}-{variant}"
    variant = string;
    transparency = TransparencyConfig;
    # ... app-specific fields
  };

  # Generate JSON theme file for application
  generateAppJSON = theme: themeConfig: {
    colorscheme = string;
    variant = string;
    appearance = "light" | "dark";     # NEW
    font = {                           # NEW
      monospace = string;
      nerdfontFallback = string;
    };
    transparency = TransparencyConfig;
    palette = PaletteColors;
    semanticColors = SemanticColors;
    ansi = AnsiColorMapping;
    # ... app-specific fields
  };
}
```

### Per-Application Contracts

#### Wezterm Adapter (`adapters/wezterm.nix`)

**Inputs**: Theme, ThemeConfig
**Output**: Wezterm color configuration

**Required Fields in Output JSON**:
```json
{
  "colorscheme": "catppuccin-macchiato",
  "variant": "macchiato",
  "appearance": "dark",
  "font": {
    "monospace": "JetBrainsMono Nerd Font",
    "nerdfontFallback": "Symbols Nerd Font"
  },
  "colors": {
    "background": "#24273a",
    "foreground": "#cad3f5",
    "cursor_bg": "#cad3f5",
    "cursor_border": "#cad3f5",
    "ansi": ["#494d64", "#ed8796", "#a6da95", ...],
    "brights": ["#5b6078", "#ee99a0", "#b8c0e0", ...]
  },
  "transparency": {
    "enable": true,
    "opacity": 0.85,
    "blur": 80
  }
}
```

**Guarantees**:
- All ANSI colors defined (16 colors)
- Font configuration included
- Colors match palette variant

#### Neovim Adapter (`adapters/neovim.nix`)

**Inputs**: Theme, ThemeConfig
**Output**: Neovim colorscheme configuration

**Required Fields in Output JSON**:
```json
{
  "colorscheme": "catppuccin-macchiato",
  "variant": "macchiato",
  "appearance": "dark",
  "background": "dark",
  "font": {
    "monospace": "JetBrainsMono Nerd Font"
  },
  "palette": {
    "base": "#24273a",
    "text": "#cad3f5",
    ...
  },
  "semanticColors": {
    "background": { "primary": "#24273a", ... },
    "foreground": { "primary": "#cad3f5", ... },
    ...
  }
}
```

**Guarantees**:
- `background` field set to "light" or "dark" based on appearance
- Font configuration included
- Palette contains all required color keys

#### Firefox Adapter (`adapters/firefox.nix`)

**Inputs**: Theme, ThemeConfig
**Output**: Firefox theme configuration

**Required Fields in Output JSON**:
```json
{
  "colorscheme": "catppuccin-macchiato",
  "variant": "macchiato",
  "appearance": "dark",
  "colors": {
    "toolbar": "#24273a",
    "toolbar_text": "#cad3f5",
    "frame": "#1e2030",
    "tab_background_text": "#cad3f5",
    "tab_selected": "#363a4f",
    "popup": "#24273a",
    "popup_text": "#cad3f5",
    "popup_border": "#494d64"
  }
}
```

**Guarantees**:
- All Firefox theme color keys defined
- Colors appropriate for light/dark appearance

## 4. Validator Contract

### Theme Configuration Validator

**Function**: `validateThemeConfig(config)`

**Input**: ThemeConfiguration (from values.nix)
**Output**: Validated config OR throw error

**Validation Sequence**:
1. Check `appearance` is "light" or "dark"
2. Check `colorscheme` exists in available palettes
3. Load palette definition
4. Check palette supports requested appearance mode
5. Derive or validate `variant` against palette
6. Validate font configuration format
7. Validate transparency values

**Error Output Format**:
```
Theme validation failed: {error_type}

Current configuration:
  appearance: {value}
  colorscheme: {value}
  variant: {value}

{detailed_explanation}

Available options:
  {list_of_valid_options}

Suggested fix:
  {actionable_suggestion}
```

**Example Error Messages**:

```
Theme validation failed: Unsupported appearance mode

Current configuration:
  appearance: light
  colorscheme: nord

The palette 'nord' does not support appearance mode 'light'.

Available appearance modes for 'nord':
  - dark (variants: nord)

Palettes supporting 'light' mode:
  - catppuccin (variants: latte)
  - rose-pine (variants: dawn)
  - gruvbox (variants: light)
  - solarized (variants: light)

Suggested fix:
  Either change appearance to "dark" or change colorscheme to a palette that supports light mode.
```

### Palette Validator

**Function**: `validatePalette(palette)`

**Input**: Palette color object
**Output**: Valid palette OR throw error

**Validation Rules**:
- All color values are hex strings
- Hex strings match `#[0-9a-fA-F]{6}` format
- Required color keys present (base, text, etc.)

## 5. Build-Time Contracts

### Nix Evaluation Contract

**Timing**: Before any system changes applied
**Guarantee**: Invalid configurations never reach activation

**Evaluation Order**:
1. Load values.nix
2. Validate theme configuration
3. Load palette definition
4. Generate application configs
5. Build Nix store derivations
6. IF any step fails → Abort with error
7. IF all succeed → Proceed to activation

**Atomicity Guarantee**:
- Either ALL applications get new theme, or NONE do
- No partial theme updates
- Rollback available via `darwin-rebuild --rollback`

## 6. Runtime Contracts

### Application Launch Contract

**When**: Application starts/restarts after `task nix:refresh`

**Expected Behavior**:
1. Application reads theme JSON from Nix store path
2. Application applies colors from JSON
3. Application applies font from JSON (if applicable)
4. Application applies transparency from JSON (if applicable)

**File Locations**:
- Wezterm: `~/.config/wezterm/theme.json` (or symlink)
- Neovim: `~/.config/nvim/theme.json` (or symlink)
- Firefox: Applied via home-manager configuration

**Fallback Behavior**:
- If theme JSON missing: Application uses default theme
- If font unavailable: Application uses fallback font
- If color invalid: Application ignores invalid color

## Summary

These contracts ensure:
1. **Type Safety**: Nix type system enforces structure
2. **Early Validation**: Errors caught at build time
3. **Clear Errors**: Actionable error messages with context
4. **Atomicity**: All-or-nothing theme updates
5. **Consistency**: All apps receive same theme configuration
6. **Extensibility**: New palettes/apps follow same contracts
