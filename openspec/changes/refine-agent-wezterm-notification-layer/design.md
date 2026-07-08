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
- Audit non-Claude harness lifecycle hooks and keep only documented, harness-specific
  hook config.
- Fix Codex hook errors by using one hook representation, removing unsupported `async`,
  and wiring `UserPromptSubmit` instead of overloading `PermissionRequest`.
- Fix per-harness MCP/config paths and field names for Copilot, Cursor, Antigravity,
  OpenCode, Amp, and Crush.
- Make OpenSpec workflow globally available through managed skills and a Codex plugin.
- Make session tree shortcut filter keys discoverable without external documentation.

**Non-Goals:**
- No guessed harness instrumentation for Amp, agy, or OpenCode until stable hook
  surfaces are documented.
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

**D4 — Do not wire guessed hooks for Amp, agy, or OpenCode.**
The docs/binaries checked during the audit do not expose stable lifecycle hook keys for
these harnesses. Adding guessed keys would either be ignored or produce startup warnings.
Alternative rejected: porting Claude hook names into each config file — that was the
source of the Codex errors and is not a valid cross-harness abstraction.

**D5 — Codex hooks use the Codex event model, not the Claude one.**
Codex documents `UserPromptSubmit`, `PermissionRequest`, and `Stop`. The turn-start
state belongs on `UserPromptSubmit`; `PermissionRequest` should only represent approval
or waiting state. Codex 0.142.x warns that async hooks are unsupported, so Codex hook
entries deliberately omit `async`. Alternative rejected: keeping both TOML hooks and
`~/.codex/hooks.json` — Codex loads both and warns about duplicate hook layers.

**D6 — MCP formatters are per harness.**
Copilot CLI expects `~/.copilot/mcp-config.json` and local servers with `type = "local"`;
Cursor Agent expects `~/.cursor/mcp.json`; Antigravity remote servers use `serverUrl`;
OpenCode accepts URL-based remote entries; Crush needs `global_context_paths` to point at
the managed instructions file. Alternative rejected: reusing `formatForClaude` and
assuming unknown fields are harmless.

**D7 — OpenSpec workflow is global configuration.**
The repo already installs `openspec` and `specutil`; the workflow guidance should live in
managed global skills and a Codex plugin. `openspec init` remains a project artifact
initializer, not a prerequisite for agent commands or skills. Alternative rejected:
depending on `.claude/commands/opsx/*` generated inside each repo.

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
4. **Harness config audit**: build green; inspect generated JSON/TOML paths for Copilot,
   Cursor, Antigravity, OpenCode, Amp, Crush, and Codex.
5. **Codex hooks**: build green; `nh darwin switch` + confirm Codex starts without hook
   layer, unsupported async, or hook exit warnings.
6. **Session tree hints**: build green; `nh darwin switch` + open `SUPER+s`, confirm
   the hint line appears in the picker title.

## Risks / Trade-offs

- **`pane.user_vars` field availability in `format-tab-title`**: WezTerm's
  `PaneInformation` table passes user vars as a plain table. If a future WezTerm
  version changes this (unlikely), the `pcall` guard degrades to no icon rather than
  crashing the tab title. Human-confirmed at the `nh darwin switch` checkpoint.
- **Docs can drift again**: harness config surfaces are moving quickly. Mitigation:
  keep each formatter named for the harness and re-audit that file against docs when a
  harness is upgraded.
- **Codex plugin support may evolve**: the local OpenSpec plugin is intentionally small
  and contains only a skill. If plugin packaging changes, global shared skills still
  provide OpenSpec guidance to the other harnesses.

## Migration Plan

1. Land all non-impactful items (dead tabline cleanup, Codex hook cleanup, session tree
   hints) with `nh darwin build` green, then a single `nh darwin switch`.
2. Land agent-state tab prefix, notification dismiss, and harness config/MCP fixes — all
   additive; reverse by removing the additions. Single `nh darwin switch` for the combined set.
3. Verify each item live per the Rollout & Gating checkpoints above.
4. Commit (title-only, conventional) and push to `main`.

## Open Questions

- **Amp/agy/OpenCode lifecycle hooks**: Leave unwired until a stable documented hook
  surface exists. Revisit during the next harness upgrade audit.
