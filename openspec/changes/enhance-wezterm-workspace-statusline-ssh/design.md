# Design

## Context

All changes live in the WezTerm Lua config under
`modules/home/programs/wezterm/lua/sysinit/pkg/`, loaded by `extraConfig`'s
`require("sysinit.pkg.*").setup(config)` chain. Plugins are vendored via
`fetchFromGitHub` in `default.nix` and loaded through the custom
`plugin_loader.lua` (not `wezterm.plugin.require`, which cannot git-clone from
the Nix store). Two new plugins are vendored: `DavidRR-F/smart_ssh.wezterm`
(SSH picker) and `sravioli/lantern.wz` (appearance picker, plus its `log.wz` /
`memo.wz` deps).

Relevant current state:

- `pkg/ui.lua` loads `workspace-manager`, overrides `wm.get_choices` to parse
  `sy list` (col 1 = name, path = `seshy_dir/name`), sets `recency` sort and
  session restore, strips the plugin's injected leader keys, and binds
  `SUPER+s → wm.workspace_switcher()`. It also calls `tabline.setup` with
  sections `a={mode,locked_indicator}`, `b={domain}`, `x={}`, `y={agent_status}`,
  `z={hostname}` and `tabs_enabled=false`.
- `pkg/keybindings.lua` has `get_ssh_picker()`:
  `enumerate_ssh_hosts()` (filtering wildcard/github entries) → `InputSelector`
  → `SpawnTab{DomainName="SSH:"..id}`, bound to `SUPER+SHIFT+s`. The libssh
  transport ignored `~/.ssh/config`, so connections prompted for a password.

## Goals / Non-Goals

