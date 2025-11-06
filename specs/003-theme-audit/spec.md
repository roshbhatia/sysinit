# Feature Specification: Theme Configuration Audit & OpenCode Integration

**Feature Branch**: `003-theme-audit`
**Created**: 2025-11-06
**Status**: Draft
**Input**: User description: "ensure we also set the opencode theme properly. you WILL do research around what themes are currently offered. also we need to fundamentally audit the theming config so that everything WORKS AS EXPECTED. that all the themes are PROPERLY configured. PREOPER PROPER"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - OpenCode Reflects System Theme (Priority: P1)

As a developer using OpenCode, I want the application theme to automatically match my system theme settings so that I have a consistent visual experience across all my development tools.

**Why this priority**: OpenCode is a core development tool. Theme inconsistency breaks user experience and causes visual discomfort when switching between applications.

**Independent Test**: Can be fully tested by changing system appearance/palette settings, rebuilding the system, and verifying OpenCode displays the correct theme.

**Acceptance Scenarios**:

1. **Given** the system is set to dark mode with Catppuccin palette, **When** I launch OpenCode, **Then** OpenCode displays with dark Catppuccin theme
2. **Given** the system is set to light mode with Gruvbox palette, **When** I launch OpenCode, **Then** OpenCode displays with light Gruvbox theme
3. **Given** I change from dark to light appearance mode, **When** I rebuild and restart OpenCode, **Then** OpenCode switches from dark to light theme variant

---

### User Story 2 - All Themes Work Across All Applications (Priority: P1)

As a system user, I want all configured themes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) to work correctly across all applications so that I can trust my theme selections will apply consistently system-wide.

**Why this priority**: This is a correctness issue. Users expect theme settings to work reliably. Broken theme configurations undermine trust in the system.

**Independent Test**: Can be tested by systematically switching through each theme palette and variant combination, verifying each application renders correctly with expected colors.

**Acceptance Scenarios**:

1. **Given** I select any supported palette (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord), **When** I rebuild the system, **Then** all configured applications (Wezterm, Neovim, Firefox, OpenCode, bat, delta, atuin, helix) apply the theme correctly
2. **Given** I select a dark variant for any palette, **When** I open each configured application, **Then** each displays with the correct dark colors from that palette
3. **Given** I select a light variant for a palette that supports it, **When** I open each configured application, **Then** each displays with the correct light colors
4. **Given** a palette only supports specific variants, **When** I try to use an unsupported variant, **Then** the build fails with a clear error message indicating which palette-variant combination is invalid

---

### User Story 3 - Theme Configuration Validation (Priority: P2)

As a system administrator, I want comprehensive validation of theme configurations during the build process so that I catch theme configuration errors before they affect my running system.

**Why this priority**: Early error detection prevents runtime issues and user frustration. Build-time validation is cheaper than runtime debugging.

**Independent Test**: Can be tested by intentionally creating invalid configurations (missing themes, invalid variants, malformed settings) and verifying build failures with helpful error messages.

**Acceptance Scenarios**:

1. **Given** I specify an invalid theme palette name, **When** the Nix build runs, **Then** it fails with an error message listing available themes
2. **Given** I specify a variant that doesn't exist for the selected palette, **When** the Nix build runs, **Then** it fails with an error message showing valid variants for that palette
3. **Given** I specify a palette-variant combination where the palette lacks that variant, **When** the Nix build runs, **Then** it fails with a clear message indicating which specific combination is invalid
4. **Given** theme configuration files have structural errors, **When** the build runs, **Then** it fails at evaluation time with messages showing the location and nature of the error

---

### Edge Cases

