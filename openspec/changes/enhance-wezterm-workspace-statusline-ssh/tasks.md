## 1. Workspace switcher default entry (`pkg/ui.lua`)

- [x] 1.1 In the `wm.get_choices` override, build the result starting with a
  pinned `{ id = "default", label = "default" }` choice, then append the parsed
  `sy list` sessions.
- [x] 1.2 Verify the pinned entry survives an empty / header-only `sy list` and
  an unresolved/erroring `sy` binary (graceful degrade).
- [x] 1.3 Confirm selecting `default` performs a create-if-absent switch to the
  `default` workspace (no separate keybinding added). Verified against plugin
  source: `data.lua:get_custom_choices` keys the entry by `name`, dedupes it
  against the live/saved set (so `default` is never duplicated) and the switcher
  fires `SwitchToWorkspace{ name = "default" }` (create-if-absent).
- [x] 1.4 Harden the workspace-manager keybinding override: strip the four leader
  bindings `apply_to_config` injects (`LEADER+s`, `LEADER+S`, `CTRL+]`, `CTRL+[`)
  by `(key, mods)` identity rather than a trailing count-trim, and keep the
  in-switcher `key_tables.workspace_switcher_actions`. `CTRL+[` (= ESC) in
  particular must not survive (it would shadow vim).

## 2. Statusline (`pkg/ui.lua`)

- [x] 2.1 Add the built-in `workspace` component to the `tabline.setup` sections
  as `tabline_x = { "workspace" }`; leave the other left sections untouched.
- [x] 2.2 Remove the right-edge hostname: set `tabline_z = {}` (was
  `{ "hostname" }`). Confirm overwrite-merge leaves
  `mode`/`locked_indicator`/`domain`/`agent_status` intact and `tabs_enabled=false`
  still uses the custom `format-tab-title`.

## 3. SSH picker (`pkg/keybindings.lua` + `default.nix`)

- [x] 3.1 Vendor `DavidRR-F/smart_ssh.wezterm` via `fetchFromGitHub` in
  `default.nix` and expose its store path in `config.json`'s `plugins` map.
- [x] 3.2 Load smart_ssh in `M.setup` via `plugin_loader.load("smart-ssh")`;
  `get_ssh_picker` returns `smart_ssh.tab()`, falling back to
  `act.ShowLauncherArgs{ flags = "FUZZY|DOMAINS" }` if the plugin fails to load.
  Preserve the `SUPER+SHIFT+s` binding and its locked-mode passthrough.
- [x] 3.3 Build `config.ssh_domains` from `enumerate_ssh_hosts()` shaped to
  smart_ssh's formatter (`name = "ssh:"..host`, `multiplexing="None"`,
  `assume_shell="Posix"`), skipping the synthetic `%.host` wildcard entries.
- [x] 3.4 Attach `ssh_option` (identityagent = `$SSH_AUTH_SOCK`, identityfile =
  first existing default key) to each domain so libssh authenticates with the
  agent / key instead of prompting for a password.
- [x] 3.5 Coverage-merge `~/.ssh/known_hosts` (skip hashed `|1|…` and malformed
  lines, unwrap `[host]:port`), deduped against the enumerated set, as additional
  `ssh:<host>` domains.

## 4. Appearance picker (`pkg/ui.lua` + `default.nix`)

- [x] 4.1 Vendor `sravioli/lantern.wz` (+ `log.wz`, `memo.wz`) via
  `fetchFromGitHub`; expose store paths in `config.json`. Wrap lantern in
  `applyPatches` with `patches/lantern-deps-loader.patch`.
- [x] 4.2 Create `patches/lantern-deps-loader.patch` routing lantern's `deps.lua`
  through `plugin_loader.load` (log/memo/ribbon/warp) instead of
  `wezterm.plugin.require`.
- [x] 4.3 Before loading lantern, set
  `wezterm.GLOBAL.__lantern_plugin_dir = config_data.plugins.lantern` so its
  bundled flames resolve from the Nix store path.
- [x] 4.4 Load lantern, call `lantern.setup{...}` (log off, `default_font.font_size`
  = our font size, `color.opacity` = configured opacity) and `lantern.rekindle(config)`.
- [x] 4.5 Bind `SUPER+SHIFT+l` to a dispatcher `InputSelector` over the 11
  appearance categories that performs the chosen `lantern.light.<x>()` action;
  include the locked-mode passthrough.

## 5. Validate and roll out (human-verification checkpoints)

- [x] 5.1 `git add` the changed Lua, `default.nix`, and the new patch (flakes only
  see tracked files).
- [x] 5.2 Gating signal: `nh darwin build` passes (also verifies the four new
  plugin hashes and that the lantern patch applies).
- [ ] 5.3 `nh darwin switch`.
- [ ] 5.4 [HUMAN] `SUPER+s` lists `default` pinned at the top; selecting it from
  inside a seshy session returns to the default workspace.
- [ ] 5.5 [HUMAN] The tabline shows the active workspace name in `tabline_x` and
  no longer shows the hostname on the right edge.
- [ ] 5.6 [HUMAN] `SUPER+SHIFT+s` opens smart_ssh's "Choose Host" picker, lists
  SSH hosts (including a `known_hosts`-only host), and connecting to a
  key-configured host no longer prompts for a password.
- [ ] 5.7 [HUMAN] `SUPER+SHIFT+l` opens the appearance dispatcher; picking
  "Colorscheme" then a scheme applies it live.
