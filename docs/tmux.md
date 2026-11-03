# Terminal sessions

Tmux owns sessions, windows, panes, floating terminals, application key locking,
copy mode, and the session picker. WezTerm supplies the renderer, fonts,
transparency, system clipboard, and operating-system window integration.

`ty terminal` is the shared interface for launchers and notification actions:

```sh
ty terminal catalog                       # live tmux and legacy native panes
ty terminal focus %3                      # reveal and focus a tmux pane
ty terminal focus wezterm:57              # focus an existing native pane
ty terminal open                          # independent new terminal session
ty terminal open seshy:project            # apply the sessionizer open plan
ty terminal run -- gh-dash-pr URL          # dedicated command session
```

Hammerspoon's Cmd-Space sources and PR-link choices use this interface. Renderer
commands live in its adapter, configured by `sysinit/terminal.json`. A future
renderer changes that adapter and configuration, without changing each launcher.
Existing native panes retain their compatibility path.

## Controls

The prefix is Ctrl-B. Prefix Space or prefix ? opens which-key.

| Action | Control |
| --- | --- |
| Sessions, panes, providers | Prefix s |
| Session slots 1–9 | Prefix F1–F9 |
| Floating terminal, hide or show | Prefix f |
| Lock application keys | Prefix g |
| Unlock | Ctrl-G |
| Split right or down, retaining remote host | Prefix `\|` or `-` |
| Split right or down locally | Prefix V or S |
| New window, retaining remote host or locally | Prefix c or C |
| Reorder window | Prefix `<` or `>` |
| Copy mode | Prefix `[` |
| Select paths, URLs, identifiers with thumbs | Prefix t |
| Copy working directory | Prefix Y |
| Toggle pane logging | Prefix P |
| Capture screen or full history | Prefix Alt-p or Alt-Shift-p |
| Save or restore sessions | Prefix Ctrl-S or Ctrl-R |
| Detach while preserving the session | Prefix d |

The session picker starts in normal mode. Use j/k, arrows, or Tab to move;
Enter or 1–9 selects a row. `/` starts filtering. Escape returns to normal mode,
and Escape again closes the picker. `!` shows attention, `a` shows agents,
`0` restores all rows, `n` creates a session, and `x` confirms a close. Provider
shortcuts appear in the heading. Escape from a provider returns to sessions;
provider loading is cancellable.

Copy mode uses v to begin selection and y to copy. g/G moves to the beginning or
end, Ctrl-U/Ctrl-D moves half a page, and `[`/`]` jumps between shell prompts.
The open plugin supplies o to open a selected file or URL, Ctrl-O to edit a file,
and Shift-S to search a selection. Mouse wheel scrolling uses native tmux
commands, with application mouse handling preserved.

## Lifecycle and persistence

An unnamed new terminal creates an independent session. Explicitly selecting a
named session reuses its existing GUI client when possible. Focus activates the
GUI window owning that client. Closing the last local client destroys its
session when no other client remains; explicit detach preserves it. Hidden
floating panes remain associated with their parent session.

Continuum saves the primary tmux server through resurrect every 15 minutes.
Its upstream multi-server guard leaves later temporary servers unsaved. Automatic restore is disabled;
prefix Ctrl-R restores deliberately. Resurrect restores the layout and supported
programs, rather than checkpointing arbitrary running processes. Logging is
opt-in per pane. Saves, logs, screen captures, and history live under
`$XDG_STATE_HOME/tmux`.

The picker and status bar call the original session-tree, tabline tab components, session-chip,
process-icon, badge, and agent-classification code. Presentation assets are
exported during the build; runtime rendering does not call the WezTerm GUI API.
The shared presentation cache is scoped to one tmux server and lasts one second.
