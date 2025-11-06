# Data Model: Theme Configuration Audit & OpenCode Integration

**Date**: 2025-11-06
**Branch**: 003-theme-audit

## Overview

This feature operates on declarative configuration data structures in Nix. There are no traditional database entities or API models. The "data model" consists of Nix attribute sets that define theme configurations.

## Core Entities

### Theme Configuration

**Location**: `values.nix` (user-provided) → validated and enriched by theme library

**Structure**:
```nix
{
  appearance = "dark" | "light";  # OS appearance mode
  colorscheme = "catppuccin" | "rose-pine" | "gruvbox" | "solarized" | "kanagawa" | "nord";
  variant = string;  # Derived from appearance if not specified
  font = {
    monospace = string;  # e.g., "TX-02"
  };
  transparency = {
    enable = bool;
    opacity = float;  # 0.0 to 1.0
    blur = int;
  };
  presets = [ string ];  # Applied theme presets
  overrides = attrs;  # Color overrides
}
```

**Validation Rules**:
- `appearance` must be "light" or "dark"
- `colorscheme` must exist in `themes` attribute set
- `variant` must exist in selected palette's `meta.variants`
- Palette must support the requested `appearance` mode
- If `appearance` + `variant` incompatible, system derives correct variant via `deriveVariantFromAppearance`

**State Transitions**: Static (no runtime state). Configuration validated at Nix evaluation time, applied atomically through generation switching.

---

### Theme Palette

**Location**: `modules/lib/theme/palettes/<palette-name>.nix`

**Structure**:
```nix
{
  meta = {
    name = string;           # Display name (e.g., "Catppuccin")
    id = string;             # Palette identifier (e.g., "catppuccin")
    variants = [ string ];   # Available variants (e.g., ["macchiato"])
    supports = [ string ];   # Supported modes (e.g., ["dark"])
    appearanceMapping = {
      light = string | null; # Variant to use for light mode
      dark = string | null;  # Variant to use for dark mode
    };
    author = string;
    homepage = string;
  };

  palettes = {
    <variant> = {
      # Core colors
      base = hex-color;
      surface = hex-color;
      text = hex-color;

      # Semantic colors (palette-specific names)
      # e.g., "rosewater", "flamingo", "pink" for Catppuccin
      # e.g., "love", "gold", "pine" for Rose Pine
      <color-name> = hex-color;

      # Standard mappings (required)
      accent = hex-color;
      accent_dim = hex-color;
    };
  };

  semanticMapping = palette: {
    # Derived semantic colors
    # Standard roles: foreground, background, primary, secondary, etc.
  };

  appAdapters = {
    wezterm = <theme-name> | { <variant> = <theme-name>; };
    neovim = { plugin, name, setup, colorscheme };
    bat = variant: <theme-name-template>;
    delta = variant: <theme-name-template>;
    # ... other applications
    opencode = <theme-name>;  # NEW - being added
  };
}
```

**Relationships**:
- `meta.id` must match filename (minus .nix extension)
- Each variant in `meta.variants` must have entry in `palettes.<variant>`
- `appearanceMapping` values must be in `meta.variants` or null
- All `appAdapters` values reference external theme names/configurations

**Validation Rules**:
- Required fields: `meta`, `palettes`, `semanticMapping`, `appAdapters`
- `palettes.<variant>` must pass `utils.validatePalette` (ensures all required colors defined)
- `meta.variants` must be non-empty list
- `meta.supports` must be subset of ["dark", "light"]

---

### Application Adapter

**Location**: `appAdapters` attribute in palette file

**Types**:

