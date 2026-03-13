## Context

Maintaining custom themes requires manual updates to multiple files (YAML, Nix palette, Wezterm Lua) and often breaks when plugins expect standard naming conventions. Switching to a standard Base16 theme like `windows-95-light` allows us to leverage existing ecosystem support.

## Goals / Non-Goals

**Goals:**
- **Zero Maintenance**: Use upstream Base16 definitions.
- **Perfect Parity**: Ensure Stylix and Wezterm use the exact same color values.
- **Code Deletion**: Remove redundant custom theme logic.

## Decisions

### 1. The `windows-95` Theme Identifier
**Decision**: Use `windows-95` as our internal theme key.
**Rationale**: It is the standard name in the `base16-schemes` repository.

### 2. Wezterm Built-in Name
**Decision**: Map the `light` variant of `windows-95` to `"Windows 95 Light (base16)"` in Wezterm.
**Rationale**: This matches Wezterm's internal registry, allowing us to delete the manually generated `colors/classic-platinum-light.lua`.

### 3. Base16 Mapping
**Decision**: Point to `${pkgs.base16-schemes}/share/themes/windows-95-light.yaml`.

## Risks / Trade-offs

- **[Risk]**: Upstream `windows-95` might differ slightly from our `classic-platinum`.
- **[Mitigation]**: We've verified they use the same core hex codes (#C0C0C0, #000080).
