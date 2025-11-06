# Research: Theme Configuration Propagation

**Feature**: `002-theme-config-propagation`
**Date**: 2025-11-04
**Status**: Complete

## Overview

This document captures research findings for implementing robust theme configuration propagation across the sysinit Nix-based system configuration. The feature ensures appearance mode (light/dark), color palette, and font settings propagate correctly to all configured applications.

## Research Areas

### 1. Light/Dark Mode Implementation in Nix Theme System

**Decision**: Add `appearance` field to theme configuration alongside existing `colorscheme` and `variant`

**Rationale**:
- Current system uses `variant` (e.g., "macchiato", "mocha") which is palette-specific, not a universal light/dark selector
- Need a separate `appearance` field that maps to palette-specific variants
- Example: `appearance = "dark"` + `colorscheme = "catppuccin"` → uses "macchiato" or "mocha" variant
- Example: `appearance = "light"` + `colorscheme = "catppuccin"` → uses "latte" variant

**Implementation Approach**:
- Add `theme.appearance` option to `modules/lib/values/default.nix` (enum: "light" | "dark")
- Update palette definitions to include `variantMapping` that maps appearance modes to specific variants
- Modify `validateThemeConfig` to check that selected palette has the requested appearance mode
- Build fails with clear error if palette lacks light/dark variant

**Alternatives Considered**:
- Using `variant` directly → Rejected because variant names are palette-specific ("macchiato" vs "storm" vs "dawn")
- Auto-detecting from variant name → Rejected because not all palettes follow predictable naming

**Best Practices**:
- Make appearance mode explicit in user configuration
- Validate at build time, not runtime
- Provide clear error messages showing available options
- Document variant mappings in each palette definition

### 2. Font Configuration and Propagation

**Decision**: Add `theme.font.monospace` field with validation and fallback chain

**Rationale**:
- System font primarily affects monospace contexts (terminal, editor)
- Need to validate font availability at build time where possible
- Provide sensible fallback chain: User Font → JetBrainsMono Nerd Font → Symbols Nerd Font (for glyphs)
- Font configuration should be part of theme system since it affects visual consistency

**Implementation Approach**:
- Add `theme.font.monospace` option to values schema (default: "JetBrainsMono Nerd Font")
- Add `theme.font.nerdfontFallback` option (default: "Symbols Nerd Font")
- Update application adapters (wezterm, neovim) to use font configuration
- Generate font configuration in theme JSON files
- Font validation happens at application level (runtime), not Nix build time

**Alternatives Considered**:
- Separate `fonts` top-level config → Rejected because fonts are part of visual theme
- No fallback mechanism → Rejected because missing fonts cause poor UX
- Build-time font validation → Rejected because fonts may be installed outside Nix

**Best Practices**:
- Always specify Nerd Font variants for glyph support
- Document font requirements in README
- Provide fallback chain in all application configurations
- Make font changes apply through same rebuild process as colors

### 3. Palette Light/Dark Variant Support

**Decision**: Audit and update all palette definitions to explicitly declare light/dark support

**Rationale**:
- Current palettes may only define dark variants
- Need to identify which palettes support light mode
- Build must fail clearly when user requests unsupported combination
- Some palettes may need light variants added

**Current Palette Status** (from existing codebase inspection):
- **Catppuccin**: Supports dark (macchiato, mocha, frappe) and light (latte)
- **Kanagawa**: Needs investigation - appears dark-only currently
- **Rose Pine**: Supports dark (main, moon) and light (dawn)
- **Gruvbox**: Traditionally supports both light and dark
- **Solarized**: Explicitly designed for both light and dark
- **Nord**: Primarily dark, light variant may need addition

**Implementation Approach**:
- Add `appearanceMapping` to each palette's meta section:
  ```nix
  appearanceMapping = {
    light = "latte";    # or null if not supported
    dark = "macchiato"; # or list of variants
  };
  ```
- Update `validateThemeConfig` to check appearance compatibility
- Fail build with message: "Palette 'nord' does not support light mode. Supported modes: dark"

**Alternatives Considered**:
- Silently falling back to dark mode → Rejected because it hides user intent
- Auto-generating light variants → Rejected because requires color theory expertise
- Allowing any variant regardless of appearance → Rejected because breaks user expectations

