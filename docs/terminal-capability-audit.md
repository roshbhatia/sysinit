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
| Daily keys and editing | Native actions cover splits, focus, resize, float, tab operations, search, copy mode, fonts, and the command palette. Server Lua can inspect the foreground process and forward a key. | Share key intent, directions, and passthrough policy as data when the next keymap changes. Resolve actual actions in each client. Rex page scrolling and native floating behavior differ from WezTerm's fixed-line scrolling and tab-owned scratch pane. |
| Native sessions | Rex supports creating, attaching, renaming, closing, and listing sessions. Session geometry belongs to the Rex server. | Use each client's lifecycle directly. WezTerm's numbered workspace slots, Lua recovery snapshots, and agent-resume behavior have no shared state format. Define slot ordering only if both clients need the same behavior. |
| Provider menu | Rex has a native session picker and Lua text and choice prompts. Lua can run a process with structured argv, deadline, stdin, and JSON output. | Reuse the existing `provider/v1` manifests for Seshy, zoxide, Tether, and `tq`. Move the current WezTerm-named frame runner toward a terminal-neutral command if Rex becomes its second consumer. Add a Rex presenter and translate launch plans at that boundary. Expose create, rename, and delete only when the provider declares them. |
| Shells, remote hosts, and spawning | Rex creates terminal blocks with argv and cwd and connects to named Rex servers. | Keep the command, cwd, and host selection policy shareable. WezTerm mux domains, SSH and Mosh forwarding behavior, and Rex server addresses need separate adapters. Rex does not inherit the WezTerm shell launch command. |
| Queue jobs, logs, and terminal identity | Pueue jobs and `tq` records are independent of the terminal UI. Rex can launch a log viewer in a block. | Share browse and log behavior. A running `tq --terminal` job stores a WezTerm workspace today. Add a Rex backend before changing where new attempts run. Persist backend plus opaque identifier for future attach and cancel, and keep existing WezTerm records readable. |
| Agent activity, capture, and recovery | Rex exposes screen text, terminal process state, session and block events, and program status via OSC 7501. | Continue using the agent registry and existing signals as inputs. A Rex adapter can emit OSC 7501 or render status from the same events. WezTerm badges, palette previews, snapshots, and scrollback restore remain client-specific. |
| Neovim navigation and companion panes | Rex exposes split, focus, input, capture, and close operations through its CLI and Lua API. | Keep ordinary Neovim in Rex. The existing `sysinit.nvim` WezTerm helper is the starting boundary for an editor-side terminal adapter. Discover the backend from the process context and keep pane IDs opaque. Harness launch and Markdown preview are good first callers. |
| Desktop integration and rendering | Rex has a native Mac window, tab UI, sidebar, themes, floating panes, and copy mode. | Preserve WezTerm-specific tabline, shaders, warp and visor behavior, custom hyperlink rules, mouse semantics, and window-manager routing in that client. Check individual Rex capabilities before promising the same presentation or behavior. |

[Rex Mac actions](https://www.superlogical.com/rex/docs/reference/mac-actions),
[Rex Mac settings](https://www.superlogical.com/rex/docs/reference/mac-settings),
[Rex custom UI](https://www.superlogical.com/rex/docs/customize/custom-ui),
[Rex server API](https://www.superlogical.com/rex/docs/reference/api),
[Rex Lua events](https://www.superlogical.com/rex/docs/automate/lua-events),
[Program status protocol](https://www.superlogical.com/rex/docs/build/program-status),
[sysinit WezTerm behavior](https://github.com/roshbhatia/sysinit.wezterm)

## Neorex

Neorex is a frontend for one background Neovim instance. It presents that
instance's editor windows as real Rex panes and shares buffers, registers, undo,
and language servers. Its palette-based colorscheme lets Rex provide the ANSI
colors, while RGB highlights retain their own colors. The project ships a Nix
flake and uses the `nvim` on PATH. The workstation currently uses Neovim 0.12.6.
Upstream develops against 0.13-dev and calls out potential statusline differences
on older versions. [Neorex README](https://github.com/alexrlocke/neorex)

Use it as an explicit experiment in a disposable Rex session. Check split and
close behavior, the configured theme, picker floats, statusline rendering, and
pane navigation against the managed Neovim configuration before adopting it.
Upstream lists split-management, tab page, and global statusline limitations.
Rex auto-balancing can override layout sizes from Neovim. Ordinary `nvim`
remains the baseline for evaluating the editor's terminal adapter.
[Neorex requirements and limitations](https://github.com/alexrlocke/neorex#requirements)

## Abstraction order

1. Keep palette and editor theme choices in sysinit. Render them through each
   client's supported configuration surface.
2. Add the Rex provider presenter against the existing frame protocol. Test
   list, open, and provider-owned lifecycle operations before extending it.
3. Extract key intent and foreground passthrough rules when a second shared
   keymap edit justifies changing both renderers. Keep platform shortcuts,
   client defaults, copy-mode behavior, and panic or fallback keys local.
4. Introduce a terminal backend for a real caller such as Neovim split or focus.
   Let the caller define the methods it needs. Extend the contract to queue
   attachments and agent activity after the first backend works end to end.
