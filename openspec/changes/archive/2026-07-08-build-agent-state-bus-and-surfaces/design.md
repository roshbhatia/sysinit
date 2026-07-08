## Context

The archived `surface-agent-session-state` change already ships a working
WezTerm-only attention system:

- `modules/home/programs/llm/config/agent-state.sh` emits per-pane state as an
  OSC 1337 `SetUserVar=agent_state=<base64>` (`status|reason|since|agent`).
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` holds
  `agent_session_states()` (rollup, ~line 223), `worst_agent_session()` (~284),
  `agent_status()` (statusline, ~302), and the `wm.get_choices` switcher (~614).
  The tabline is configured with `tabs_enabled = false` (ui.lua:324),
  `tab_bar_at_bottom = true` (ui.lua:41), sections `tabline_a`,
  `tabline_y = { agent_status }`, `tabline_z`.
- `agent-notify.sh` + `agent-focus.sh` provide a clickable toast that raises the
  exact pane; `notify.nix` builds per-agent PNG icons and exports
  `exe`/`stateExe`/`focusExe` via `pkgs.writeShellApplication` (best-effort,
  `bashOptions = [ ]`).
- Hooks are wired in `claude.nix` and `codex.nix` via `notify.stateExe`.

The ceiling of that design is that state lives only in WezTerm user-vars. This
change extends the *same* scripts and the *same* rollup rather than paralleling
them: `agent-state.sh` grows a second transport, `ui.lua`'s existing rollup
grows a per-pane view, and the existing switcher/statusline components grow
fields. The one genuinely new external dependency is `alerter`, chosen because
`terminal-notifier` (already a `runtimeInput` in `notify.nix`) cannot reliably
return a clicked action.

## Goals / Non-Goals

**Goals:**

- Make agent state readable outside WezTerm via a per-pane JSON state file — the
  cross-surface bus every future consumer (neovim, `sy`, neph) subscribes to.
- Navigate to the exact blocked pane (not just session) in one keystroke,
  including throwaway agents in sibling tabs.
- Put a clickable per-tab attention indicator in the tab bar.
- Let a notification resolve a permission prompt (Accept/Deny) without switching
  to the pane.
- Keep every slice independently buildable and reversible.

**Non-Goals:**

- The neovim consumer (lives in `sysinit.nvim`), `sy status` integration, neph
  wiring, and a quota segment — all out of scope, all future consumers of the
  bus this change produces.
- Changing the existing OSC emission format or the click-to-focus path.

## Decisions

### D1: Per-pane JSON file at `~/.local/state/agents/panes/<pane>.json`

Second transport is a file keyed by WezTerm pane id, written atomically
(temp + `mv`). Readers key on pane id and intersect with `wezterm cli list` for
liveness.

- **Alternative — single append-only JSONL / socket daemon**: rejected. A daemon
  adds a lifecycle to supervise and a socket to manage; the file-per-pane model
  is stateless, self-partitioning (pane id = filename), and needs no pruning
  because liveness is derived from live panes — matching the existing
  "no pruning required" property of the user-var rollup.
- **Alternative — reuse the OSC user-var only**: rejected; it is the exact
  limitation being removed (unreadable outside WezTerm).
- **Pane id over session as the key**: a session has many panes (throwaway
  tabs); keying by pane preserves the per-pane precision the jump needs.

### D2: `alerter` over `terminal-notifier` on the actionable path

`terminal-notifier` cannot reliably block and return a chosen action;
`vjeantet/alerter` is a fork built precisely to print the clicked action/reply
to stdout and block for it.

- **Alternative — terminal-notifier `-execute`**: rejected. `-execute` runs a
  fixed command on the single click; it cannot express a two-choice Accept/Deny
  nor return which was chosen.
- **Alternative — swap the whole notifier to alerter**: rejected for blast
  radius; keep `terminal-notifier` for fire-and-forget `done`/info toasts and
  use `alerter` only where a decision exists, so the common path is unchanged.
- **Packaging**: `alerter` is not in nixpkgs. Package it as a darwin-only
  derivation that installs the pinned prebuilt release binary via hash-locked
  `fetchurl`, mirroring how `notify.nix` already hash-pins fetched assets. This
  keeps it out of the fragile "build a macOS app bundle from source" path.

### D3: Keystroke relay via `wezterm cli send-text`, toggle-gated

Accept/Deny is relayed into the recorded pane with per-agent approve/reject
keystrokes. This is the same `wezterm cli` surface the config already uses in
neovim's bridge and `agent-focus.sh`.

- **Alternative — an agent-native API (e.g. Claude/Codex RPC to answer a
  prompt)**: rejected for now; no stable cross-harness API exists, and the
  harnesses differ. Keystroke relay is the lowest-common-denominator that works
  for any TUI, at the cost of fragility.
- **Mitigation for fragility**: a single config toggle is the kill switch;
  agents without a defined keymap are skipped; all failures are best-effort
  no-ops. This mirrors the existing best-effort posture (`exit 0` everywhere).

### D4: Extend the existing rollup, add `worst_agent_pane()`

Keep `agent_session_states()` producing the session map; add a per-pane view and
`worst_agent_pane()` from the *same* single live-pane walk.

- **Alternative — read the new state files in Lua for the rollup**: rejected on
  the render path. The rollup runs every `update-status` tick and must not do fs
  reads or shell-outs (an existing spec constraint); user-vars stay the WezTerm
  render source. The state files serve *out-of-WezTerm* consumers, not the
  tabline.

### D5: `SUPER+g` jump, `SUPER+SHIFT+g` picker

Both are free (`CTRL+g` is the unrelated locked-mode toggle at
`keybindings.lua:417`); they sit naturally beside the existing `SUPER+s`
switcher / `SUPER+SHIFT+s` ssh picker convention.

- **Alternative — overload `SUPER+s`**: rejected; the switcher is
  session-granular and mixing a pane-jump into it muddies both.

### D6: Flip `tabs_enabled = true` with a custom tab component

- **Alternative — keep tabs disabled, encode per-tab state in the statusline**:
  rejected; the statusline can't be clicked and can't disambiguate *which* tab.
  Native click-to-switch tab titles are the only clickable per-tab affordance
  WezTerm offers.

## Rollout & Gating

Default dotfiles gate applies, adjusted for this host: edit →
`nix flake check` → **`nh darwin build`** (not `nh os`) → user live spot-check →
`nh darwin switch`. Each slice below is built and (where visible) spot-checked
before the next:

1. **`agent-state-bus`** — add the file transport + shared resolver to
   `agent-state.sh`/`agent-notify.sh`. Additive and invisible; gate on
   `nh darwin build` and inspecting a written JSON file.
2. **`agent-session-rollup`** — per-pane view + `worst_agent_pane()` in
   `ui.lua`. No surface reads it yet; gate on build.
3. **`wezterm-agent-jump`** — `SUPER+g` / `SUPER+SHIFT+g`. Gate on build + live
   jump test.
4. **`per-tab-agent-state`** — flip `tabs_enabled`, add the tab component. Gate
   on build + live tab-bar check (visual regression risk).
5. **richer `agent-aware-switcher` + `agent-aware-statusline`** — extra fields.
   Gate on build + live `SUPER+s`/statusline check.
6. **`actionable-notifications`** — package `alerter`, swap the permission path,
   add the relay behind its toggle. Highest risk; ships last; gate on build +
   live Accept/Deny test with the toggle on.

**Kill switches**: the state-file write is additive (delete the write to
revert); the relay has an explicit config toggle; `tabs_enabled` reverts to
`false`; each keybind/component can be removed independently.

## Risks / Trade-offs

- **[Keystroke relay is agent-specific and fragile]** → toggle-gated kill
  switch, per-agent keymap with skip-on-unknown, best-effort no-op on any
  failure. Human-verification checkpoint in tasks.md (live Accept/Deny test).
- **[Vendored `alerter` binary — supply chain + drift]** → hash-pinned
  `fetchurl` of a specific release; build fails loudly on drift, same posture as
  the pinned icon assets. Human checkpoint: confirm the packaged binary runs.
- **[OSC-to-tty + user-var read under Claude's alt-screen TUI]** → unchanged
  from the shipped design but re-confirmed live for the new per-tab component
  and the state-file enrichment. Human checkpoint.
- **[`tabs_enabled = true` visual regression]** → spot-check the tab bar; revert
  the flag if it crowds the bar. Human checkpoint.
- **[State-file staleness]** → consumers intersect with live pane ids; cleanup
  is best-effort only, and the spec forbids correctness depending on it.
- **[Blocking `alerter` stalling a hook]** → the alert and waiter run detached;
  the hook returns immediately.

## Migration Plan

This is additive config, applied via `nh darwin switch`; rollback is reverting
the slice and re-switching. Impactful steps each get a verify-before /
confirm-after:

1. **Verify** `nix flake check` + `nh darwin build` green for slices 1–5.
2. **Apply** `nh darwin switch` (mutates the live system). **Confirm**: state
   files appear under `~/.local/state/agents/panes/`, `SUPER+g` jumps, tab bar
   shows per-tab icons, switcher/statusline show the new fields.
3. **Verify** the `alerter` derivation builds and the binary runs standalone.
4. **Apply** slice 6 via `nh darwin switch` with the relay toggle on.
   **Confirm** live: Accept approves and Deny rejects in the target pane; toggle
   off restores click-to-focus only.
5. **Publish (impactful)**: commit (conventional, title-only) and `git push` to
   `main` — only on explicit user direction.

## Open Questions

- Should throwaway-tab agents carry equal rollup weight, or should the primary
  tab be weighted / `done` decay applied so throwaway `done` prompts don't nag?
  Deferred as a fast-follow; noted in the proposal non-goals.
- Exact per-agent approve/reject keystrokes for Claude vs Codex — to be pinned
  during slice 6 against the live TUIs.
- Whether `sy` should later write its own session-level rollup file so consumers
  needn't re-derive sessions from pane files — a `sysinit.nvim`/seshy concern.
