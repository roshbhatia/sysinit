## Context

WezTerm ships a `wezterm.sh` integration script that, when sourced in the shell, emits OSC 133 escape sequences to mark prompt boundaries. Without it, WezTerm treats all terminal output as undifferentiated scrollback — no semantic zones, no prompt-jump keybindings, and triple-click line selection instead of output-block selection.

The Lua-side additions (tab titles, quick-select, hyperlinks) are self-contained to `ui.lua` and `keybindings.lua` with no external dependencies.

## Goals / Non-Goals

**Goals:**
- Enable OSC 133 prompt markers in zsh via `wezterm.sh` (guarded to WezTerm sessions only)
- Bind `CTRL+SHIFT+↑/↓` to `ScrollToPrompt` for prompt-to-prompt navigation
- Emit a `format-tab-title` handler that shows `dirname (process)` with a reasonable fallback
- Extend `quick_select_patterns` with Nix store hashes, git SHAs (7/40-char), UUIDs, absolute paths
- Add hyperlink rules for bare GitHub issue refs (`#123`) and Nix store paths (`/nix/store/…`)

**Non-Goals:**
- Workspace / window-grouping features
- Changes to the tabline plugin configuration
- Fish or bash shell integration (zsh only, matching existing shell setup)

## Decisions

**Guard `wezterm.sh` behind `$TERM_PROGRAM`**
WezTerm sets `TERM_PROGRAM=WezTerm`. Sourcing unconditionally would break SSH sessions or other terminals. Use `[[ $TERM_PROGRAM == "WezTerm" ]] && source "$(wezterm shell-completion --shell zsh)"` — no, actually `wezterm shell-integration` is the right subcommand. Alternatives: hardcode the Nix store path (fragile across rebuilds) vs. use `wezterm --shell-integration` at runtime (correct, version-matched).

**Tab title: dirname + process, not full path**
Full paths are too long for the tab bar. `basename $cwd` is too terse when multiple tabs share the same directory name. `~/code/sysinit (nvim)` is the sweet spot — short enough, informative enough. Fall back to `basename` only when `get_foreground_process` returns nil (e.g., freshly spawned tab).

**Quick-select: additive, not replacement**
`wezterm.default_hyperlink_rules()` is already applied. We extend with `table.insert` rather than replacing, so default URL detection is preserved.

**Hyperlink for `#123`**: These are ambiguous without a repo base URL. We scope them to GitHub by requiring the pattern only activates on click, opening `https://github.com` with the repo derived from the cwd's git remote — but that's complex. Simpler: just make them visually highlighted and let the user copy. Re-evaluated: WezTerm hyperlinks need a full URL in the rule. Skip bare `#123` detection; support full GitHub URLs and Nix store paths as clickable links only.

## Risks / Trade-offs

- [OSC 133 double-emission] If another prompt framework (oh-my-posh, starship) also emits OSC 133, markers may duplicate → Mitigation: check if oh-my-posh emits them already; if so, skip `wezterm.sh` sourcing.
- [Tab title flicker] `format-tab-title` fires frequently; heavy computation causes visible lag → Mitigation: keep the handler to a simple string concat, no I/O.
- [Quick-select false positives] Nix hash regex (`[a-z0-9]{32}`) may match non-hash strings → Acceptable trade-off; quick-select is user-initiated.