**Goals.** Add a `default` home entry to the switcher; surface the active
workspace in the tabline and drop the redundant hostname; make the SSH picker
both more usable (smart_ssh's fuzzy "Choose Host" selector) and passwordless
(agent / key auth via `ssh_option`) while covering hosts `enumerate_ssh_hosts`
cannot see; add a runtime appearance picker (lantern) on a single key.

**Non-Goals.** No seshy changes; no session-persistence behavior change; no
`SSHMUX:` / reattachable domains (smart_ssh's model is single-shot exec); no
auto-mux of every host.

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

`tabline.setup` merges per-section by overwrite, so naming only the sections we
change (`tabline_x`, `tabline_z`) leaves the others intact. The redundant
right-edge hostname is dropped at the same time (`tabline_z = {}`): the
connection context is already carried by the `domain` section (`tabline_b`), so
the hostname only duplicated it. Because the workspace indicator is a
status-section component and `tabs_enabled=false` keeps the custom
`format-tab-title` handler authoritative for tab labels, the two do not interact.

### 3. SSH picker — smart_ssh selector + key-auth domains + coverage merge

We vendor `DavidRR-F/smart_ssh.wezterm` (the user preferred its UX over the
native launcher) and build the domains it lists ourselves rather than calling
its `apply_to_config`:

1. **Picker.** `get_ssh_picker()` returns `smart_ssh.tab()` — an
   `action_callback` that opens a "Choose Host" `InputSelector` over
   `mux.all_domains()` filtered to names matching `^ssh` (case-insensitive),
   then `SpawnCommandInNewTab` into the chosen domain. If the plugin fails to
   load, fall back to `act.ShowLauncherArgs{ flags = "FUZZY|DOMAINS" }` (the
   `DOMAINS` content flag is required; `FUZZY` alone yields an empty launcher,
   wezterm#2377). Bound to `SUPER+SHIFT+s` with the locked-mode passthrough.
2. **Domain naming.** smart_ssh's formatter does `string.lower(name:sub(5))`,
   so domains MUST be named `ssh:<host>` (the `ssh:` prefix is exactly 4 chars)
   to render the bare host. Each domain is
   `{ name = "ssh:"..host, remote_address = host, multiplexing = "None",
   assume_shell = "Posix" }`. `multiplexing = "None"` (single-shot exec) because
   we do not assume remote `wezterm` — hence no `SSHMUX:` reattachable variant.
3. **Key auth.** WezTerm's libssh transport did not honor `~/.ssh/config`, so
   connections prompted for a password. Each domain gets an `ssh_option` table
   (lowercased libssh keys): `identityagent = $SSH_AUTH_SOCK` when set, and
   `identityfile` = the first existing default key among `id_ed25519`,
   `id_ecdsa`, `id_rsa`. With no agent and no key file the option table is empty
   and the connection falls back to negotiated auth.
4. **Coverage merge.** `enumerate_ssh_hosts()` returns only literal `Host`
   names — it drops wildcard blocks, negations, unevaluated `Match exec`, and
   never reads `known_hosts` (wezterm#5553, #5755). Augment it by parsing
   `~/.ssh/known_hosts`: skip hashed (`|1|…`) and malformed lines, unwrap
   `[host]:port` tokens, skip empties/globs, and dedupe by host name against the
   enumerated set before appending as additional `ssh:<host>` domains.

### 4. Appearance picker — lantern on a single dispatcher key

We vendor `sravioli/lantern.wz` (plus its `log.wz` / `memo.wz` deps) for a
runtime picker over colorscheme, fonts, GPU front-end, opacity, padding, cursor
and tab-bar styles. Two store-path adaptations are required:

1. **deps via the plugin loader.** lantern's `deps.lua` resolves `log`, `memo`,
   `ribbon`, `warp` through `wezterm.plugin.require`, which cannot git-clone from
   the Nix store. `patches/lantern-deps-loader.patch` (applied with
   `applyPatches`) routes those four through `plugin_loader.load` instead.
2. **flame resolution.** lantern's `meta.find_plugin_dir` locates its bundled
   flame choice-sets from either a plugin url containing `lantern.wz` or
   `wezterm.GLOBAL.__lantern_plugin_dir` — and a Nix store path
   (`/nix/store/HASH-source`) has neither. Because `api.lua` registers the
   built-in wicks at module-load time, we set
   `wezterm.GLOBAL.__lantern_plugin_dir = config_data.plugins.lantern` **before**
   loading. After load we `lantern.setup{ log = {enabled=false}, default_font =
   {font_size=…}, color = {opacity=…} }` and `lantern.rekindle(config)` to
   restore any persisted pick.

**Keybinding choice.** lantern's README binds `CTRL+SHIFT+c/f/…` per category,
which collide with this config's copy (`CTRL+SHIFT+c`) and pane-select
(`CTRL+SHIFT+f`). Instead a single `SUPER+SHIFT+l` dispatcher opens one
`InputSelector` over the 11 categories and performs the chosen
`lantern.light.<x>()` action — one key, no collisions, same locked-mode
passthrough as the other smart bindings. If lantern fails to load, the failure
is logged and the binding is simply not registered.

## Risks / Trade-offs

- **known_hosts noise.** known_hosts can hold many stale/one-off hosts; the
  picker could get long. Mitigation: it is fuzzy-filtered, and the parse skips
  hashed lines (which are unusable as display names anyway). If noise is a
  problem, gate the merge behind a small allowlist later — out of scope here.
- **No reattach.** smart_ssh's model is single-shot exec (`multiplexing =
  "None"`); closing the tab ends the connection. Users wanting persistence
  should use a remote multiplexer (tmux/zellij) — documenting rather than adding
  `SSHMUX:` keeps the picker's domain list uniform.
- **Vendored-plugin drift.** Three pinned upstreams (smart_ssh, lantern, its
  deps) plus a lantern patch now ride the config; the patch and the
  `__lantern_plugin_dir` fix are coupled to lantern's internals and can break on
  bump. The pins are explicit (rev+hash) so drift surfaces at build, not runtime.

## Migration

None — additive. The old `InputSelector` SSH picker is replaced in place; the
`SUPER+SHIFT+s` binding and its locked-mode passthrough are preserved. The new
`SUPER+SHIFT+l` appearance dispatcher is additive.

## Rollout

Each capability is independent: ship the switcher `default` entry, the
`tabline_x`/`tabline_z` changes, the SSH picker, and the appearance picker in any
order. Gating signal is `nh darwin build` (then `nh darwin switch`); `git add`
changed Lua, `default.nix`, and the new patch first so the flake sees them.
