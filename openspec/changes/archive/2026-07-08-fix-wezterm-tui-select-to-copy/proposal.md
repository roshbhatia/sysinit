## Why

Running Claude Code with `tui = "fullscreen"` made WezTerm's select-to-copy
unreliable. Root cause (verified against both products' primary docs):

- The fullscreen TUI **captures mouse events** (SGR mouse reporting) — by design
  (`code.claude.com/docs/en/fullscreen`: "When Claude Code captures mouse
  events, your terminal's native copy-on-select stops working").
- WezTerm **forwards** plain (`NONE`-modifier) drags to any app that has mouse
  reporting enabled (`wezterm docs/config/mouse.md`). The documented escape
  hatch is `bypass_mouse_reporting_modifiers`, default `SHIFT` — so a Shift+drag
  bypasses the app and selects natively.
- Even when a native selection is made, WezTerm's **default** left-release action
  copies to `PrimarySelection`, not the macOS system **Clipboard** — so on macOS
  the selection frequently "doesn't copy" even when it visually worked.

The user wants to keep the fullscreen TUI (and Claude's mouse features:
click-to-expand, URL click, wheel scroll) AND have reliable select-to-copy.
The clean resolution lives entirely on the WezTerm end: make `Shift+drag`
select even under app mouse reporting, and complete the selection to the system
**Clipboard** (not just primary).

## What Changes

- In `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua`, set
  `config.bypass_mouse_reporting_modifiers = "SHIFT"` explicitly (documents the
  intent; it is already the default).
- Add three `SHIFT`-modified left-button mouse bindings (merged with WezTerm's
  defaults, which the existing config already relies on): `Down`, `Drag`, and
  `Up` → `SelectTextAtMouseCursor`, `ExtendSelectionToMouseCursor`, and
  `CompleteSelection "ClipboardAndPrimarySelection"`. Binding all three avoids
  the documented "Up-only" gotcha (a lone `Up` binding double-fires with the
  default `Down`).
- Keep the existing triple-click `SemanticZone` binding (`NONE`) unchanged.

### Non-goals

- **No change to Claude Code config.** `tui = "fullscreen"` stays; mouse capture
  is not disabled (`CLAUDE_CODE_DISABLE_MOUSE` is deliberately NOT set — it would
  cost wheel scroll / click-to-expand and hits open bug claude-code#70724).
- **No `tui = "classic"` revert.** Fullscreen's flicker-free rendering is kept.
- **No change to plain (no-modifier) drag.** Plain drag intentionally still
  goes to the TUI app so Claude's own click/scroll/expand keep working;
  selection is the `SHIFT`-modified gesture.
- No new WezTerm plugins; no global mouse-binding disable
  (`disable_default_mouse_bindings` does not exist in WezTerm — defaults are
  opt-out per-event via `DisableDefaultAssignment`, not needed here).

## Capabilities

### New Capabilities

- `wezterm-tui-select-to-copy`: declares that WezTerm provides a reliable
  Shift-modified select-to-copy gesture that bypasses in-app mouse reporting and
  lands the selection on the system clipboard, so text can be copied out of
  full-screen mouse-capturing TUIs (Claude Code fullscreen) without disabling
  the app's own mouse handling.
