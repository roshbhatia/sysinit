# Research Findings: Theme Configuration Audit & OpenCode Integration

**Date**: 2025-11-06
**Branch**: 003-theme-audit

## OpenCode Theme System Analysis

### Decision: Use Built-in Theme Names with Fallback Strategy

**Rationale**:
OpenCode provides built-in themes that directly match 4 of our 6 palettes (Catppuccin, Gruvbox, Kanagawa, Nord). This allows simple string mapping without custom theme JSON generation. For the 2 unmatched palettes (Rose Pine, Solarized), we'll use the "system" theme which auto-adapts to terminal colors.

**Alternatives Considered**:
1. **Generate custom theme JSON files** - More complex, requires maintaining color mappings and deploying additional files. Benefits don't justify the implementation overhead since "system" theme provides acceptable fallback.
2. **Map everything to "system"** - Simpler but loses the value of OpenCode's built-in themes. Users would not get the curated OpenCode theme experience for supported palettes.
3. **Create OpenCode adapter module** - Overkill for simple string mapping. Existing `appAdapters` pattern in palette files is sufficient.

### OpenCode Theme Configuration Format

**Location**: `~/.config/opencode/opencode.json`

**Schema**: Points to `https://opencode.ai/config.json`

**Theme Field**: Accepts either:
- Built-in theme name (string): `"catppuccin"`, `"gruvbox"`, `"kanagawa"`, `"nord"`, `"system"`, etc.
- Custom theme path (string): Path to custom theme JSON file

**Current State**: Hardcoded to `"system"` in `modules/home/configurations/llm/config/opencode.nix:17`

### Theme Name Mappings

| Our Palette | OpenCode Built-in | Mapping Strategy |
|-------------|-------------------|------------------|
| catppuccin  | `"catppuccin"`    | Direct match - use palette name |
| gruvbox     | `"gruvbox"`       | Direct match - use palette name |
| kanagawa    | `"kanagawa"`      | Direct match - use palette name |
| nord        | `"nord"`          | Direct match - use palette name |
| rose-pine   | N/A               | Fallback to `"system"` |
| solarized   | N/A               | Fallback to `"system"` |

**Implementation Pattern**:
```nix
# In palette files (e.g., catppuccin.nix)
appAdapters = {
  # ... existing adapters
  opencode = "catppuccin";  # Direct theme name
}

# For rose-pine.nix and solarized.nix
appAdapters = {
  # ... existing adapters
  opencode = "system";  # Fallback
}
```

### Variant Handling

**Observation**: OpenCode built-in theme names don't include variant suffixes (no `"gruvbox-light"` vs `"gruvbox-dark"`).

**Decision**: Ignore variant in OpenCode mapping. Use base palette name only.

**Rationale**:
- OpenCode's built-in themes likely handle variant detection internally (possibly via terminal background)
- Our system's variant granularity (e.g., Gruvbox `dark`/`light`) doesn't map cleanly to single OpenCode theme names
- Attempting to map variants would require research into OpenCode's theme implementations, which is out of scope
- Users can override to `"system"` theme if built-in theme doesn't match their variant preference

**Implementation**: Use simple string adapter (no function), ignoring variant parameter:
```nix
opencode = "gruvbox";  # Not `variant: "gruvbox-${variant}"`
```

## Existing Theme System Audit

### Current Architecture

**Theme Library**: `modules/lib/theme/default.nix`
- Exports: `getTheme`, `validateThemeConfig`, `getAppTheme`, `createAppConfig`, `generateAppJSON`
- Already supports 12 applications via `appAdapters` in palette files
- Uses `getAppTheme` function to resolve app-specific theme names

**Palette Structure**: Each palette file exports:
```nix
{
  meta = {
    name = "Display Name";
    id = "palette-id";
    variants = [ "variant1" "variant2" ];
    supports = [ "dark" "light" ];
    appearanceMapping = { light = "variant"; dark = "variant"; };
  };

  palettes = {
    variant1 = { /* color definitions */ };
    variant2 = { /* color definitions */ };
  };

  semanticMapping = palette: { /* semantic color roles */ };

  appAdapters = {
    wezterm = { variant = "Theme Name"; };
    neovim = { /* plugin config */ };
    bat = variant: "bat-theme-${variant}";
    # ... etc
  };
}
```

### Validation Status

**Existing Validations** (in `modules/lib/theme/default.nix`):
- ✅ Palette color definitions validated via `utils.validatePalette`
- ✅ Variant existence checked against `meta.variants`
- ✅ Appearance mode validated against `meta.supports`
- ✅ Theme configuration validated via `validateThemeConfig` function
- ✅ Build fails with clear errors on invalid palette/variant combinations

**Gap Analysis**: No systematic validation that all palettes define adapters for all applications.

**Decision**: Add validation script in `specs/003-theme-audit/validation-tests/theme-audit.sh` to iterate through all palette-app combinations and report missing adapters.

### Application Adapter Coverage

