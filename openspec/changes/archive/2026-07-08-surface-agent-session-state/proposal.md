## Why

Multiple coding agents run in parallel across seshy sessions, but the only
persistent surface that shows their state is the tabline `agent_status`
component — and it shows *aggregate counts* (`◔ 1 waiting  ● 2 working`) with no
session, no reason, and no age. When an agent blocks on a permission prompt you
learn only that *something* is waiting; finding *which* session and *why* means
switching into each pane by hand. The seshy session switcher (`SUPER+s`) is the
natural place to see this — it already lists every session — but it renders bare
names and nothing else.

The information already exists and is thrown away twice over. `agent-notify.sh`
resolves the exact session·repo·pane and the harness's own reason string
("needs your permission to use Bash") on every `Notification`/`Stop` — then
discards it into a transient macOS toast. `agent-deck` reconstructs a coarse
working/waiting/idle by *scraping pane text*, which is fragile enough that it
already needed a patch (`agent-deck-idle-detection.patch`) and a stale-entry
pruner (`ui.lua:170`) to behave. Authoritative state is computed and dropped;
approximate state is reverse-engineered and surfaced.

## What Changes

- **Hooks emit authoritative per-pane state.** A new agent-agnostic `agent-state`
  script (sibling to `agent-notify.sh`, reusing its session·repo·pane identity
  resolution) emits an OSC 1337 `SetUserVar` to the pane tty on each lifecycle
  transition, stamping `status`, `reason`, `since`, and `agent`. Wired into the
  existing Claude (`UserPromptSubmit`/`PreToolUse`/`PostToolUse`/`Notification`/
  `Stop`) and Codex (`PermissionRequest`/`Stop`) hook sets in `claude.nix` /
  `codex.nix`, alongside the unchanged notifier. State lives in `pane.user_vars`,
  which WezTerm discards when the pane closes — so the count-never-decrements
  bug that forced `ui.lua:170`'s pruner *cannot occur* for hooked agents.
- **WezTerm rolls per-pane state up to per-session state.** A new shared Lua
  helper walks live panes, reads each pane's `agent_state` user-var (falling back
  to `agent-deck`'s scrape for panes that set none), groups by workspace
  (= seshy session name), and reduces to one state per session via worst-wins
  (`waiting > done > working > idle`) carrying the reason and the age since the
  worst transition.
- **The session switcher shows state.** The `wm.get_choices` override in
  `ui.lua` enriches each session's `label` with its rolled-up state icon,
  reason, and age, sorted so the longest-blocked session is on top.
- **The statusline names the blocked session.** The `tabline_y` `agent_status`
  component names the worst session and its age (`◔ auth-refactor 6m`) instead of
  a bare count, reading the same rollup.

### Non-goals

- **No persistent/cross-surface state store.** State is WezTerm-only via
  `user_vars`; no live-state file, no `sy status` integration, no ssh/tmux reach.
  (The `worklog.jsonl` precedent stays session-end-only; this is deliberately a
  separate, ephemeral concern.)
- **No removal of `agent-deck`.** It stays as the fallback detector for agents
  without lifecycle hooks (e.g. aider, cursor, opencode). Its scrape patch and
  pruner remain.
- **No new keybindings or new overlay UI.** The switcher and statusline are the
  surfaces; nothing new is summoned.
- **No per-turn transcript metadata or history.** Only live state is tracked.
- **No change to the notification/click-to-focus path.** `agent-notify` and
  `agent-focus` are untouched.

## Capabilities

### New Capabilities

- `agent-state-emission`: an agent-agnostic hook script that resolves
  session·repo·pane identity and emits per-pane lifecycle state to WezTerm via
  OSC 1337 `SetUserVar`, wired into each harness's lifecycle hooks.
- `agent-session-rollup`: a WezTerm-side helper that aggregates per-pane
  `agent_state` user-vars (with `agent-deck` fallback) into one worst-wins state
  per seshy session, carrying reason and age.
- `agent-aware-switcher`: the seshy session switcher renders each session's
  rolled-up state, reason, and age, sorted by urgency.
- `agent-aware-statusline`: the tabline agent-status component names the worst
  blocked session and its age instead of an aggregate count.

### Modified Capabilities

<!-- none: no archived wezterm/agent specs exist in openspec/specs/ -->

## Impact

- **New files**: `modules/home/programs/llm/config/agent-state.sh` (emitter,
  follows `agent-notify.sh`), its `pkgs.writeShellApplication` wrapper in
  `notify.nix` (follows the existing `script`/`focusScript` pattern), and a
  WezTerm rollup helper (new function in `pkg/ui.lua` or a small `pkg/`
  sibling, following `agent_status()` at `ui.lua:196`).
- **Modified files**: `modules/home/programs/llm/config/claude.nix` and
  `codex.nix` (add `agent-state` to existing hook arrays), `notify.nix` (export
  the new script), `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`
  (rollup helper, `agent_status()` rewrite, `wm.get_choices` label enrichment).
- **Progressive rollout**: the four capabilities are independent vertical
  slices. Emission + rollup land first (no visible change until a surface reads
  it); switcher and statusline are separate, each shippable alone.
- **Impactful actions** (become human-verification checkpoints in `tasks.md`):
  - `nh darwin switch` — applies the new hooks/scripts to the live system.
  - `git push` to `main` — this repo commits straight to main.
- **Gating signal**: `nix flake check` → `nh darwin build` (no system change) →
  user spot-check in a live WezTerm → `nh darwin switch`. OSC-to-tty behavior
  under Claude's alt-screen TUI is the one item that can only be confirmed live.
