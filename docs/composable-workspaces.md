# Workspace tool ownership

> MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY follow [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Summary

WezTerm displays live terminals. Seshy groups directories. Git owns checkout state. Tether connects a foreground process to a host.

## Goals

- The session tree MUST contain only live WezTerm workspaces, tabs, and panes.
- Directory selection MUST resolve the selected path before launching a local shell.
- Status updates MUST NOT discover saved directories or probe remote hosts.
- Removing a directory group MUST preserve branches and referenced directories.
- Git MUST enforce worktree removal checks unless the user supplies `--force`.

## Proposal

Keep the existing tree key and navigation. Dot opens a separate directory picker.
The command palette also provides `Open directory group` and `Connect to host`.
Host selection attaches a configured WezTerm domain. It does not enumerate remote seshy groups.

`sy new` and `sy add` accept `--reference` for existing directories.
`--start-point` selects the commit for a new branch. `--existing --branch` selects an existing branch.
Removing a group retains its branches. `sy prune` uses Git's merged-branch check and preserves branches that existed before seshy used them.
Existing directory layouts remain valid. This change performs no migration of user directories.

## Design details

| Owner | Responsibility | Decision |
|---|---|---|
| WezTerm | Live windows, tabs, panes, and focus | Retain the tree and separate its renderer from interaction handling |
| seshy | Named directory groups and checkout creation | Reuse its JSON listing and opening interfaces |
| Git | Branches, worktree registration, and checkout state | Preserve its refusal conditions |
| tether | SSH/Mosh transport selection | Keep `tsh` in the foreground; callers can consume native plans separately |
| roster | Provider catalog aggregation | Remove from sysinit's installed tools and WezTerm configuration |
| zmx | Explicit terminal persistence | Keep `sz` and direct attachment separate from directory selection |
| prose-style | Vale policy, pinned styles, and fixtures | Extract to `roshbhatia/prose-style` |
| gate | Hook decisions, notes, and hook output | Retain the existing extracted providers |
| go-utils | Shared Git, paths, and workspace primitives | Retain shared library ownership |
| sysinit utils | Desktop and editor integration commands | Keep agent-state, statusline, firefox-tabs, worker, watch, wezspawn, and workspace |

`utils workspace` supplies repository inventory, health, and history contracts used by the editor.
`changes workspace` supplies comparison snapshots with a different schema.
Moving the editor adapter would create another public interface without removing the integration responsibility.
It stays in sysinit, using the Git and workspace primitives already owned by `go-utils`.

The obsolete `hookfmt` package is removed. Neovim uses gate's standalone `note` command instead of the removed `utils note` command.
The `sy` wrapper is removed. `agent-review` remains an explicit command.

The Lua modules have separate roles:

| Module | Responsibility |
|---|---|
| `command.lua` | Execute an argument vector and decode JSON |
| `domains.lua` | Construct WezTerm SSH domains from SSH configuration |
| `ui/launcher.lua` | Select a directory or host and perform its explicit action |
| `ui/sessions.lua` | Track live workspace slots and focus times |
| `ui/session_tree.lua` | Read the mux tree and pane metadata |
| `ui/tree_rows.lua` | Render selectable tree rows |
| `ui/switcher.lua` | Handle selection, navigation, and close actions |

Directory commands come from Nix as argument vectors. Each command has a five-second timeout.
The launcher sets `cwd`, the local domain, and the plan's environment without constructing shell code.
A new workspace gets a unique name so an existing remote workspace cannot capture the launch.

WezTerm documents these fields in [SpawnCommand](https://wezterm.org/config/lua/SpawnCommand.html).
Host selection uses [AttachDomain](https://wezterm.org/config/lua/keyassignment/AttachDomain.html) to import the host's live terminals.

## Validation

The Lua tests cover local launching from a remote pane, cancellation, failed resolution, plan validation, host selection, and live tree rendering.
Editor tests verify the standalone notes command. The Nix editor check parses the configuration with WezTerm itself.
Seshy tests cover referenced directories, dirty worktrees, unmerged commits, start points, and explicit branch reuse.
Tether tests require foreground execution even when `WEZTERM_PANE` is set.
Prose-style builds run the original clean and failing fixtures without changing the rules.

## Drawbacks

The directory launcher runs a bounded local command on the GUI thread when requested.
The tree no longer displays cached remote directories or transport badges.
Branch retention changes cleanup behavior. A user must remove unwanted branches separately.

## Alternatives

Keeping roster only for local directory selection adds a cache and provider dispatch before an existing local CLI.
One repository per utility would split desktop integration contracts without adding independent consumers.

## Rollout

Sysinit pins the tested repository revisions. Building does not apply the machine configuration.
Applying the configuration changes future launches and leaves existing worktrees and terminal processes intact.
