# WezTerm workflows restored in Rex

The baseline is sysinit commit `c686f3ed5`, immediately before the first Rex
revert. The Rex configuration targets macOS preview build 2061. Use
**Apply sysinit terminal settings** in Rex's command palette or press
`Ctrl+Cmd+Shift+A` after activation. New local panes use the resulting startup
command. Home Manager owns the Lua configuration, and nix-darwin owns the
preferences for tab placement and window fading.

| WezTerm workflow | Rex keys or entry point | Behavior in Rex |
| --- | --- | --- |
| Managed local shell | New panes, sessions, and scratch panes | Uses the same Nushell executable, config, environment and plugin files, and profile PATH. Clears inherited `PWD` so Nushell can initialize it from the actual working directory. |
| Terminal colors | Apply sysinit terminal settings | Imports the shared foreground, background, cursor, selection, and 16 ANSI colors as a named Ghostty palette. Uses sysinit's light or dark setting and tints the interface. |
| Typography and spacing | Apply sysinit terminal settings | Uses the shared monospace family and font size, plus Symbols Nerd Font fallback. Rex uses eight points of horizontal and six points of vertical pane padding. |
| Bottom tabs and inactive window treatment | Managed Darwin preferences | Tabs appear below the terminal. Inactive pane fading and the separate inactive-window fade are off, as in the restored baseline. Rex renders the window material. |
| Copy on selection | Apply sysinit terminal settings | Mouse selections are copied automatically. |
| Split down | `Ctrl+S`, `Ctrl+Shift+S` | Creates a pane below the current one. |
| Split right | `Ctrl+V`, `Ctrl+Shift+V`, `Cmd+Shift+V` | Creates a pane to the right. |
| Choose a pane | `Ctrl+Cmd+P`, `Ctrl+Shift+F` | Opens Rex's pane chooser. |
| Focus adjacent panes | `Ctrl+H/J/K/L` | Moves left/down/up/right. Vim, Neovim, Helix, Traces, and Orc can receive these keys directly. |
| Resize adjacent panes | `Ctrl+Shift+H/J/K/L`, `Ctrl+Cmd+Arrow` | Resizes in the indicated direction by three units. The letter bindings pass through to Vim, Neovim, and Helix. |
| Pane zoom | `Ctrl+M` | Toggles zoom for the current pane. |
| Floating scratch pane | `Cmd+F` | Opens a scratch shell in the current tab at the foreground working directory. Subsequent presses minimize or restore it through Rex's floating layer API. |
| Close a pane or detach | `Ctrl+W`, `Cmd+W` | Presents a choice between ending the current pane's process and closing the GUI window while keeping the session running. |
| Close pane only | `Ctrl+Shift+W`, `Cmd+Shift+W` | Shows only the pane-close choice. |
| New tab | `Ctrl+T`, `Cmd+T`, `Ctrl+Shift+T`, `Cmd+Shift+T` | Opens a tab in the current Rex session. |
| Next, previous, and recent tab | `Ctrl+Tab`, `Ctrl+Shift+Tab`, `Ctrl+Shift+O` | Moves between tabs or switches to the last-used tab in the current session. |
| Select tab by index | `Ctrl+1…9`, `Cmd+1…9` | Selects tabs 1–8. The 9 binding selects the last tab. |
| Rename tab | `Ctrl+Shift+R`, `Cmd+Shift+R` | Opens the native tab rename action. |
| Reorder tabs | `Ctrl+Shift+,`, `Ctrl+Shift+.` | Moves the current tab backward or forward. |
| New and full-screen windows | `Cmd+N`, `Cmd+Shift+N`, `Ctrl+Cmd+F` | Opens a new window or toggles native macOS full screen. |
| Reload configuration | `Cmd+R` | Reloads Rex configuration. |
| Command palette | `Cmd+;`, `Cmd+Shift+;`, `Ctrl+;`, `Ctrl+Shift+P`, `Cmd+Shift+P` | Opens Rex's native palette. |
| Clipboard and clear screen | `Cmd+C`, `Ctrl+Shift+C`, `Cmd+V`, `Cmd+K` | Copies, pastes, or sends `Ctrl+L` to the foreground program for clear-screen behavior. |
| Find terminal text | `Cmd+/`, `Ctrl+/` | Opens native find. The control binding passes through to Vim, Neovim, and Helix. |
| Jump between shell prompts | `Ctrl+Shift+Up`, `Ctrl+Shift+Down` | Uses native prompt navigation. Vim, Neovim, and Helix receive these keys directly. |
| Page scroll | `Ctrl+U/D`, `Cmd+U/D` | Uses native page scrolling. The control bindings pass through to the editors above, Traces, Orc, Slk, Diffnav, Changes, and the standard shells. |
| Vim-style terminal copy mode | `Ctrl+Escape`, `Ctrl+Shift+X` | Enters Rex's native copy mode for motions, selection, search, and yank. Individual copy-mode keys follow Rex's defaults. |
| Font zoom | `Ctrl/Cmd+-`, `Ctrl/Cmd+=`, `Ctrl/Cmd+0` | Decreases, increases, or resets the font size. |
| Session switcher | `Cmd+S` | Offers native sessions by their actual names, shared providers, and an entry for Rex's host and session picker. |
| Seshy sessions | Seshy in the switcher | Reads the same provider manifests and launch plans as WezTerm. Reuses a Rex session matching the worktree label, including old saved sessions with a `seshy:` prefix. |
| Recent directories | zoxide in the switcher | Opens the selected directory as a Rex session using the shared picker provider. |
| Remote shells | Tether in the switcher | Consumes the provider's command, arguments, and working directory. Native Rex server connections are available through Rex's own picker. |
| Queue attempts and logs | Task queue provider in the switcher | Presents jobs through the shared Pueue picker and opens returned log commands in a Rex tab. Queue terminal execution still uses the configured WezTerm provider. |
| Neovim integration | `nvim` or `neorex` on Apple Silicon | Runs managed Neovim in a terminal block. The restored pinned Neorex command is an opt-in frontend that maps Neovim windows to Rex panes. |

The first snapshot used Rex's native session lifecycle. WezTerm's numbered
workspace slots, recovery format, agent activity and resume UI, pane-targeted
review links, and terminal shaders are specific to WezTerm. The `Ctrl+G`
shortcut-lock and the Rex Reviewr binding were experiments after the first
revert and are outside this baseline.

[Rex Lua API](https://www.superlogical.com/rex/docs/reference/lua),
[Mac actions](https://www.superlogical.com/rex/docs/reference/mac-actions),
[Neorex](https://github.com/alexrlocke/neorex)
