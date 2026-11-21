# Rex and WezTerm capability audit

This audit covers the sysinit workstation terminal workflows and Rex for Mac
preview build 2061. Rex implements Lua for configuring keys, invoking actions,
and running scripts against its server. Client settings, layouts, and terminal
processes have separate APIs. The table distinguishes interfaces verified in
the installed build from ports that still need implementation.
[Rex Lua API](https://www.superlogical.com/rex/docs/reference/lua)

| Workflow | Rex capability | Shared contract and remaining work |
| --- | --- | --- |
| Theme and typography | The Mac client imports Ghostty and iTerm palettes and exposes font, fallbacks, size, tint, and pane padding as actions. | Both terminals consume sysinit's terminal palette. Rex applies the imported theme through a local Lua action. Native materials, opacity and blur, and asymmetric cell padding use different models. |
| Daily keys and editing | Native actions cover splits, focus, resize, float, tab operations, search, copy mode, fonts, and the command palette. Server Lua can inspect the foreground process and forward a key. | Share key intent, directions, and passthrough policy as data when the next keymap changes. Resolve actual actions in each client. Both bind Cmd+F to a scratch pane owned by the current tab. Rex page scrolling uses its native actions. |
| Native sessions | Rex supports creating, attaching, renaming, closing, and listing sessions. Session geometry belongs to the Rex server. | Use each client's lifecycle directly. WezTerm's numbered workspace slots, Lua recovery snapshots, and agent-resume behavior have no shared state format. Define slot ordering only if both clients need the same behavior. |
| Provider menu | Rex has a native session picker and Lua text and choice prompts. Lua can run a process with structured argv, deadline, stdin, and JSON output. | Both clients use `terminal-picker-call` and the same `provider/v1` manifests for Seshy, zoxide, Tether, and `tq`. Rex presents results in its native picker and translates spawn plans into Rex blocks. Provider create, rename, and delete require separate integration with the capabilities each provider declares. |
| Shells, remote hosts, and spawning | Rex creates terminal blocks with argv and cwd and connects to named Rex servers. The Mac client exposes a local startup command. | Both terminals use the same managed Nushell argv and baseline PATH. Rex supplies PATH in the startup command before Nushell loads its hooks. WezTerm mux domains, SSH and Mosh forwarding behavior, and Rex server addresses need separate adapters. The client's startup setting applies to new panes it opens on the local server. |
| Queue jobs, logs, and terminal identity | Pueue jobs and `tq` records are independent of the terminal UI. Rex opens the selected job's log in a tab. | Share browse and log behavior. A running `tq --terminal` job stores a WezTerm workspace today. Add a Rex backend before changing where new attempts run. Persist backend plus opaque identifier for future attach and cancel, and keep existing WezTerm records readable. |
| Agent activity, capture, and recovery | Rex exposes screen text, terminal process state, session and block events, and program status via OSC 7501. | Continue using the agent registry and existing signals as inputs. A Rex adapter can emit OSC 7501 or render status from the same events. WezTerm badges, palette previews, snapshots, and scrollback restore remain client-specific. |
| Neovim navigation and companion panes | Rex exposes split, focus, input, capture, and close operations through its CLI and Lua API. | Rex can launch either `nvim` or the separately packaged `neorex` frontend. The existing `sysinit.nvim` WezTerm helper is the starting boundary for an editor-side terminal adapter. Discover the backend from the process context and keep pane IDs opaque. Harness launch and Markdown preview are good first callers. |
| Desktop integration and rendering | Rex has a native Mac window, tab UI, sidebar, themes, floating panes, and copy mode. | Preserve WezTerm-specific tabline, shaders, warp and visor behavior, custom hyperlink rules, mouse semantics, and window-manager routing in that client. Sysinit uses macOS preferences to set the Rex tab bar to Below. Build 2061 exposes that choice in Settings and omits it from the Lua action schema. |

[Rex Mac actions](https://www.superlogical.com/rex/docs/reference/mac-actions),
[Rex Mac settings](https://www.superlogical.com/rex/docs/reference/mac-settings),
[Rex custom UI](https://www.superlogical.com/rex/docs/customize/custom-ui),
[Rex server API](https://www.superlogical.com/rex/docs/reference/api),
[Rex Lua events](https://www.superlogical.com/rex/docs/automate/lua-events),
[Program status protocol](https://www.superlogical.com/rex/docs/build/program-status),
[sysinit WezTerm behavior](https://github.com/roshbhatia/sysinit.wezterm)

## Vim copy mode

The managed `Ctrl+Escape` and `Ctrl+Shift+X` shortcuts enter Rex's native copy
mode. Rex provides Vim motions, character, line and block selections, match and
character search, yank, and exit. Rex also implements counts and paragraph
motions. Its documented defaults differ from WezTerm for Tab and Shift+Tab,
Return, Space, Ctrl+C, Ctrl+G, and the horizontal selection-end swap. Return
yanks in Rex and moves to the start of the next line in WezTerm. The installed
Rex action schema has no next-line-start motion or horizontal-only swap.
[Rex copy mode actions](https://www.superlogical.com/rex/docs/reference/mac-actions)

Rex currently reports `xterm-256color` on this host. Moving to `xterm-rex`
requires installing the terminfo entry through Nix and integrating Rex's SSH
fallback with the managed SSH configuration.
[Rex shell and terminal integration](https://www.superlogical.com/rex/docs/automate/shell-scripting)

## Neorex

Neorex is a frontend for one background Neovim instance. It presents that
instance's editor windows as real Rex panes and shares buffers, registers, undo,
and language servers. Its palette-based colorscheme lets Rex provide the ANSI
colors, while RGB highlights retain their own colors. The project ships a Nix
flake and uses the `nvim` on PATH. The workstation currently uses Neovim 0.12.6.
Upstream develops against 0.13-dev and calls out potential statusline differences
on older versions. [Neorex README](https://github.com/alexrlocke/neorex)

Sysinit installs the pinned `neorex` command on Apple Silicon hosts with Rex
enabled. Run it inside Rex to opt in. Check close behavior, picker floats,
statusline rendering, and pane navigation before adopting it as a daily editor.
Upstream lists split-management, tab page, and global statusline limitations.
Rex auto-balancing can override layout sizes from Neovim. Ordinary `nvim`
remains the baseline for evaluating the editor's terminal adapter.
[Neorex requirements and limitations](https://github.com/alexrlocke/neorex#requirements)

## Abstraction order

1. Keep palette and editor theme choices in sysinit. Render them through each
   client's supported configuration surface.
2. Extend the existing provider picker with lifecycle operations only when the
   provider declares the corresponding capability.
3. Extract key intent and foreground passthrough rules when a second shared
   keymap edit justifies changing both renderers. Keep platform shortcuts,
   client defaults, copy-mode behavior, and panic or fallback keys local.
4. Introduce a terminal backend for a real caller such as Neovim split or focus.
   Let the caller define the methods it needs. Extend the contract to queue
   attachments and agent activity after the first backend works end to end.
