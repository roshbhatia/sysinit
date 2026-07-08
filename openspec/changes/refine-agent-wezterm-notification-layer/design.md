## Context

The work described here extends three already-shipped systems:

- **`build-session-tree-switcher`** — the `SUPER+s` all-in-one session tree, the
  `format-tab-title` tab ribbon, the `tabline.setup` configuration, and the
  `open_session_tree` picker in `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`.
- **`build-agent-state-bus-and-surfaces`** — the per-pane OSC user-var + state file bus
  (`agent-state.sh`), the desktop notification layer (`agent-notify.sh`,
  `agent-prompt.sh`), and the click-to-navigate `agent-focus.sh` helper.
- Harness Nix configs: `claude.nix`, `codex.nix`, `amp.nix`, `opencode.nix` (and the
  forthcoming `gemini.nix` for agy).

The changes are surgical addendums to each, not redesigns.

## Goals / Non-Goals

**Goals:**
- Clean dead `tab_active`/`tab_inactive` tabline config before it misleads a reader.
- Surface agent working/waiting/done state in the tab bar via our live
  `format-tab-title` handler (not the dead tabline handler).
- Dismiss the terminal-notifier toast the instant the user clicks to navigate.
- Extend first-class lifecycle hook coverage to Amp, agy, and OpenCode (matching
  Claude's fidelity: state bus + done notification).
- Gate Codex done-notifications on elapsed time (the same 60-second threshold Claude
  uses) by writing a `.start` file from `PermissionRequest`.
- Make session tree shortcut filter keys discoverable without external documentation.

**Non-Goals:**
- No new harness instrumentation beyond the four (Amp, agy, OpenCode, Codex tweak).
- No overhaul of sound/timing model: Blow/Pop/Ping and the 60s gate are settled.
- No session-tree data-model or workspace walk changes.
- No MCP server additions.

## Decisions

**D1 — Read `pane.user_vars.agent_state` in `format-tab-title` as a plain table lookup.**
`PaneInformation` (the struct WezTerm passes into `format-tab-title`) exposes
`user_vars` as a plain Lua table, not a method. The value is already base64-decoded;
it arrives as the pipe-delimited `status|reason|since|agent` string the OSC transport
sets. We `pcall` the decode to keep the handler fail-safe. Alternative rejected:
calling `:get_user_vars()` on the `Pane` object — `format-tab-title` receives a
`PaneInformation` struct, not a live `Pane` object, and the method is not available on
it.

**D2 — Only non-idle agent states surface in the tab bar.**
Idle panes get no icon prefix; working/waiting/done panes get `⟳`/`◔`/`✔`. Showing
`idle` would add noise to every unattended pane and undermine the signal. Alternative
rejected: showing all states — defeats the purpose of a quick-scan tab bar.

**D3 — `agent-focus.sh` reconstructs the notification group from the pane's state file.**
The state file (`$state_dir/$pane.json`) carries `agent`, `session`, and `repo`
fields that are sufficient to reconstruct `agent-notify:$agent:$context` — the same
group string `agent-notify.sh` uses. If the state file is absent (pane already exited)
we fall through silently. Alternative rejected: passing the group as a CLI argument —
`agent-focus.sh` is called by terminal-notifier's `-execute` flag; the invocation string
is baked at notification-issue time and would need to be encoded there, adding coupling.

**D4 — Amp hooks use `amp.hooks` in `settings.json` via `ampConfig` in `amp.nix`.**
Amp 1.x supports `AgentEnd`, `ToolCallStart`, and `UserMessageSent` hook keys. These
are already inside the `builtins.toJSON` block; adding them is a plain Nix attribute
merge. Alternative rejected: a shell-wrapper around the `amp` binary — fragile, requires
PATH wrangling, and Amp's hook surface already exists.

**D5 — agy lifecycle hooks use the `onStop` / `onToolStart` / `onUserMessage` config keys.**
Antigravity CLI's config format (JSON) supports these hooks natively. The agy Nix
module (`gemini.nix`) produces its config JSON the same way `amp.nix` does — via
`builtins.toJSON`. Alternative rejected: a wrapper script — same objection as D4.

**D6 — OpenCode lifecycle hooks use `hooks.session.end` / `hooks.tool.before` in
`opencode.json`.**
OpenCode's hook surface (`hooks.session.start`, `hooks.session.end`, `hooks.tool.before`)
is already documented upstream. The `opencode.nix` config is written via the
`updateOpencodeConfig` jq-merge activation script, which deep-merges Nix-declared keys
into the mutable file. Hooks are a new top-level key; no existing runtime-written keys
conflict. Alternative rejected: using the `opencode-handoff` plugin for lifecycle events
— the plugin is for cross-harness handoff, not notification, and it has no hook surface.

**D7 — Codex `PermissionRequest` hook writes the `.start` file via a second hook entry.**
Codex fires `PermissionRequest` for every tool-approval prompt. The first interaction
is a reliable proxy for "the user has submitted something" — close enough to set the
elapsed-time baseline. The hook already fires `agent-prompt` and `agent-state waiting`;
a third command (`agent-state codex working submit`) uses the existing `submit`
`reason_src` branch which writes the `.start` file as a side effect. Alternative
rejected: adding a Codex-specific `UserPromptSubmit` equivalent — Codex has no such
hook event; `PermissionRequest` is the best available signal.

**D8 — Session tree title suffix carries the shortcut hints as a single string literal.**
The `open_session_tree` call passes `title` to `InputSelector`. Appending a bracketed
suffix to that string requires no API changes and no new UI surface. Alternative
rejected: a `description` field on each row — `InputSelector.description` adds a
separate rendered line per row, which would repeat for every row and be far noisier.

## Rollout & Gating

Each item is independently buildable; they share no cross-dependencies.

1. **Dead tabline cleanup**: `nix flake check` + `nh darwin build` green; no system
   change needed (tabline is read-only at runtime).
2. **Agent state in tab title**: build green; `nh darwin switch` + visual confirmation
   that working/waiting panes show an icon prefix.
3. **Notification dismiss**: build green; `nh darwin switch` + trigger an agent
   notification, click it, confirm the toast disappears immediately.
4. **Amp/agy/OpenCode hooks**: build green; `nh darwin switch` + start a task in each
   harness, confirm the state bus updates and a done notification fires.
5. **Codex session-start**: build green; `nh darwin switch` + run a quick Codex reply,
   confirm no done notification fires; run a long reply (>60 s), confirm one fires.
6. **Session tree hints**: build green; `nh darwin switch` + open `SUPER+s`, confirm
   the hint line appears in the picker title.

## Risks / Trade-offs

- **`pane.user_vars` field availability in `format-tab-title`**: WezTerm's
  `PaneInformation` table passes user vars as a plain table. If a future WezTerm
  version changes this (unlikely), the `pcall` guard degrades to no icon rather than
  crashing the tab title. Human-confirmed at the `nh darwin switch` checkpoint.
- **Amp hook keys**: Amp's hook surface is documented but not versioned. If key names
  change, the hooks silently do nothing (Amp ignores unknown keys). Mitigation: check
  `amp --version` at any Amp upgrade and re-verify hook names.
- **agy config path and hook keys**: agy (`pkgs.antigravity-cli`) may not yet have
  a Nix home-manager module or a stable config path. If the config location differs from
  `~/.config/agy/config.json`, the hook wiring has no effect. This is an Open Question.
- **OpenCode `hooks.session.end` timing**: OpenCode fires `session.end` on exit, which
  may or may not be reliable if the user force-quits or the session crashes. The
  best-effort contract (`agent-notify.sh` exits 0 on any failure) applies here.

## Migration Plan

1. Land all non-impactful items (dead tabline cleanup, Codex `.start` file, session tree
   hints) with `nh darwin build` green, then a single `nh darwin switch`.
2. Land agent-state tab prefix, notification dismiss, and harness hooks — all additive;
   reverse by removing the additions. Single `nh darwin switch` for the combined set.
3. Verify each item live per the Rollout & Gating checkpoints above.
4. Commit (title-only, conventional) and push to `main`.

## Open Questions

- **agy config location**: Does `pkgs.antigravity-cli` write its config to
  `~/.config/agy/config.json` or another path? Resolve by inspecting the package or
  running `agy --help` / checking `$XDG_CONFIG_HOME` behavior before wiring the hooks.
- **Amp `UserMessageSent` hook availability**: The `UserMessageSent` event may not be
  present in the current Amp release. Resolve by checking `amp` changelog or attempting
  a config write and watching for startup warnings.
