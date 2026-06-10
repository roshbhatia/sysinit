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

## 2. Statusline workspace indicator (`pkg/ui.lua`)

- [x] 2.1 Add the built-in `workspace` component to the `tabline.setup` sections
  as `tabline_x = { "workspace" }`; leave the other sections untouched.
- [x] 2.2 Confirm overwrite-merge leaves `mode`/`locked_indicator`/`domain`/
  `agent_status`/`hostname` intact and `tabs_enabled=false` still uses the custom
  `format-tab-title`.

## 3. SSH picker (`pkg/keybindings.lua` + domain config)

- [x] 3.1 Seed `config.ssh_domains` from `wezterm.default_ssh_domains()` and set
  `assume_shell = "Posix"` on each (done in `pkg/keybindings.lua` `M.setup`,
  where the picker and `config` both live).
- [x] 3.2 Build a coverage-merge helper: parse `~/.ssh/known_hosts` (skip hashed
  `|1|…` and malformed lines, unwrap `[host]:port` tokens), dedupe against
  generated domain names, and append `SSH:` exec `SshDomain` entries
  (`multiplexing = "None"`). `ssh -G` resolution deferred — known_hosts covers
  the wildcard-derived gap without a per-host subprocess.
- [x] 3.3 Replace the `InputSelector` in `get_ssh_picker` with
  `act.ShowLauncherArgs{ flags = "FUZZY|DOMAINS" }`; preserve the `SUPER+SHIFT+s`
  binding and its locked-mode passthrough.

## 4. Validate and roll out (human-verification checkpoints)

- [x] 4.1 `git add` the changed Lua (flakes only see tracked files).
- [x] 4.2 Gating signal: `nh darwin build` passes.
- [ ] 4.3 `nh darwin switch`.
- [ ] 4.4 [HUMAN] `SUPER+s` lists `default` pinned at the top; selecting it from
  inside a seshy session returns to the default workspace.
- [ ] 4.5 [HUMAN] The tabline shows the active workspace name (seshy session
  name, or `default`) in its right-side section.
- [ ] 4.6 [HUMAN] `SUPER+SHIFT+s` opens the fuzzy launcher and lists SSH hosts,
  including at least one host the old `enumerate_ssh_hosts` picker omitted
  (wildcard-derived or `known_hosts`-only).
- [ ] 4.7 [HUMAN] Connecting to a host with remote `wezterm` via its `SSHMUX:`
  domain survives a brief disconnect/reattach; a bare host still works via `SSH:`.