Current applications in theme system:
1. **wezterm** - Terminal emulator (primary)
2. **neovim** - Text editor
3. **bat** - Syntax-highlighted cat
4. **delta** - Git diff viewer
5. **atuin** - Shell history
6. **vivid** - LS_COLORS generator
7. **helix** - Alternative text editor
8. **nushell** - Alternative shell
9. **k9s** - Kubernetes CLI
10. **sketchybar** - macOS status bar (uses color values, not theme names)
11. **firefox** - Web browser (custom theme generation)
12. **opencode** - AI coding assistant (MISSING - being added)

**Finding**: All palettes except OpenCode have adapters for all applicable applications. Sketchybar uses raw color values instead of theme names, which is the correct approach for that application.

## Theme Testing Strategy

### Decision: Manual Validation with Scripted Audit

**Rationale**:
- Nix evaluation validates structure at build time (already implemented)
- Theme appearance requires visual verification across applications
- Automated testing would require:
  - Headless application launching
  - Screenshot comparison or color extraction
  - Complex test infrastructure
- ROI on automated theme testing is low for a personal dotfiles repo

**Implementation**:
1. **Build-time validation** (already exists): Nix evaluation catches structural errors
2. **Audit script** (`validation-tests/theme-audit.sh`): Reports missing adapters for each palette-app combination
3. **Manual testing checklist** (in `documentation/theme-support.md`): Step-by-step verification procedure for each palette
4. **Acceptance criteria**: User stories from spec define success (visual consistency across apps)

**Alternatives Considered**:
1. **Automated screenshot testing** - Too complex, brittle, requires additional dependencies
2. **Unit tests for Nix functions** - No standard Nix testing framework in use; build-time evaluation is sufficient
3. **CI/CD integration** - Personal repo, no CI configured, manual validation acceptable

## Best Practices for Theme System Extensions

### Pattern: Application Adapter Definition

**From existing implementations** (bat, delta, atuin, helix):

**Simple string template** (when theme name follows pattern):
```nix
appAdapters = {
  bat = variant: "palette-${variant}";
  delta = variant: "palette-${variant}";
}
```

**Variant-specific mapping** (when different themes per variant):
```nix
appAdapters = {
  wezterm = {
    macchiato = "Catppuccin Macchiato";
    latte = "Catppuccin Latte";
  };
}
```

**Plugin-based configuration** (for editors with plugin systems):
```nix
appAdapters = {
  neovim = {
    plugin = "catppuccin/nvim";
    name = "catppuccin";
    setup = "catppuccin";
    colorscheme = "catppuccin";
  };
}
```

**Color-based configuration** (for apps that need raw colors):
```nix
appAdapters = {
  sketchybar = {
    background = palettes.variant.base;
    foreground = palettes.variant.text;
    accent = palettes.variant.accent;
  };
}
```

**Decision for OpenCode**: Use simple string (no function) since theme name doesn't vary by variant:
```nix
appAdapters = {
  opencode = "catppuccin";  # or "system" for unsupported palettes
}
```

### Pattern: Consuming Theme in Application Config

**Standard approach** (from existing configs):
```nix
{ lib, values, ... }:
let
  themes = import ../../lib/theme { inherit lib; };
  validatedTheme = themes.validateThemeConfig values.theme;
  appTheme = themes.getAppTheme "app-name"
               validatedTheme.colorscheme
               validatedTheme.variant;
in
{
  # Use appTheme in configuration
  programs.app.theme = appTheme;
}
```

**Decision for OpenCode**: Apply same pattern to `modules/home/configurations/llm/config/opencode.nix`

## Documentation Requirements

### Decision: Create Theme Support Matrix

**Location**: `specs/003-theme-audit/documentation/theme-support.md`

**Content**:
1. **Compatibility table**: Which palettes work with which applications
2. **Manual testing procedure**: Step-by-step verification for each palette
3. **Known limitations**: Document where OpenCode built-in themes may not perfectly match variant expectations
4. **Fallback behavior**: Explain when and why "system" theme is used

**Rationale**:
- Users need clear expectations about theme support
- Future contributors need guidance on adding new palettes or applications
- Documents design decisions for maintenance

**Alternatives Considered**:
1. **Auto-generate from Nix metadata** - Would require additional tooling; manual documentation is sufficient for this scale
2. **Inline comments in palette files** - Less discoverable than dedicated documentation file
3. **README.md section** - Too detailed for main README; separate doc keeps it focused

## Summary

**Key Research Outcomes**:
1. OpenCode uses simple string theme names, 4/6 palettes have direct matches
2. No variant suffix in OpenCode theme names - use base palette name only
3. Existing theme system already has all necessary infrastructure (getAppTheme, validateThemeConfig)
4. Manual validation with scripted audit is appropriate testing strategy
5. Follow existing appAdapters patterns for consistency

**All Technical Context fields resolved** - no "NEEDS CLARIFICATION" items remain.

**Ready for Phase 1**: Design artifacts can now be created with full technical clarity.
