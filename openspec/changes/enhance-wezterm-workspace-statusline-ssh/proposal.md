## Why

The WezTerm workspace/SSH navigation has three gaps that all stem from the same
shape: a picker or status surface that shows *less* than the runtime actually
knows.

1. **No way back to the default workspace.** `SUPER+s` opens the
   workspace-manager switcher, but `pkg/ui.lua` overrides `wm.get_choices` to
   return *only* seshy sessions parsed from `sy list`. The startup workspace
   (`default`, the one `wezterm.mux.get_active_workspace()` reports before any
   seshy session is picked) is never a choice — so once you switch into a
   session there is no switcher path back to the home base.
2. **The active workspace is invisible in the statusline.** The tabline sections
   are `tabline_a={mode,locked}`, `tabline_b={domain}`, `tabline_x={}` (empty),
   `tabline_y={agent_status}`, `tabline_z={hostname}`. The current workspace —
   which under this workflow *is* the active seshy session name — appears
   nowhere, even though `tabline.wez` ships a built-in `workspace` component and
   `tabline_x` is empty.
3. **The SSH picker is blind to most of `~/.ssh/config`.** `SUPER+SHIFT+s` feeds
   `wezterm.enumerate_ssh_hosts()` into a custom `InputSelector`. That function
   only returns *literal* `Host` names — it silently drops wildcard blocks
   (`Host *.cluster.com`), negations, unevaluated `Match exec`, and never reads
   `known_hosts`. So hosts you actually reach can be missing from the picker, and
   the connection is a throwaway `SSH:` exec domain (no reattach after a drop).

None of the three needs a new plugin: the default-workspace entry is a one-line
addition to the existing `get_choices` override, the statusline indicator is the
`tabline.wez` built-in `workspace` component dropped into the empty `tabline_x`,
and the SSH upgrade is built-in WezTerm API (`ShowLauncherArgs`,
`wezterm.default_ssh_domains()`) plus an `ssh -G` / `known_hosts` coverage merge.

## What Changes

### Workspace switcher (`pkg/ui.lua`)

- **Pin a `default` entry at the top of the switcher.** Extend the existing
  `wm.get_choices` override to prepend one static choice (label `default`) ahead
  of the `sy list` sessions. Selecting it performs
  `SwitchToWorkspace{name="default"}` (create-if-absent), giving a reliable path
  home from any seshy session. Reuses the existing override — no new keybinding,
  no plugin change.

### Statusline workspace indicator (`pkg/ui.lua`)

- **Add the built-in `workspace` component to `tabline_x`.** Set
  `tabline_x = { "workspace" }` in the existing `tabline.setup` call. The
  component renders `wezterm.mux.get_active_workspace()` (the active seshy
  session name, or `default`) in the one empty right-side section, grouped with
  the existing agent/hostname status indicators. Reuses `tabline.wez`; no custom
  component required.

### SSH picker (`pkg/keybindings.lua` + domain config)

- **Native fuzzy launcher.** Replace the custom `InputSelector` in
  `get_ssh_picker` with `act.ShowLauncherArgs{ flags = "FUZZY|DOMAINS" }`, which
  fuzzy-lists the configured SSH domains with no hand-rolled selector.
- **Generate domains from config.** Seed `config.ssh_domains` from
  `wezterm.default_ssh_domains()` (one `SSH:` and one `SSHMUX:` domain per
  enumerated host), so reattachable multiplexer domains exist for hosts that run
  `wezterm`.
- **Coverage merge for hosts `enumerate_ssh_hosts` misses.** Augment the
  generated domains with entries resolved from the real ssh client — parse
  `~/.ssh/known_hosts` and/or resolve specific hosts via `ssh -G <host>`
  (`run_child_process`) — so wildcard-derived and previously-connected hosts that
  `enumerate_ssh_hosts()` cannot see still appear in the picker as `SSH:` exec
  domains.

### Non-goals

- No new vendored WezTerm plugin (no `fetchFromGitHub` additions). The archived
  `smart_workspace_switcher`/`resurrect` and the near-zero-adoption `smart_ssh`
  add nothing the built-in API and existing plugins don't already provide.
- No change to the seshy session-manager itself, its branch scheme, or how
  `sy list` enumerates sessions.
- No change to workspace *session persistence* (`session_enabled`,
  `session_restore_on_startup`) beyond surfacing `default` in the switcher.
- No change to the `tabline` theme, separators, or the other sections
  (`mode`/`locked`/`domain`/`agent_status`/`hostname`).
- No automatic conversion of every SSH connection to a multiplexer domain;
  `SSHMUX:` requires `wezterm` on the remote, so coverage-merged hosts stay
  `SSH:` exec by default.

## Capabilities

### New Capabilities

- `wezterm-workspace-switcher`: the `SUPER+s` workspace switcher choices,
  including the pinned `default` home entry alongside seshy sessions.
- `wezterm-statusline-workspace`: the tabline workspace indicator that renders
  the active workspace / seshy session name.
- `wezterm-ssh-picker`: the `SUPER+SHIFT+s` SSH host picker — domain generation,
  coverage merge, and the native fuzzy launcher.

### Modified Capabilities

<!-- No pre-existing specs under openspec/specs/ for these surfaces; all new. -->

## Impact

- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` — `get_choices`
  override (pinned `default`) and `tabline.setup` sections (`tabline_x`).
- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua` — `get_ssh_picker`
  rewritten to `ShowLauncherArgs`; SSH-domain generation + coverage merge (here
  or in `pkg/core.lua`, wherever `config` domains are assembled).
- **Progressive rollout.** The three capabilities are independent and land in any
  order: the switcher `default` entry, the `tabline_x` indicator, and the SSH
  picker each build, verify, and ship on their own.
- **Gating signal.** `nh darwin build` (this repo uses `nh darwin`, not `nh os`)
  must pass before `nh darwin switch`. Flakes only see git-tracked files, so
  changed Lua must be `git add`ed before building.
- **Human-verification checkpoints** (encoded in tasks.md):
  - After switch: `SUPER+s` lists `default` pinned at the top and selecting it
    returns to the default workspace.
  - After switch: the tabline shows the active workspace name (seshy session, or
    `default`) in its right-side section.
  - After switch: `SUPER+SHIFT+s` opens the fuzzy launcher and lists SSH hosts,
    including at least one host the old `enumerate_ssh_hosts` picker omitted
    (wildcard-derived or `known_hosts`-only).
