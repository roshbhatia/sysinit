## Why

Four gaps surfaced while hardening pi, and each has the same shape: a rule the
repository already holds somewhere, that nothing enforces at the layer where it
is broken.

1. **Chords are gated for three layers and not for the two that changed.**
   `checks/wezterm-chord-collisions.nix` spans symbolic hotkeys, aerospace, and
   WezTerm against `modules/darwin/lib/chords.nix`. pi and neovim are outside it.
   Measured cost: a sidebar toggle shipped on `alt+s`, which cannot fire, because
   WezTerm defaults `send_composed_key_when_left_alt_is_pressed` to true on macOS
   and nothing overrides it, so left-alt composes `ß`. Nothing failed. In the same
   pass `<leader>dt` was found bound twice in `codediff.lua`, to
   `view.toggle_explorer` and `conflict.accept_incoming`.

2. **citelock gates one change and no workflow.** The `citation-verification`
   skill and the `citelock` check exist and pass, but only
   `codify-responsible-llm-workflow` carries a `citations.lock`. The pre-commit
   gate is a no-op for a change that never captures a claim, so an
   external-factual claim reaches a proposal unpinned by default.

3. **openspec is visible to pi but not operable from it.** The sidebar reports
   the active change, its task counts, and artifact status. Acting on any of it
   means leaving the session for `openspec` and `specutil`. The read path is
   first-class and the write path is not.

4. **Six extensions hook `context` and nothing documents the composition.**
   `pi-subagents`, `@plannotator/pi-extension`, `pi-btw`, `pi-tool-display`,
   `@monotykamary/pi-vcc`, and `pi-context` all mutate or observe what reaches the
   model. Load order decides the result. A prior removal justified itself by
   calling `pi-dcp` "a third extension mutating the message list"; the true count
   was six, so the reasoning was wrong even though the removal may not have been.

## What Changes

- Extend the chord gate to pi and neovim, and make composing-modifier chords a
  build failure rather than a silent no-op.
- Register pi's chords in `modules/darwin/lib/chords.nix` so one registry covers
  every layer that binds a key.
- Make `citelock capture` reachable from the authoring loop, so pinning a claim is
  the cheap path rather than the diligent one.
- Surface `specutil next` and the openspec artifact gate as pi commands, so the
  sidebar's read path gains a matching write path.
- Record the `context`-hook order as declared data next to `piPackagePaths`, and
  assert the declared order matches what is installed.

### Non-goals

- Reviving a promoted requirement-spec corpus under `openspec/specs/`.
- Rewriting the sidebar to a WezTerm pane, or moving it left. The owner chose
  right-bound; the compositor narrows `terminal.columns` and cannot shift pi's
  origin, so left-binding needs a different architecture and a separate decision.
- Removing any pi package. `pi-annotated-reply` and `@juicesharp/rpiv-advisor` are
  removal candidates with evidence recorded; the decision stays with the owner.
- Making citelock mandatory for every change. A change with no external-factual
  claim must stay cheap.

## Behavior

Must do:
- A chord bound in a pi extension or a neovim keymap collides with a reserved
  chord, a symbolic hotkey, aerospace, or WezTerm, and the build fails, decided by
  the extended collision check.
- A chord whose modifier composes on macOS fails the check with the reason,
  decided by a fixture binding `alt+<letter>` while
  `send_composed_key_when_left_alt_is_pressed` is unset.
- The same mnemonic bound to two different meanings inside one plugin's keymap
  groups is reported, decided by the `<leader>dt` case as a regression fixture.
- A proposal carrying an external-factual claim without a matching
  `citations.lock` entry is rejected, decided by `specutil check` on a fixture.
- `specutil next` is reachable from pi without leaving the session, decided by the
  owner running it against a real change.
- The installed `context`-hook order matches the declared order, decided by a
  Nix assertion over `piPackagePaths`.

Must still hold:
- `nix flake check` and `nix build .#darwinConfigurations.lv426.system` exit 0.
- The permission gate keeps all 13 destructive deny globs under `yoloMode`.
- The sidebar keeps its current panels, width command, and OSC 8 file links.
- Nothing hand-written returns to `~/.pi/agent/extensions/`.
- openai model lists stay generated from pi's catalog, never declared in Nix.