- **OpenCode theme format differences**: OpenCode may use different theme names/formats than other applications - system MUST map from unified theme config to OpenCode-specific theme identifiers
- **Missing theme adapters**: Some applications may not have theme adapters for all palettes - system MUST either provide generic fallback or fail build with clear message about missing support
- **Theme variant mismatches**: When appearance mode is "light" but palette only has "dark" variants (or vice versa), build MUST fail with actionable error message
- **Incomplete palette definitions**: When a palette file is missing required color definitions, validation MUST catch this during build and report which colors are missing
- **Application-specific theme limitations**: Some applications may not support all features of a theme (e.g., transparency, blur) - system MUST document these limitations and apply best-effort theming

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST configure OpenCode theme to match system appearance mode and color palette settings
- **FR-001a**: System MUST map unified theme configuration to OpenCode's theme format/naming conventions
- **FR-002**: System MUST validate that all defined palettes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) have complete color definitions for their advertised variants
- **FR-002a**: System MUST validate that each palette file defines all required colors for theme rendering
- **FR-003**: System MUST verify that each application adapter (wezterm, neovim, firefox, opencode, bat, delta, atuin, helix, vivid, k9s, sketchybar) correctly maps theme configurations
- **FR-003a**: System MUST test that each adapter produces valid output for all supported palette-variant combinations
- **FR-004**: System MUST validate appearance mode mappings for each palette, ensuring "light" and "dark" modes map to valid variants
- **FR-005**: System MUST fail the build with clear error messages when theme configuration is invalid or incomplete
- **FR-005a**: Error messages MUST identify the specific palette, variant, application, or configuration field that failed validation
- **FR-006**: System MUST document which palette-variant combinations are supported for each application
- **FR-007**: System MUST ensure theme configuration changes apply to OpenCode through the same rebuild/activation process as other applications
- **FR-008**: System MUST generate correct theme configuration files for OpenCode in the expected format and location
- **FR-009**: System MUST handle theme propagation consistently for applications with different configuration formats (JSON, TOML, Lua, etc.)
- **FR-010**: System MUST verify that semantic color mappings (primary, secondary, accent, error, warning, success, info) are correctly defined for all palettes
- **FR-011**: System MUST validate font configuration is correctly propagated to applications that support custom fonts

### Key Entities

- **OpenCode Theme Configuration**: JSON configuration file mapping system theme settings to OpenCode's theme format
- **Theme Palette**: Collection of color definitions with metadata about supported variants and appearance modes
- **Application Adapter**: Module that translates unified theme configuration into application-specific format
- **Theme Validator**: Build-time validation logic that ensures theme configurations are complete and correct
- **Semantic Color Mapping**: Translation layer from palette-specific color names to semantic roles (error, success, etc.)

### Assumptions *(mandatory)*

- OpenCode respects the "theme" field in its configuration file (opencode.json)
- OpenCode theme names follow a predictable pattern or have documented theme identifiers
- All currently defined palettes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) should remain functional
- Theme validation failures should prevent system deployment (fail-fast at build time)
- The existing theme system architecture (modules/lib/theme) provides the extension points needed for adding OpenCode support

### Dependencies *(mandatory)*

- **Existing theme infrastructure**: modules/lib/theme/default.nix provides getTheme, validateThemeConfig, createAppConfig, and generateAppJSON functions
- **Palette definitions**: modules/lib/theme/palettes/*.nix define color schemes and application adapters
- **Home Manager**: Required for deploying OpenCode configuration files to user's XDG config directory
- **OpenCode installation**: OpenCode must be installed and enabled (values.llm.opencode.enabled)
- **Nix build system**: Theme validation and configuration generation occurs during Nix evaluation/build phase

## Success Criteria *(mandatory)*

- Users can change system theme settings and see the change reflected in OpenCode after rebuild/activation
- All six supported palettes (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord) correctly theme all configured applications
- Invalid theme configurations are caught at build time with error messages that clearly explain what's wrong and how to fix it
- Zero theme-related runtime errors or mismatches between application appearances
- Theme configuration changes complete within 30 seconds (Nix rebuild time, not including compilation)
- Users can trust that selecting any supported palette-variant combination will either work correctly across all applications or fail the build with a clear explanation
- Documentation clearly identifies which palette-variant-application combinations are supported

## Out of Scope *(optional)*

- Adding new theme palettes beyond the six currently defined (Catppuccin, Rose Pine, Gruvbox, Solarized, Kanagawa, Nord)
- Hot-reloading theme changes without system rebuild/activation
- Per-application theme overrides (all applications must use the same system theme)
- Creating custom color schemes through configuration
- Theme preview functionality before applying changes
- Automatic theme switching based on time of day or ambient light
- Support for applications not currently in the configuration (only focusing on: Wezterm, Neovim, Firefox, OpenCode, bat, delta, atuin, helix, vivid, k9s, sketchybar, nushell)
- Migration tools for users with custom theme configurations outside the standard system

## Constraints *(optional)*

- Must maintain backward compatibility with existing theme configuration structure in values.nix
- Theme validation must complete during Nix evaluation phase (before any builds start)
- Cannot require external services or network access for theme configuration
- Must work within Home Manager's file deployment constraints
- OpenCode configuration must follow OpenCode's documented configuration schema
- Error messages must be suitable for display in terminal output during Nix builds
- Must not introduce new dependencies beyond what's already in the system

## Open Questions *(optional)*

None - all critical questions have been resolved through codebase research:
- OpenCode configuration location: ~/.config/opencode/opencode.json
- OpenCode theme field: Uses "theme" property in JSON config (currently hardcoded to "system")
- Available themes: System has 6 palettes with variants listed in meta.variants
- Theme validation: Already implemented via validateThemeConfig in modules/lib/theme/default.nix
