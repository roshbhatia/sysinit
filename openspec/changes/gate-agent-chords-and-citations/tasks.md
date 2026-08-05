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

## 6. OpenSpec as a first-class, global workflow

- **SHAPE** graph

- [x] 6.1 Rename the schema from `spec-driven` to `spec-driven`, replacing
      the built-in directory instead of sitting beside it. Attempted and reverted:
      the openspec half is clean and deletes all six `--replace-fail` patches in
      `overlays/openspec/default.nix`, but `spec-driven` is a preset name
      compiled into the specutil binary, which has no source in this repo. With
      the schema renamed, `specutil check` resolves no rubric and every change
      loses its gate. Needs a coordinated specutil change first, or an explicit
      `check:` block in `openspec/specutil.yaml` that reproduces the preset
      exactly `deps:` 1.1

      Done, both halves. specutil is ours, so it was fixed at the source rather
      than worked around: `internal/check/presets.go` and
      `internal/extract/extract.go` now key on `spec-driven`, with an `aliases`
      table so archived changes pinning the retired name still resolve, and a
      test asserting an alias can never shadow a real preset (specutil 932308f).
      The overlay then replaced the built-in schema directory instead of sitting
      beside it, deleting all six `--replace-fail` patches against upstream's
      prebuilt dist/. Archives and openspec/specs were left alone: they are
      history, and rewriting them to chase a rename would falsify the record.
- [ ] 6.2 Install the openspec skills and prompts globally for every harness, so
      no repo needs `openspec init`. Upstream ships `pi` as a first-class tool
      (`.pi/skills/openspec-*/SKILL.md`, `.pi/prompts/opsx-<id>.md`), `codex` and
      `agents` share `.agents/skills/`, and `opencode` uses `.opencode/skills/`.
      Nix owns those roots already `deps:` 6.1
- [ ] 6.3 Onboard the new opsx skills (`propose`, `explore`, `apply`, `update`,
      `sync`, `archive`, and the expanded `new`/`continue`/`ff`/`verify`/
      `bulk-archive`/`onboard`) into the generated skill set `deps:` 6.2
- [x] 6.4 Audit the schema itself against upstream's customization contract:
      `openspec/config.yaml` supports a default schema, injected context,
      per-artifact rules, and operation guidance. Confirm each is set and
      correct, and that the language matches the output style `deps:` 6.1

      Done. `ProjectConfigSchema` accepts exactly `schema`, `context`, `rules`
      (artifact id to string list), and `store`, plus normalized `references`.
      Only `schema` and `context` were set, so `rules` was entirely unused and no
      per-artifact guidance reached any author. Added 11 rules across proposal,
      design, and tasks, each drawn from a failure this repo actually hit, and
      refreshed the context, which listed three harnesses out of seven and omitted
      both the gates and the apply path.

      One trap, found by validating rather than assuming: openspec IGNORES a
      config it cannot parse and only warns. An unquoted rule containing a colon
      broke the YAML and silently dropped `schema:` with it, leaving the repo on
      defaults. Every rule with a colon is now quoted and config.yaml says why.
- [ ] 6.5 Evaluate stores and worksets (beta) for seshy: a store is a standalone
      planning repo, registered per machine, referenced from a code repo via
      `store:` or read-only `references:` in config.yaml. seshy already manages
      multi-repo sessions, so the question is whether a workset is the same
      object under another name or a layer beneath it `deps:` 6.1
- [x] 6.6 Move every agent's shell back to its default instead of zsh. The owner
      reports zsh causes issues; `shellCommandPrefix` and `shellPath` are the pi
      levers, and the other harnesses have equivalents `deps:` none

      Done. Three harnesses pinned it, not one: `CLAUDE_CODE_SHELL`, codex's
      `shell_environment_policy.set.SHELL`, and opencode's `shell`. All unset. pi
      was never pinned; its `shellCommandPrefix` only sources aliases.
- [ ] 6.7 Adversarial review: whether global install makes openspec present or
      merely installed, and whether 6.1 is worth its coordination cost `deps:` 6.5, 6.6

## 7. Continual harness

- **SHAPE** graph

- [x] 7.1 Adopt prime-agent's Continual Harness split. It is built on pi, and its
      durable idea is that supplemental state (memories, skills, subagent specs)
      is refined from evidence while the base prompt stays immutable. That split
      already exists here, `instructions.nix` immutable against
      `~/.claude/projects/*/memory/` mutable, but nothing refined the mutable
      half, so it only grew. `agent-refine` reads a bounded worklog window and
      writes a proposal, and a weekly launchd agent runs it unattended.

      It proposes and never applies, deliberately. The owner's own rules say
      model output is a draft until evidence verifies it and that approval is
      never claimed on their behalf; a job that rewrote memory unattended would
      break both. `StartCalendarInterval` rather than `StartInterval`, because a
      7-day window re-proposes the same items if it fires after every reboot.
      Rejected from prime-agent: RLM subagent spawning (pi-subagents covers it),
      daemon-backed sessions (seshy covers it), persistent IPython (wrong shape
      for a Nix-managed config) `deps:` none
- [ ] 7.2 Verify the first refine run produces a report whose every claim cites
      worklog evidence, and that a run with an empty window exits 0 without
      publishing a file `deps:` 7.1
- [ ] 7.3 Evaluate an openspec store for the sysinit constellation. `store:` and
      `references:` are real keys in `ProjectConfigSchema`, so the wiring exists.
      The case for one is concrete: this work spans sysinit, sysinit.laurel, and
      specutil, and the change describing it can only live in one of them today.
      The case against is that stores are beta and upstream says file formats may
      still change. Decide adopt-now against wait `deps:` 7.1
- [ ] 7.4 Decide how seshy relates to worksets. A seshy session already groups
      repos for one feature and a workset is a personal multi-folder view, so the
      question is whether they are the same object named twice. If they are,
      seshy should emit the store reference rather than both tracking it `deps:` 7.3
- [ ] 7.5 Adversarial review: whether an unattended refine that only proposes is
      actually read, or becomes a weekly file nobody opens `deps:` 7.2, 7.4