**Best Practices**:
- Document which palettes support light/dark in README
- Provide clear error messages with available options
- Consider community palette contributions for missing variants
- Maintain backward compatibility with existing `variant` usage

### 4. Application Adapter Validation

**Decision**: Ensure all application adapters (wezterm, neovim, firefox) properly propagate theme changes

**Rationale**:
- Theme changes should propagate atomically to all applications
- Each adapter must handle appearance mode, palette, and font
- Adapters generate app-specific config files from theme configuration
- Need to verify current adapters handle all theme aspects

**Implementation Approach**:
- Audit existing adapters for theme propagation completeness:
  - `modules/lib/theme/adapters/wezterm.nix` - terminal colors and font
  - `modules/lib/theme/adapters/neovim.nix` - editor colors and font
  - `modules/lib/theme/adapters/firefox.nix` - browser theme
- Add font configuration to wezterm and neovim adapters
- Ensure Firefox adapter uses correct light/dark variant
- Update JSON generation functions to include all theme properties
- Test that `task nix:refresh` correctly rebuilds with new theme

**Verification Points**:
1. Wezterm: Colors, font, transparency all update
2. Neovim: Colorscheme, font, background (light/dark) all update
3. Firefox: Theme colors update, userChrome.css if applicable
4. Shell (zsh/nu): Prompt colors update

**Alternatives Considered**:
- Hot-reloading theme changes → Out of scope, requires application support
- Per-app theme overrides → Out of scope per spec
- Real-time validation → Using build-time validation instead

**Best Practices**:
- Generate minimal config files (only theme-related settings)
- Use Nix string interpolation for clean JSON generation
- Document which app settings are theme-managed
- Preserve non-theme user customizations

### 5. Build-Time Validation Strategy

**Decision**: Implement comprehensive validation at Nix evaluation time with clear error messages

**Rationale**:
- Failing fast at build time prevents broken configurations
- Users get immediate feedback before system changes
- Atomic activation ensures all-or-nothing updates
- Clear errors reduce troubleshooting time

**Implementation Approach**:
- Add validators to `modules/lib/validation/default.nix`:
  - `validateAppearanceMode`: Check "light" | "dark"
  - `validatePaletteAppearance`: Check palette supports requested mode
  - `validateFont`: Basic string validation (runtime handles availability)
- Update `validateThemeConfig` in theme/default.nix to call validators
- Use Nix `throw` with descriptive error messages:
  ```nix
  throw ''
    Theme validation failed: Palette 'nord' does not support appearance mode 'light'.

    Available appearance modes for 'nord': dark
    Supported palettes for 'light' mode: catppuccin, rose-pine, gruvbox, solarized

    Please either:
    1. Change appearance to 'dark', or
    2. Change colorscheme to a light-mode compatible palette
  ''
  ```

**Error Message Format**:
- What went wrong (invalid value + field name)
- Why it's invalid
- Available valid options
- Suggested fixes

**Alternatives Considered**:
- Runtime validation → Too late, system already activated
- Warning instead of error → User might not notice, system breaks
- Minimal error messages → Poor developer experience

**Best Practices**:
- Validate early in evaluation
- Provide actionable error messages
- List available options in errors
- Test error paths as thoroughly as success paths

## Technology Stack Confirmation

- **Language**: Nix (declarative configuration)
- **Framework**: nix-darwin + home-manager
- **Theme System**: Custom Nix modules in `modules/lib/theme/`
- **Applications**: Wezterm, Neovim, Firefox, Zsh/Nu shell
- **Validation**: Nix type system + custom validators
- **Testing**: Manual integration testing + Nix build validation

## Open Questions Resolved

All questions from spec clarification session have been addressed:
- ✅ Notification mechanism: Nix rebuild/activation (no hot-reload)
- ✅ Fallback font for glyphs: Symbols Nerd Font
- ✅ Missing palette variant: Build fails with clear error
- ✅ Default monospace font: JetBrainsMono Nerd Font
- ✅ Application support: Wezterm, Neovim, Firefox, shell
- ✅ Error message content: Invalid value + field name + available options

## Next Steps

Proceed to Phase 1:
1. Generate data-model.md (theme configuration entities)
2. Generate contracts/ (if applicable - N/A for Nix config)
3. Generate quickstart.md (testing scenarios)
4. Update agent context with Nix technology
