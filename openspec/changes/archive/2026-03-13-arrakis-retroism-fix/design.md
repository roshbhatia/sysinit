## Context

The "Retroism" overhaul on `arrakis` was incomplete at the integration layer. Wezterm is failing because its theme mapping is missing the standard ANSI/Brights color arrays required by the terminal. The Waybar menu bar is missing because `mango-session.target` never reaches an active state, and Waybar itself isn't configured to claim exclusive space on the screen.

## Goals / Non-Goals

**Goals:**
- **Crash-Free Terminal**: Ensure Wezterm launches without Lua errors.
- **Reliable GUI Startup**: Guarantee the bar and notifications start automatically on login.
- **Exclusive Bar Space**: Force the bar to be visible and occupy dedicated screen real estate.
- **System-Wide Bitmap Feel**: Deploy `Terminus` across the OS and applications.

**Non-Goals:**
- **Redesigning the Palette**: We will keep the `classic-platinum` colors but fix their mapping.

## Decisions

### 1. ANSI Mapping for Wezterm
**Decision**: Update the Wezterm theme adapter to fill in the `ansi` and `brights` keys using the existing Base16 slots (00-07 and 08-15 respectively).
**Rationale**: Wezterm's internal theme logic depends on these fields being present when a custom color scheme is applied.

### 2. Wrapper-Led Session Activation
**Decision**: Modify `mango-wrapped` to execute `systemctl --user start mango-session.target` after the environment variables are exported.
**Rationale**: This creates a clean chain of causality: Greetd -> Wrapper -> Env Export -> Target Activation -> Service Startup (Waybar/Mako).

### 3. Waybar Exclusive Mode
**Decision**: Set `exclusive: true` and `layer: top` in the Waybar configuration.
**Rationale**: This tells the compositor (`mangowc`) to reserve space for the bar and ensures windows tile below it rather than covering it.

### 4. Bitmap Font Enforcements
**Decision**: Use `terminus_font` in the NixOS host configuration and specifically `Terminus (Nerd Font)` for applications requiring icons.
**Rationale**: Standard Terminus is a bitmap font; the Nerd Font version provides the modern glyphs needed for the bar while preserving the 90s pixel look.

## Risks / Trade-offs

- **[Risk]**: Bitmap fonts may not scale well on high-DPI displays.
- **[Mitigation]**: We will target standard sizes (12px/14px) where Terminus is known to be pixel-perfect.
- **[Risk]**: Redundant session starts if the user manually re-runs the wrapper.
- **[Mitigation]**: Systemd targets are idempotent; re-starting an active target has no ill effect.
