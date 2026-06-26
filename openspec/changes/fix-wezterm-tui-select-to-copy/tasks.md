# Tasks

## 1. WezTerm Shift+drag select-to-clipboard

- [x] **Apply**: In `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`,
      set `config.bypass_mouse_reporting_modifiers = "SHIFT"` and extend
      `config.mouse_bindings` (which merges with WezTerm defaults) with three
      `SHIFT`+Left entries, keeping the existing triple-click `SemanticZone`
      binding:
      ```lua
      -- Shift+drag bypasses in-app mouse reporting (e.g. Claude Code fullscreen
      -- TUI) and copies to the system clipboard. Bind Down/Drag/Up together to
      -- avoid WezTerm's documented "Up-only" double-fire gotcha.
      { event = { Down = { streak = 1, button = "Left" } }, mods = "SHIFT",
        action = act.SelectTextAtMouseCursor("Cell") },
      { event = { Drag = { streak = 1, button = "Left" } }, mods = "SHIFT",
        action = act.ExtendSelectionToMouseCursor("Cell") },
      { event = { Up = { streak = 1, button = "Left" } }, mods = "SHIFT",
        action = act.CompleteSelection("ClipboardAndPrimarySelection") },
      ```
- [x] **Verify**: `nix flake check` passes; WezTerm reloads the config without
      Lua errors (`wezterm` logs clean on config reload).
- [ ] **Confirm**: With Claude Code in `tui = "fullscreen"`, `Shift`+drag selects
      and the text pastes from the macOS system clipboard (Cmd+V elsewhere);
      plain drag still drives Claude's click-to-expand / scroll; triple-click
      semantic-zone selection still works.

## 2. Documentation note (optional)

- [x] **Apply**: Add a short comment in `keybindings.lua` recording that plain
      drag is intentionally forwarded to mouse-capturing TUIs and `SHIFT`+drag is
      the select-to-copy gesture, citing the WezTerm `bypass_mouse_reporting_modifiers`
      default and the Claude fullscreen mouse-capture behavior.
- [x] **Confirm**: Comment is present and accurate; no behavioral change.
