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
2. **The active workspace is invisible in the statusline, and the right edge
   wastes space on the hostname.** The tabline sections are
   `tabline_a={mode,locked}`, `tabline_b={domain}`, `tabline_x={}` (empty),
   `tabline_y={agent_status}`, `tabline_z={hostname}`. The current workspace —
   which under this workflow *is* the active seshy session name — appears
   nowhere, even though `tabline.wez` ships a built-in `workspace` component and
   `tabline_x` is empty; meanwhile `tabline_z` shows a hostname that duplicates
   the connection context the `domain` section already carries.
3. **The SSH picker is blind to most of `~/.ssh/config` and prompts for a
   password.** `SUPER+SHIFT+s` feeds `wezterm.enumerate_ssh_hosts()` into a
   custom `InputSelector`. That function only returns *literal* `Host` names — it
   silently drops wildcard blocks (`Host *.cluster.com`), negations, unevaluated
   `Match exec`, and never reads `known_hosts`. And WezTerm's libssh transport
   does not reliably honor `~/.ssh/config`, so even configured hosts prompt for a
   password instead of using the agent / key.

The workspace and statusline gaps need no new plugin: the default-workspace entry
is a one-line addition to the existing `get_choices` override, the statusline
indicator is the `tabline.wez` built-in `workspace` component dropped into the
empty `tabline_x`, and the hostname removal is `tabline_z = {}`. The SSH gap is
closed by vendoring `DavidRR-F/smart_ssh.wezterm` for its fuzzy "Choose Host"
picker, building the `ssh_domains` it draws from (with an `ssh_option` agent/key
config so connections authenticate without a password), and coverage-merging
`~/.ssh/known_hosts` so wildcard-derived hosts still appear.

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
  session name, or `default`) in the one empty right-side section. Reuses
  `tabline.wez`; no custom component required.
- **Remove the `hostname` component from the right edge.** Set
  `tabline_z = {}` (previously `{ "hostname" }`). The `domain` section in
  `tabline_b` already conveys the connection context (local vs. an `ssh:<host>`
  domain), so the trailing hostname is redundant on the right edge.

### SSH picker (`pkg/keybindings.lua` + vendored `smart_ssh.wezterm`)

- **Vendor `smart_ssh.wezterm` for its fuzzy "Choose Host" picker.** Pin
  `DavidRR-F/smart_ssh.wezterm` via `fetchFromGitHub` and load it through
  `plugin_loader`. `get_ssh_picker` returns `smart_ssh.tab()` — an
  `InputSelector` over the mux domains whose name starts with `ssh` — with a
  fallback to the native `ShowLauncherArgs{flags="FUZZY|DOMAINS"}` if the plugin
  fails to load.
- **Build the `ssh_domains` the picker draws from, with key auth.** Seed
  `config.ssh_domains` from `enumerate_ssh_hosts()`, shaping each domain to match
  smart_ssh's formatter — name `ssh:<host>`, `multiplexing="None"`,
  `assume_shell="Posix"` — and attach an `ssh_option` table
  (`identityagent=$SSH_AUTH_SOCK`, `identityfile=<first existing default key>`)
  so the libssh transport authenticates with the agent / key instead of
  prompting for a password.
- **Coverage merge for hosts `enumerate_ssh_hosts` misses.** Parse
  `~/.ssh/known_hosts` (skip hashed `|1|…` and malformed lines, unwrap
  `[host]:port`), dedupe against the enumerated set, and append the parseable
  hosts as additional `ssh:<host>` domains so wildcard-derived and
  previously-connected hosts still appear in the picker.

### Appearance picker (`pkg/ui.lua` + vendored sravioli `lantern.wz`)

- **Vendor `lantern.wz` as a runtime appearance picker.** Pin `sravioli/lantern.wz`
  (plus its `log.wz`/`memo.wz` deps; `ribbon.wz`/`warp.wz` are already vendored)
  and load it through `plugin_loader`. lantern exposes built-in "wicks" for
  colorscheme, fonts, font size/leading/ligatures, GPU/front-end, window opacity
  & padding, inactive-pane opacity, cursor style, and tab-bar style.
