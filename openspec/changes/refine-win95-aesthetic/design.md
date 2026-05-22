## Context

The arrakis host is running a Windows 95 aesthetic. Issues include a crashing Wezterm (nil field 'ansi'), a failing Neovim config clone, and unpolished UI elements. We will switch to the dark variant of the windows-95 theme and polish the UI components.

## Goals / Non-Goals

**Goals:**
- Switch to windows-95 DARK theme.
- Fix Neovim config loading.
- Clean up Wezterm UI (padding, frame).

## Decisions

### 1. Repository Access via HTTPS
**Decision**: Switch nvimConfigRepo to 'https://github.com/roshbhatia/sysinit.nvim.git'.
**Rationale**: The repository is public, so using HTTPS avoids the need for SSH keys on arrakis.

### 2. Wezterm Color Palette Injection
**Decision**: Pass 'config.lib.stylix.colors' into 'config.json' for Wezterm.
**Rationale**: This allows Lua to access the actual hex codes of the current theme for pixel-perfect UI styling (e.g., custom tab bar colors).

### 3. Integrated Buttons and Clean Frame
**Decision**: Use 'INTEGRATED_BUTTONS|RESIZE' for 'window_decorations' on macOS and 'RESIZE' on Linux with custom tab bar styling.
**Rationale**: Makes the window look more cohesive and modern while maintaining the retro spirit.

## Risks / Trade-offs

- **[Risk]**: Dark mode might not look as authentic to Windows 95 as light mode.
- **[Mitigation]**: We will use the official Base16 'windows-95' dark scheme which is well-balanced.
