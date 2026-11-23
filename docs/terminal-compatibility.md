# WezTerm and Rex compatibility

Sysinit installs both terminals on Darwin workstations. WezTerm is the managed
terminal provider for Seshy, Tether, and queue views. Rex uses its own sessions,
panes, CLI, and left sidebar. The Rex package pins macOS build 2061
(`0.1.0-preview.21`), and Home Manager generates `~/.config/rex/init.lua`.
The **Apply Sysinit terminal settings** action in Rex's command palette applies
the managed Nushell command, profile PATH, sidebar placement, and font.

| Workflow | WezTerm | Rex |
| --- | --- | --- |
| Nushell, Neovim, Changes, and Traces | The launcher uses the managed Nushell command. Changes and Traces use the managed Neovim configuration and preserve their structured CLI output. | Apply the Sysinit action and open a new local terminal. It uses the same shell command, PATH, and Neovim configuration. |
| Open a worktree review | `agent-diff --review --allow-directory` opens or refreshes a split. A temporary Git index includes untracked files. Plain directories open in the directory browser. | `Cmd+R` opens or hides Reviewr next to the current terminal. The native integration reviews tracked and staged files in Git repositories. Open an untracked file directly in Neovim. |
| Review the previous agent turn | Run `:ReviewrTurn` before the edit, then select Last turn. | Reviewr marks the baseline and refreshes the diff from Rex program-status events for a recognized agent. Use a separate worktree per agent for accurate attribution. |
| Draft inline feedback | Reviewr needs the caller's TTY metadata to verify the agent. The local macOS WezTerm build returned no TTY, so export wrote to the repository's `.reviewr/inbox`. Use `y` to copy the draft for manual paste. | Reviewr targets the paired Rex block when the active agent is recognized. It pastes a draft without submitting. |
| Exact source links and pull requests | The managed source-link handler opens a file comparison with Diffview. Atlas owns GitHub PR review. | Use Neovim and Atlas directly. Sysinit's WezTerm source-link handler is specific to that terminal. |
| Session management and persistence | Seshy owns saved workspaces. The WezTerm configuration restores layout and bounded scrollback, and Tether attaches to managed remote muxes. | Use the native sidebar or `rex session ls`, `rex session rename`, and `rex session kill`. Rex restores saved layouts on server restart. Running programs end, and agents resume through their harness. |
| Pane automation and queued jobs | Use `ty` or `nuwez`. Queue helpers use the configured WezTerm provider. | Use `rex do`, `rex block`, and `rex events` for native automation. Queue state and logs remain available through `tq`. |

`rex config check` validates the generated Lua against the installed binary.
After a configuration change, `rex config reload` loads it into the active server.

[Rex configuration](https://www.superlogical.com/rex/docs/customize/config)
· [Rex CLI](https://www.superlogical.com/rex/docs/reference/cli)
· [Rex restart behavior](https://www.superlogical.com/rex/docs/linux/upgrading)
· [Reviewr integration](https://github.com/paul-enz/reviewr.nvim#rex)
