## Why

Four independent producers raise agent notifications and none of them agree.
`agent-notify` uses `alerter` for claude and codex. The agent-deck WezTerm
plugin raises native toasts for seven harnesses by screen-scraping. Pi ships an
OSC 777 toast from its own `notify.ts`. OpenCode 1.18 carries an `attention`
block that this repo does not manage. Claude can therefore be announced twice
for one wait, while pi and opencode never reach the state bus at all.

Four defects are live today, not merely missing features.

## What Changes

- Make `agent-notify` the only desktop-toast producer. Turn off agent-deck
  notifications, turn off opencode's `attention.notifications`, and drop pi's
  vendored `notify.ts`.
- Bridge pi and opencode onto the same notifier and the same state bus. Pi gets
  a local extension. OpenCode gets a local plugin. Both call the existing
  `agent-notify` and `agent-state` executables.
- Fix the group-prefix mismatch. `agent-prompt` writes the group
  `agent-prompt:<agent>:<context>` and `agent-focus` removes
  `agent-notify:<agent>:<context>`, so an approval toast is never dismissed.
- Fix the idle dedup key. It is keyed on the agent name alone, so a second
  claude pane stays silent for five minutes after the first one pings.
- Make an approval toast clickable. `agent-prompt` treats `@CONTENTCLICKED` as
  a no-op, so clicking the body of an approval notification does nothing.
- Ship one icon per harness. `agent.png` is a copy of `claude.png`, so seven
  harnesses render as Claude.
- Carry repo, branch, dirty, and elapsed time into the toast body. The state
  file already holds all four.

### Non-goals

- The state-file schema, its version field, and stale-entry collection. Those
  belong to `harden-agent-shell-terminal`, which is in progress.
- Mirroring agent bash output into a pane. That belongs to
  `wezterm-command-console`.
- Adding a harness. This change covers the eleven already configured.
- Replacing `alerter`. The backend stays as it is.
- Notification delivery on NixOS. `alerter` is macOS-only and the current
  no-op behavior on other platforms is preserved.

## Capabilities

### New Capabilities

- `agent-notification-routing`: one producer, one reason vocabulary, per-pane
  dedup, per-harness icons, and an actionable approval path.

### Modified Capabilities

- `agent-state-emission`: the wiring requirement names only claude and codex.
  It must name pi and opencode, and it must state that a harness with no
  lifecycle hook contributes nothing rather than a stale entry.
- `pi-extension-config`: its extension-list requirement enumerates a fixed
  roster that includes `notify`. Removing that producer falsifies the roster,
  so the requirement must drop the enumeration and state the exclusion rule
  instead.

## Impact

Modified code:
- `modules/home/programs/llm/config/notify.nix`
- `modules/home/programs/llm/config/agent-notify.sh`
- `modules/home/programs/llm/config/agent-prompt.sh`
- `modules/home/programs/llm/config/agent-focus.sh`
- `modules/home/programs/llm/config/pi.nix`
- `modules/home/programs/llm/config/opencode.nix`
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua`

New code:
- `modules/home/programs/llm/config/extensions/sysinit-notify.ts` (pi)
- `modules/home/programs/llm/config/plugins/sysinit-notify.ts` (opencode)

Dependencies:
- Depends on `harden-agent-shell-terminal` for the versioned state-file schema.
  This change reads the bus and must not redefine its shape.
- Phase 3 depends on `modernize-opencode-and-pi-config` phase 1, which creates
  the OpenCode TUI config writer. `attention.notifications` is a TUI key and
  `opencode.nix` has no TUI writer today. Building a second one here would race
  the first on the same file.
- Three new icon sources fetched by `pkgs.fetchurl` with pinned hashes,
  following the existing `notify.nix` icon block. amp, crush, goose, and devin
  get the generic glyph instead: no correct brand asset exists for them.

Impactful and irreversible actions:
- `nh darwin switch` applies the notification change to the live machine.
- Removing pi's `notify.ts` from the vendored extension list changes pi's
  runtime behavior on the next pi start.

Gating signal:
- `nix flake check`, then `nh darwin build`, then an owner smoke test of one
  toast per harness, then `nh darwin switch`. Each phase is independently
  switchable. The kill switch for the bridges is removing the pi extension file
  and the opencode plugin entry, which restores today's behavior for those two
  harnesses without touching the other nine.
