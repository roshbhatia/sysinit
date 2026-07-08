## 1. Shell Integration (zsh)

- [x] 1.1 Check whether oh-my-posh already emits OSC 133 markers (if so, skip sourcing `wezterm.sh`)
- [x] 1.2 Add `wezterm shell-integration` source block to zsh `initContent`, guarded by `$TERM_PROGRAM == "WezTerm"`

## 2. Prompt-Jump Keybindings

- [x] 2.1 Add `CTRL+SHIFT+Up` → `ScrollToPrompt(-1)` binding in `get_scroll_keys()` with locked-mode passthrough
- [x] 2.2 Add `CTRL+SHIFT+Down` → `ScrollToPrompt(1)` binding in `get_scroll_keys()` with locked-mode passthrough

## 3. Smart Tab Titles

- [x] 3.1 Register `wezterm.on("format-tab-title", ...)` handler in `ui.lua`
- [x] 3.2 Handler reads `pane:get_current_working_dir()` and `pane:get_foreground_process_name()`, builds `<dir> (<process>)` string
- [x] 3.3 Skip process name when it is the shell itself (`zsh`, `bash`, `fish`)
- [x] 3.4 Respect user-set titles: check `tab:get_title()` and only override when it matches the default WezTerm-generated title pattern

## 4. Quick-Select Extensions

- [x] 4.1 Add full Nix store path pattern to `config.quick_select_patterns`: `/nix/store/[a-z0-9]{32}[a-zA-Z0-9._+-]*`
- [x] 4.2 Add 40-char git SHA pattern: `\b[0-9a-f]{40}\b`
- [x] 4.3 Add 7-char git SHA pattern: `\b[0-9a-f]{7}\b`
- [x] 4.4 Add UUID pattern: `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`
- [x] 4.5 Add absolute path pattern: `/[^\s]+`

## 5. Custom Hyperlink Rules

- [x] 5.1 Add Nix store path hyperlink rule using `file://` URI scheme
- [x] 5.2 Add `owner/repo#NNN` → `https://github.com/$1/$2/issues/$3` hyperlink rule
- [x] 5.3 Verify `wezterm.default_hyperlink_rules()` is still prepended (full GitHub URLs covered by default)

## 6. Build & Validate

- [x] 6.1 Run `nh darwin switch .` and confirm no build errors
- [ ] 6.2 Open a WezTerm tab, run a command, verify `CTRL+SHIFT+Up/Down` jumps to previous prompt
- [ ] 6.3 Confirm tab title updates to `<dir> (<process>)` when running nvim
- [ ] 6.4 Trigger quick-select, confirm Nix path and git SHA candidates appear
- [ ] 6.5 Ctrl-click a Nix store path and an `owner/repo#NNN` reference, verify correct URLs open
- [x] 6.6 Commit and push
