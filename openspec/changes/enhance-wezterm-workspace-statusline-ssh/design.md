# Design

## Context

All three changes live in the WezTerm Lua config under
`modules/home/programs/wezterm/lua/sysinit/pkg/`, loaded by `extraConfig`'s
`require("sysinit.pkg.*").setup(config)` chain. Plugins are vendored via
`fetchFromGitHub` in `default.nix` and loaded through the custom
`plugin_loader.lua` (not `wezterm.plugin.require`). No new plugin is added.

Relevant current state:

- `pkg/ui.lua` loads `workspace-manager`, overrides `wm.get_choices` to parse
  `sy list` (col 1 = name, path = `seshy_dir/name`), sets `recency` sort and
  session restore, strips the plugin's injected `CTRL+[` key, and binds
  `SUPER+s → wm.workspace_switcher()`. It also calls `tabline.setup` with
  sections `a={mode,locked_indicator}`, `b={domain}`, `x={}`, `y={agent_status}`,
  `z={hostname}` and `tabs_enabled=false`.
- `pkg/keybindings.lua` has `get_ssh_picker()`:
  `enumerate_ssh_hosts()` (filtering wildcard/github entries) → `InputSelector`
  → `SpawnTab{DomainName="SSH:"..id}`, bound to `SUPER+SHIFT+s`.

## Goals / Non-Goals

**Goals.** Add a `default` home entry to the switcher; surface the active
workspace in the tabline; make the SSH picker both more usable (native fuzzy
launcher, reattachable domains) and more complete (cover hosts
`enumerate_ssh_hosts` cannot see).

**Non-Goals.** No new vendored plugin; no seshy changes; no session-persistence
behavior change; no auto-mux of every host.

## Decisions

### 1. Default workspace — extend the existing `get_choices` override

The plugin's own `session_exclude_workspaces = {"default"}` is irrelevant here
because the override *replaces* the choice list wholesale. So the fix is to
prepend one static choice to the override's return value:

```lua
-- inside the wm.get_choices override, before returning the sy-list sessions
local choices = { { id = "default", label = "default" } }
-- ...append parsed `sy list` sessions...
return choices
```

`workspace-manager`'s switcher acts on the chosen `id`/`label`; for the static
entry the resulting `SwitchToWorkspace{ name = "default" }` is create-if-absent
(per WezTerm docs), so it is always safe. Pinning at index 1 keeps `default` at
the top regardless of `recency` sort applied to the dynamic entries. If `sy`
fails, `choices` already contains the `default` entry, satisfying the graceful
degrade requirement.

### 2. Statusline — built-in `workspace` component into `tabline_x`

`tabline.wez` ships a `workspace` window-component whose `update` returns
`string.match(wezterm.mux.get_active_workspace(), "[^/\\]+$")` — it renders the
active workspace, including the literal `default`. Drop it into the empty
right-side section:

```lua
tabline_x = { "workspace" },
```

`tabline.setup` merges per-section by overwrite, so naming only `tabline_x`
leaves the other sections intact. Because the indicator is a status-section
component and `tabs_enabled=false` keeps the custom `format-tab-title` handler
authoritative for tab labels, the two do not interact.

### 3. SSH picker — native launcher + generated domains + coverage merge

Three layered changes:

1. **Launcher.** Replace the `InputSelector` action with
   `act.ShowLauncherArgs{ flags = "FUZZY|DOMAINS" }`. Note `FUZZY` alone yields
   an empty launcher (wezterm#2377) — the `DOMAINS` content flag is required.
2. **Generated domains.** `config.ssh_domains = wezterm.default_ssh_domains()`,
   then loop to set `assume_shell = "Posix"` for cwd awareness. This yields
   `SSH:` and `SSHMUX:` domains per enumerated host for free.
3. **Coverage merge.** `enumerate_ssh_hosts()` returns only literal `Host`
   names — it drops wildcard blocks, negations, unevaluated `Match exec`, and
   never reads `known_hosts` (wezterm#5553, #5755). Augment the generated list
   with extra `SshDomain` entries built from:
   - `~/.ssh/known_hosts` — read the file, skip hashed (`|1|…`) and malformed
     lines, split host[,host]:port tokens, dedupe against names already present.
   - optionally `ssh -G <host>` via `wezterm.run_child_process` for hosts whose
     real resolution (Include globs, Match) WezTerm's parser mishandles.
   Coverage-added hosts are `SSH:` exec domains (`multiplexing = "None"`); we do
   not assume `wezterm` is present remotely, so no `SSHMUX:` variant for them.

Dedupe by host name so a host present in both the generated set and the merge
appears once.

## Risks / Trade-offs

- **known_hosts noise.** known_hosts can hold many stale/one-off hosts; the
  picker could get long. Mitigation: it is fuzzy-filtered, and the parse skips
  hashed lines (which are unusable as display names anyway). If noise is a
  problem, gate the merge behind a small allowlist later — out of scope here.
- **`ssh -G` cost.** Running `ssh -G` per host is a subprocess each; reserve it
  for targeted resolution, not a blanket sweep, or run it lazily.
- **SSHMUX expectations.** Users may expect every connection to persist;
  document that only hosts with remote `wezterm` get the `SSHMUX:` variant.

## Migration

None — additive. The old `InputSelector` picker is replaced in place; the
keybinding (`SUPER+SHIFT+s`) and its locked-mode passthrough are preserved.

## Rollout

Each capability is independent: ship the switcher `default` entry, the
`tabline_x` indicator, and the SSH picker in any order. Gating signal is
`nh darwin build` (then `nh darwin switch`); `git add` changed Lua first so the
flake sees it.
