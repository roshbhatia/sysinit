# Feature Specification: Theme Configuration Propagation

**Feature Branch**: `002-theme-config-propagation`
**Created**: 2025-11-04
**Status**: Draft
**Input**: User description: "make sure our theme config propagation works as expected. i should be able to specify light or dark for the os, and the palette like we do now, as well as the system font i.e. tx-02 or something else and switch it on the fly and have it propagate down. make sure that it is robust and works properly and is stable and doesn't break"

## Clarifications

### Session 2025-11-04

- Q: How should applications be notified when theme configuration changes? → A: Through Nix rebuild/activation - no hot-reloading needed, theme changes apply on next system activation
- Q: What should be the fallback font for nerd font glyphs? → A: Symbols Nerd Font
- Q: When a palette lacks the requested variant (light/dark), what should happen? → A: Build fails with clear error message requiring user to choose different palette or mode
- Q: Which monospace font should be the default fallback when specified font is unavailable? → A: JetBrainsMono Nerd Font
- Q: Which applications must have theme propagation support? → A: Terminal, Neovim, Firefox, Wezterm
- Q: What information should validation error messages include? → A: Invalid value and field name

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Switch Light/Dark Mode (Priority: P1)

As a system user, I want to switch between light and dark appearance modes so that I can work comfortably in different lighting conditions and match my personal preference.

**Why this priority**: Appearance mode switching is fundamental to user comfort and is the most commonly changed theme setting. This affects all applications and must work reliably.

**Independent Test**: Can be fully tested by changing the appearance mode setting, running system rebuild/activation, and verifying all applications reflect the change.

**Acceptance Scenarios**:

1. **Given** the system is set to light mode, **When** I change the setting to dark mode, **Then** all configured applications update to display dark appearance
2. **Given** the system is set to dark mode, **When** I change the setting to light mode, **Then** all configured applications update to display light appearance
3. **Given** I have multiple applications open, **When** I switch appearance mode and rebuild the system, **Then** all applications reflect the new mode after restart/relaunch

---

### User Story 2 - Change Color Palette (Priority: P2)

As a system user, I want to switch between different color palettes (e.g., Catppuccin, Kanagawa, Rose Pine) so that I can customize the visual aesthetic of my system to my preference.

**Why this priority**: Palette selection is important for personalization but less critical than light/dark mode. Users change this less frequently but expect it to work reliably when they do.

**Independent Test**: Can be fully tested by changing the palette setting and verifying all applications adopt the new color scheme consistently.

**Acceptance Scenarios**:

1. **Given** the system is using one palette, **When** I change to a different palette, **Then** all configured applications update to use the new palette's colors
2. **Given** I am in dark mode with palette A, **When** I switch to palette B, **Then** the dark variant of palette B is applied across all applications
3. **Given** I change palette settings, **When** I open a new application, **Then** it uses the currently configured palette

---

### User Story 3 - Change System Font (Priority: P3)

As a system user, I want to switch between different system fonts (e.g., TX-02 or other monospace fonts) so that I can optimize readability and match my coding/terminal preferences.

**Why this priority**: Font selection is important for daily usability but affects fewer applications than appearance mode or palette. Users typically set this once and rarely change it.

**Independent Test**: Can be fully tested by changing the font setting and verifying terminal, editor, and other text-heavy applications reflect the new font choice.

**Acceptance Scenarios**:

1. **Given** the system is using one font, **When** I change to a different system font, **Then** all text-based applications (terminal, editor) update to use the new font
2. **Given** I change the system font, **When** I open a new terminal or editor instance, **Then** it uses the newly configured font
3. **Given** I switch fonts, **When** the font is not available, **Then** the system falls back to JetBrainsMono Nerd Font

---

### Edge Cases

