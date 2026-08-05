## 1. Discovery

- **SHAPE** graph

- [x] 1.1 Inventory every chord-binding layer: `modules/darwin/lib/chords.nix`,
      `keybindings.nix`, wezterm `keybindings.lua` and `ui.lua`, pi extensions and
      `piKeybindings`, neovim keymaps, hammerspoon, sketchybar, zsh ZLE. Record
      which the current check reads and which it does not

      Found. The check reads `reservedChords`, `baseSymbolicHotkeys`, the wezterm
      lua root, and a hand-written `uiChords` list. Binding-site counts:
      `ui.lua` 33, `chords.nix` 22, pi `default.nix` 8, wezterm
      `keybindings.lua` 3, `keybindings.nix` 2, pi extensions 2, neovim 86.
      hammerspoon, sketchybar, and zsh ZLE bind zero chords, which bounds the
      work to four real layers, not seven.

      Two gaps, not one. Neovim is the largest surface at 86 sites and is
      entirely ungated. But `uiChords` declares 11 chords against 33 literals in
      `ui.lua`, and the check's own comment admits it is kept in step by hand
      because ui.lua cannot load under the stub. So the existing gate is already
      partly fictional for a layer it claims to cover. Phase 2 has to fix the
      extraction, not only widen it.
- [ ] 1.2 Determine how neovim keymaps can be extracted without loading the full
      config. `checks/lua-parses.nix` already parses them; the chord check needs
      the bound keys, not just parseability `deps:` 1.1
- [ ] 1.3 Confirm whether WezTerm's compose behaviour is detectable from config
      alone, or whether the check must treat every `alt+<key>` as failing until
      `send_composed_key_when_left_alt_is_pressed = false` is set `deps:` 1.1
- [ ] 1.4 Read `citelock capture` and the `citation-verification` skill, and
      record the smallest authoring step that pins a claim `deps:` 1.1
- [ ] 1.5 Adversarial review: whether the inventory is complete. A layer missed
      here is a layer the gate will not cover, which is the defect this change
      exists to fix `deps:` 1.4

## 2. Chord registry

- **SHAPE** graph

- [ ] 2.1 Extend `modules/darwin/lib/chords.nix` with a pi layer, sourced from the
      extensions rather than hand-copied, so it cannot drift the way `uiChords`
      already does `deps:` 1.1
- [ ] 2.2 Extend `checks/wezterm-chord-collisions.nix` to consume the pi and
      neovim layers. Rename it: it is no longer WezTerm-specific `deps:` 2.1, 1.2
- [ ] 2.3 Add the composing-modifier rule with its reason string `deps:` 2.2, 1.3
- [ ] 2.4 Add fixtures: `alt+s` under default compose, `<leader>dt` bound twice,
      and one accepted overlap. Each must fail or pass for its stated reason, not
      incidentally `deps:` 2.3
- [ ] 2.5 STOP: mutation-test the check. Reintroduce `alt+s` and the duplicate
      `<leader>dt` against the committed tree and confirm both fail `deps:` 2.4
- [ ] 2.6 Adversarial review: critics attack the fixtures, not the check. A gate
      that passes because its fixture is wrong is worse than no gate `deps:` 2.5

## 3. Citations in the loop

- **SHAPE** graph

- [ ] 3.1 Make `citelock capture` reachable from pi as a command, so pinning a
      claim does not require leaving the session `deps:` 1.4
- [ ] 3.2 Confirm `specutil check` rejects an unpinned external-factual claim, and
      add the fixture if it does not `deps:` 1.4
- [ ] 3.3 Confirm a change with no external-factual claim stays cheap: no lock
      file, no new gate output `deps:` 3.2
- [ ] 3.4 Adversarial review: whether a cheap capture path makes unpinned claims
      rarer, or only makes pinning look done `deps:` 3.3

## 4. openspec as a write path

- **SHAPE** graph

- [ ] 4.1 Register `specutil next` as a pi command returning the runnable subtasks
      for the active change `deps:` 1.1
- [ ] 4.2 Decide whether the sidebar's OpenSpec panel should link its artifacts via
      OSC 8, reusing `link()`/`fileUri()` from the Changes panel `deps:` 4.1
- [ ] 4.3 Declare the `context`-hook order next to `piPackagePaths` and assert the
      installed set matches it, so the composition is data rather than
      load-order accident `deps:` 4.1
- [ ] 4.4 Verify diffnote end to end on a real dirty tree: `ctrl+b` opens the
      split, pi writes notes through `diffnote apply --stdin`, the store validates,
      neovim renders them as virt_lines, and `stop()` clears every drawn buffer.
      `checks/diffnote-roundtrip.nix` covers the CLI, not the chord-to-render
      path `deps:` 4.1
- [ ] 4.5 Adversarial review: whether each new pi command earns its surface, and
      whether the declared hook order matches observed behaviour `deps:` 4.4

## 5. Rollout

- **SHAPE** sequence

- [ ] 5.1 Apply: `nh darwin switch . --update` from the `sysinit.laurel` checkout
      in a split pane, gated on `nix flake check` and
      `nix build .#darwinConfigurations.lv426.system` exiting 0 `deps:` 2.5, 3.3, 4.4
- [ ] 5.2 Confirm: the owner presses `shift+ctrl+b` and the sidebar toggles,
      presses `ctrl+b` and reads a left-hand tree explorer, ctrl+clicks a path in
      the Changes panel and it opens `deps:` 5.1
- [ ] 5.3 Confirm: the owner runs the new pi commands against a real change and
      judges whether the write path is worth its surface `deps:` 5.1
- [ ] 5.4 Decide: the owner rules on `pi-annotated-reply` and
      `@juicesharp/rpiv-advisor`, whose removal evidence is recorded in
      `piPackagePaths` comments, and on the stale `mcp-cache.json` `deps:` 5.3