- **Bind a single dispatcher to `SUPER+SHIFT+l`.** Rather than lantern's upstream
  `CTRL+SHIFT+c/f/…` bindings (which collide with this config's copy and
  pane-select), `SUPER+SHIFT+l` opens one `InputSelector` of appearance
  categories; choosing a category performs that wick's own selector
  (`lantern.light.<x>()`). `lantern.rekindle(config)` restores the last-picked
  appearance on startup.

### Non-goals

- No change to the seshy session-manager itself, its branch scheme, or how
  `sy list` enumerates sessions.
- No change to workspace *session persistence* (`session_enabled`,
  `session_restore_on_startup`) beyond surfacing `default` in the switcher.
- No change to the `tabline` theme, separators, or the other sections
  (`mode`/`locked`/`domain`/`agent_status`).
- No `SSHMUX:` multiplexer domains. smart_ssh's model is single-shot exec
  domains (`multiplexing="None"`); reattach-after-disconnect is out of scope.
- No patch to smart_ssh itself — it is used as-is; only the `ssh_domains` it
  reads are configured by this repo. lantern's `deps.lua` *is* patched (to
  resolve its sravioli deps through `plugin_loader` instead of
  `wezterm.plugin.require`, which cannot git-clone from the Nix store).

## Capabilities

### New Capabilities

- `wezterm-workspace-switcher`: the `SUPER+s` workspace switcher choices,
  including the pinned `default` home entry alongside seshy sessions.
- `wezterm-statusline-workspace`: the tabline workspace indicator that renders
  the active workspace / seshy session name, and the removal of the right-edge
  hostname.
- `wezterm-ssh-picker`: the `SUPER+SHIFT+s` SSH host picker — smart_ssh's fuzzy
  "Choose Host" selector, `ssh_domains` generation with `ssh_option` key auth,
  and the `known_hosts` coverage merge.
- `wezterm-appearance-picker`: the `SUPER+SHIFT+l` lantern appearance dispatcher.

### Modified Capabilities

<!-- No pre-existing specs under openspec/specs/ for these surfaces; all new. -->

## Impact

- `modules/home/programs/wezterm/default.nix` — pin `smart_ssh.wezterm`,
  `lantern.wz`, `log.wz`, `memo.wz` via `fetchFromGitHub`; expose their store
  paths in `config.json`'s `plugins` map. lantern is wrapped in `applyPatches`
  with `patches/lantern-deps-loader.patch`.
- `modules/home/programs/wezterm/patches/lantern-deps-loader.patch` (new) —
  routes lantern's `deps.lua` through `plugin_loader.load` instead of
  `wezterm.plugin.require`.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` — `get_choices`
  override (pinned `default`); `tabline.setup` sections (`tabline_x`/`tabline_z`);
  lantern load + `setup`/`rekindle` + the `SUPER+SHIFT+l` dispatcher; hardened
  workspace-manager keybinding strip (by `(key, mods)` identity).
- `modules/home/programs/wezterm/lua/sysinit/pkg/keybindings.lua` —
  `get_ssh_picker` returns `smart_ssh.tab()`; `build_ssh_domains` +
  `ssh_key_options` + `known_hosts` coverage merge; smart_ssh loaded in `M.setup`.
- **Progressive rollout.** The capabilities are independent and land in any
  order: the switcher `default` entry, the `tabline_x`/`tabline_z` changes, the
  SSH picker, and the appearance picker each build, verify, and ship on their own.
- **Gating signal.** `nh darwin build` (this repo uses `nh darwin`, not `nh os`)
  must pass before `nh darwin switch`. Flakes only see git-tracked files, so
  changed Lua and the new patch must be `git add`ed before building.
- **Human-verification checkpoints** (encoded in tasks.md):
  - After switch: `SUPER+s` lists `default` pinned at the top and selecting it
    returns to the default workspace.
  - After switch: the tabline shows the active workspace name (seshy session, or
    `default`) in `tabline_x` and no longer shows the hostname on the right edge.
  - After switch: `SUPER+SHIFT+s` opens smart_ssh's "Choose Host" picker, lists
    SSH hosts (including a `known_hosts`-only host), and connecting to a
    key-configured host no longer prompts for a password.
  - After switch: `SUPER+SHIFT+l` opens the appearance dispatcher; picking
    "Colorscheme" then a scheme applies it live.