- **Missing palette variant**: When a palette doesn't have the requested light or dark variant defined, the build MUST fail with a clear error message indicating which palette and variant combination is invalid, requiring the user to select a different palette or appearance mode
- **Invalid font**: When a font specified in the configuration is not installed, the system MUST fall back to JetBrainsMono Nerd Font (which provides both text and glyph support with Symbols Nerd Font as secondary fallback for glyphs)
- **Malformed configuration**: When configuration files contain invalid values, the Nix build MUST fail at evaluation time with error messages showing the invalid value and field name
- **Incomplete theme support**: Applications that don't support theming will use their default appearance (documented limitation)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to specify appearance mode (light or dark) through configuration
- **FR-002**: System MUST allow users to specify color palette through configuration (supporting existing palettes: Catppuccin, Kanagawa, Rose Pine, Gruvbox, Solarized, Nord)
- **FR-003**: System MUST allow users to specify system font through configuration
- **FR-003a**: System MUST use JetBrainsMono Nerd Font as default fallback when specified font is unavailable
- **FR-003b**: System MUST use Symbols Nerd Font as secondary fallback for nerd font glyphs when primary font doesn't support them
- **FR-004**: System MUST propagate theme configuration changes to all configured applications through Nix rebuild/activation process
- **FR-005**: System MUST apply theme changes consistently across all applications after rebuild/activation
- **FR-006**: System MUST maintain theme consistency across all configured applications: Wezterm (terminal), Neovim (editor), Firefox (browser), and shell integrations
- **FR-007**: System MUST validate theme configuration values at build time to catch errors early
- **FR-007a**: System MUST fail the build with a clear error message when selected palette lacks the requested appearance mode variant
- **FR-007b**: System MUST provide error messages that include the invalid value and field name for failed validations
- **FR-008**: System MUST provide sensible fallback behavior when theme values are invalid or missing
- **FR-009**: System MUST preserve user's theme settings across system restarts
- **FR-010**: System MUST handle multiple theme configuration changes in values.nix without breaking the build process
- **FR-011**: System MUST ensure theme changes are atomic through Nix's generation-based activation - either fully applied or rollback to previous generation
- **FR-012**: System MUST generate correct theme configuration files for all applications during build phase

### Key Entities

- **Theme Configuration**: Central configuration containing appearance mode (light/dark), color palette name, and system font name
- **Appearance Mode**: Light or dark variant selection that affects color brightness and contrast
- **Color Palette**: Named collection of colors that defines the visual aesthetic (e.g., Catppuccin, Kanagawa)
- **System Font**: Font family used for monospace text in terminal and editor applications
- **Application Adapter**: Mapping between theme configuration and application-specific format requirements
- **Themed Applications**: Core applications requiring theme support - Wezterm, Neovim, Firefox, and shell integrations

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can change appearance mode, rebuild the system, and see updates reflected correctly in all applications after relaunch
- **SC-002**: Users can switch between any supported color palette and see consistent colors across Wezterm, Neovim, Firefox, and shell after rebuild
- **SC-003**: Users can change system font and see the update in terminal and editor after rebuild
- **SC-004**: Zero configuration-related crashes or errors when switching between valid theme settings
- **SC-005**: 100% of theme changes are applied atomically - no applications show mixed old/new theme state
- **SC-006**: Theme configuration errors are detected at validation time, not at runtime
- **SC-007**: System successfully builds and activates after multiple theme configuration changes without errors
- **SC-008**: Theme settings persist across system restarts with 100% accuracy

## Assumptions

- Users will primarily use the existing palette options (Catppuccin, Kanagawa, Rose Pine, Gruvbox, Solarized, Nord)
- System font refers to monospace fonts used in terminal and code editor contexts
- Theme changes apply through Nix rebuild/activation (task nix:refresh), not live hot-reloading
- Core applications (Wezterm, Neovim, Firefox, shell) are already configured to support theming through the existing theme system
- The theme system uses the existing modular structure (`modules/lib/theme/`)
- Invalid configuration values should fail fast at Nix build time
- Applications will use updated theme configuration after system rebuild and application restart/relaunch
- JetBrainsMono Nerd Font is the default fallback when specified fonts are unavailable
- Symbols Nerd Font provides secondary fallback for nerd font glyphs

## Out of Scope

- Adding new color palettes (focus is on propagation of existing palettes)
- Creating new theme system architecture (working with existing system)
- Theme configuration through GUI (command-line/file-based configuration only)
- Per-application theme overrides (system-wide consistency is the goal)
- Dynamic font size adjustment (only font family selection in scope)
- Supporting non-monospace fonts for terminal/editor contexts