**1. Simple String** (theme name doesn't vary by variant):
```nix
opencode = "catppuccin";
```

**2. Function** (theme name includes variant):
```nix
bat = variant: "catppuccin-${variant}";
```

**3. Attribute Set** (different theme per variant):
```nix
wezterm = {
  macchiato = "Catppuccin Macchiato";
  latte = "Catppuccin Latte";
};
```

**4. Plugin Configuration** (for editor plugins):
```nix
neovim = {
  plugin = "catppuccin/nvim";
  name = "catppuccin";
  setup = "catppuccin";
  colorscheme = "catppuccin";
};
```

**5. Color Mapping** (for apps needing raw colors):
```nix
sketchybar = {
  background = palettes.macchiato.base;
  foreground = palettes.macchiato.text;
  accent = palettes.macchiato.accent;
};
```

**Relationships**:
- Consumed by `getAppTheme` function in theme library
- Must return string (theme name) or attrs (configuration) for the application
- OpenCode uses **Type 1** (simple string)

---

### OpenCode Configuration

**Location**: `~/.config/opencode/opencode.json` (deployed via Home Manager)

**Structure**:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "catppuccin" | "gruvbox" | "kanagawa" | "nord" | "system" | <custom-theme-path>,
  "share": "disabled" | "enabled",
  "autoupdate": true | false,
  "mcp": { /* MCP server configs */ },
  "lsp": { /* LSP configs */ },
  "agent": { /* Agent configs */ }
}
```

**Validation Rules**:
- `theme` field must be string (either built-in theme name or path)
- Generated at Nix build time from `values.theme` via theme library
- Deployed to XDG config via Home Manager

**State Transitions**: Regenerated on each `darwin-rebuild switch`, applied when OpenCode restarts.

---

## Data Flow

```
values.nix (user input)
    ↓
validateThemeConfig() → validates appearance/colorscheme/variant
    ↓
getAppTheme("opencode", colorscheme, variant) → resolves theme name
    ↓
palette.<colorscheme>.appAdapters.opencode → returns "catppuccin" or "system"
    ↓
opencode.nix config file generation → { theme = "<resolved-name>"; ... }
    ↓
Home Manager deployment → ~/.config/opencode/opencode.json
    ↓
OpenCode reads config on launch → displays theme
```

---

## Validation Points

**Build Time** (Nix evaluation):
1. `validateThemeConfig` ensures theme config structure is valid
2. `getTheme` ensures colorscheme exists
3. `getThemePalette` ensures variant exists for colorscheme
4. `getAppTheme` ensures adapter exists for app (returns theme name or throws)

**Validation Script** (`validation-tests/theme-audit.sh`):
1. Iterates through all 6 palettes
2. For each palette, checks if adapter exists for each of 12 applications
3. Reports missing adapters (not a build failure, but documentation gap)

**Manual Testing** (user verification):
1. Change `values.theme.colorscheme` to each palette
2. Run `task nix:refresh`
3. Launch applications and verify theme matches

---

## Extension Points

**Adding New Palette**:
1. Create `modules/lib/theme/palettes/<new-palette>.nix`
2. Define `meta`, `palettes`, `semanticMapping`, `appAdapters`
3. Add to `themes` attribute set in `modules/lib/theme/default.nix`
4. Run validation script to ensure all adapters defined

**Adding New Application**:
1. Add adapter to each palette file's `appAdapters`
2. Create application config in `modules/home/configurations/<app>/`
3. Use `getAppTheme` to resolve theme name from validated config
4. Deploy via Home Manager or darwin configuration

**Adding OpenCode Custom Themes** (future):
1. Generate theme JSON from palette colors via `generateAppJSON`
2. Deploy to `~/.config/opencode/themes/<palette>-<variant>.json`
3. Reference by filename in opencode.json: `theme = "catppuccin-macchiato"`
4. Requires implementing OpenCode adapter module (currently out of scope)

---

## Constraints

1. **No Runtime Modification**: Themes are declarative and immutable per generation. Changes require rebuild.
2. **No Per-App Overrides**: All applications use same system theme (values.theme applies globally).
3. **Variant Granularity Mismatch**: OpenCode built-in themes don't expose variants. Our variant selection doesn't affect OpenCode theme choice.
4. **Palette Coverage**: Only 4/6 palettes have native OpenCode themes. Rose Pine and Solarized fall back to "system".

---

## Testing Considerations

**What Can Be Validated**:
- Structure of palette files (Nix evaluation)
- Presence of required fields (type checking)
- Validity of color hex codes (validatePalette)
- Existence of theme/variant combinations (validateThemeConfig)

**What Cannot Be Automated**:
- Visual appearance of themes across applications
- Color accuracy (requires human perception)
- OpenCode's interpretation of theme names (external system)
- User satisfaction with theme choices

**Testing Strategy**:
- Structural: Rely on Nix evaluation and type system
- Coverage: Use validation script to report gaps
- Visual: Manual testing procedure in documentation
