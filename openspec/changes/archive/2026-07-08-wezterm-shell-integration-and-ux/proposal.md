## Why

WezTerm has several UX features that require shell-side cooperation (OSC 133 prompt markers) or small Lua additions (tab titles, quick-select patterns, hyperlink rules) that are currently absent from the setup. Adding them makes navigation faster, tab identification instant, and text extraction more precise.

## What Changes

- Source `wezterm.sh` shell integration in zsh so WezTerm receives OSC 133 semantic prompt markers
- Add `CTRL+SHIFT+↑/↓` keybindings to jump between shell prompts in scrollback
- Add a `format-tab-title` event handler that shows `cwd (process)` instead of a raw index
- Extend `quick_select_patterns` with Nix store hashes, git SHAs, UUIDs, and file paths
- Add custom hyperlink rules for GitHub issue/PR refs (`#123`) and Nix store paths

## Capabilities

### New Capabilities

- `shell-integration`: OSC 133 prompt markers via `wezterm.sh` sourced in zsh, enabling semantic zone selection and prompt-jump keybindings
- `smart-tab-titles`: `format-tab-title` handler that displays current working directory and foreground process name
- `quick-select-extensions`: Additional regex patterns for Nix hashes, git SHAs, UUIDs, and file paths
- `custom-hyperlinks`: Additional hyperlink rules for GitHub refs and Nix store paths

### Modified Capabilities

## Impact

- `modules/home/programs/zsh/` — source `wezterm.sh` when `$TERM_PROGRAM == WezTerm`
- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua` — prompt-jump bindings
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` — tab title handler, quick-select patterns, hyperlink rules
