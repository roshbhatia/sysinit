## Context

The `arrakis` host is the target for a 90s retro aesthetic. Current blockers are a Wezterm crash when indexing the `ansi` field of a custom theme and a Waybar configuration error regarding workspace arguments. 

## Goals / Non-Goals

**Goals:**
- **Authentic 90s Feel**: Use Fixedsys and bevelled borders.
- **Stable Wezterm**: Fix the "nil field ansi" error by correctly registering the theme.
- **Working Bar**: Fix the Waybar workspace module.

## Decisions

### 1. Fixedsys Excelsior
**Decision**: Use the `fixedsys-excelsior` package.
**Rationale**: It is the most accurate representation of the classic DOS/Windows font while supporting modern unicode and scaling.

### 2. Wezterm Theme Registration
**Decision**: In `wezterm.lua`, use `config.color_schemes = { [name] = require("colors." .. name) }`.
**Rationale**: This adds the custom theme to Wezterm's internal memory, making it available to plugins that use `wezterm.get_builtin_color_schemes()`.

### 3. Waybar Workspace Correction
**Decision**: Change `custom/workspaces` to a simple set of labels or use the `wlr/workspaces` module correctly. 
**Rationale**: The previous configuration used `{name}` in a `custom` module without a script, which is invalid.

### 4. Bevelled CSS
**Decision**: Use a 2px border with contrasting colors (light top/left, dark bottom/right) to simulate the classic 3D bevel effect.

## Risks / Trade-offs

- **[Risk]**: `fixedsys-excelsior` might need exact integer scaling to look good.
- **[Mitigation]**: We will test at 12px and 16px.
