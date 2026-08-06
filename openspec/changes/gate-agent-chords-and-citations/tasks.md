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
- [x] 1.2 Determine how neovim keymaps can be extracted without loading the full
      config. `checks/lua-parses.nix` already parses them; the chord check needs
      the bound keys, not just parseability `deps:` 1.1

      Answer: do not load at all, read the source text. extract.lua loads
      keybindings.lua under a stub and that cannot extend to ui.lua, which dies at
      module scope pulling in tabline, lantern, and workspace-manager. Static
      extraction covers wezterm lua, neovim lua, and pi TypeScript with one
      mechanism and no stub per module. It cannot see a chord assembled from
      variables at runtime, so it is a floor on coverage, not a ceiling.
- [x] 1.3 Confirm whether WezTerm's compose behaviour is detectable from config
      alone, or whether the check must treat every `alt+<key>` as failing until
      `send_composed_key_when_left_alt_is_pressed = false` is set `deps:` 1.1

      Detectable. The check greps the wezterm lua root for that option set false
      and lifts the rule when it finds it, so the gate follows the config instead
      of hardcoding an assumption about macOS.
- [ ] 1.4 Read `citelock capture` and the `citation-verification` skill, and
      record the smallest authoring step that pins a claim `deps:` 1.1
- [ ] 1.5 Adversarial review: whether the inventory is complete. A layer missed
      here is a layer the gate will not cover, which is the defect this change
      exists to fix `deps:` 1.4

## 2. Chord registry

- **SHAPE** graph

- [x] 2.1 Extend `modules/darwin/lib/chords.nix` with a pi layer, sourced from the
      extensions rather than hand-copied, so it cannot drift the way `uiChords`
      already does `deps:` 1.1
- [x] 2.2 Extend `checks/wezterm-chord-collisions.nix` to consume the pi and
      neovim layers. Rename it: it is no longer WezTerm-specific `deps:` 2.1, 1.2
- [x] 2.3 Add the composing-modifier rule with its reason string `deps:` 2.2, 1.3
- [x] 2.4 Add fixtures: `alt+s` under default compose, `<leader>dt` bound twice,
      and one accepted overlap. Each must fail or pass for its stated reason, not
      incidentally `deps:` 2.3
- [x] 2.5 STOP: mutation-test the check. Reintroduce `alt+s` and the duplicate
      `<leader>dt` against the committed tree and confirm both fail `deps:` 2.4

      Five mutations against the committed tree. Caught: `alt+s` reintroduced in
      pi, pi binding the reserved `cmd+space`, pi binding one chord twice, and
      breaking the load-bearing extraction pattern. NOT caught at first: breaking
      the `registerShortcut` pattern, because the generic literal pattern covers
      the same chords and the pi floor of 2 was slack enough to absorb it. Floors
      raised to just under the real counts (12/93/3) and the mutation then failed
      correctly. A slack floor tests nothing.
- [x] 2.6 Adversarial review: critics attack the fixtures, not the check. A gate
      that passes because its fixture is wrong is worse than no gate `deps:` 2.5

      This is where the check earned its shape. Three rules were proposed and one
      was withdrawn after its own candidates were checked against source.

      Withdrawn: a same-file duplicate rule for neovim. Every candidate it raised
      was legitimate. gitsigns binds `<leader>ghs` in normal and visual mode;
      fyler and trouble both take `<C-t>` in their own buffers. A neovim mapping
      is keyed by chord AND mode AND buffer, and static extraction sees only the
      chord. Reporting those would bury a real find under noise and teach the
      owner to ignore the gate. neovim is still extracted for the alt rule and
      the coverage floor.

      Also withdrawn by evidence: lower-casing chords. `<leader>cL` and
      `<leader>cl` are different vim mappings, and merging them invented a
      collision in lsp-lines.lua that does not exist. Only the modifier letter is
      normalised now, because `<C-t>` and `<c-t>` genuinely are the same.
      Terminal-style chords still normalise fully, since pi's own files carry
      both `ctrl+shift+r` and `shift+ctrl+b` for what would be one chord.

## 3. Citations in the loop

- **SHAPE** graph

- [x] 3.1 Make `citelock capture` reachable from pi as a command, so pinning a
      claim does not require leaving the session `deps:` 1.4
- [x] 3.2 Confirm `specutil check` rejects an unpinned external-factual claim, and
      add the fixture if it does not `deps:` 1.4
- [x] 3.3 Confirm a change with no external-factual claim stays cheap: no lock
      file, no new gate output `deps:` 3.2
- [x] 3.4 Adversarial review: whether a cheap capture path makes unpinned claims
      rarer, or only makes pinning look done `deps:` 3.3

      The guarantee is real and the first implementation was not. `citelock
      capture` was tested against a quote no source states and failed closed:
      "quote does not anchor in fetched content". So a cheap capture path cannot
      make pinning merely look done; a captured claim is anchored or there is no
      capture.

      But `/cite` ran a bare `citelock capture`, which cannot work. Capture takes
      a URL plus --id/--quote/--class, and bare it exits "capture requires a
      URL". The command would have errored every time while looking like the
      capture step existed and was merely failing, which is worse than not having
      it. Arguments now pass through, with usage on an empty invocation.

## 4. openspec as a write path

- **SHAPE** graph

- [x] 4.1 Register `specutil next` as a pi command returning the runnable subtasks
      for the active change `deps:` 1.1
- [ ] 4.2 Decide whether the sidebar's OpenSpec panel should link its artifacts via
      OSC 8, reusing `link()`/`fileUri()` from the Changes panel `deps:` 4.1
- [x] 4.3 Declare the `context`-hook order next to `piPackagePaths` and assert the
      installed set matches it, so the composition is data rather than
      load-order accident `deps:` 4.1
- [x] 4.4 Verify diffnote end to end on a real dirty tree: `ctrl+b` opens the
      split, pi writes notes through `diffnote apply --stdin`, the store validates,
      neovim renders them as virt_lines, and `stop()` clears every drawn buffer.
      `checks/diffnote-roundtrip.nix` covers the CLI, not the chord-to-render
      path `deps:` 4.1
- [x] 4.5 Adversarial review: whether each new pi command earns its surface, and
      whether the declared hook order matches observed behaviour `deps:` 4.4

      The order did NOT match. Declared pi-tool-display before pi-btw; the actual
      order in piPackagePaths is the reverse. The assertion passed anyway because
      it only checked membership, and membership is not the thing the declaration
      exists to record: pi runs these handlers in load order and each sees the
      previous one's mutations.

      Fixed both halves. The declaration now matches, and the assertion compares
      sequences. It derives the actual order by filtering the INSTALLED list,
      because filtering the declared list would only ever reproduce the
      declaration and could never disagree with it. Mutation-tested: swapping two
      entries fails the build and prints declared against actual.

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
- [x] 5.4 Decide: the owner rules on `pi-annotated-reply` and
      `@juicesharp/rpiv-advisor`, whose removal evidence is recorded in
      `piPackagePaths` comments, and on the stale `mcp-cache.json` `deps:` 5.3

      Both removed, on evidence that nothing routes to either. pi-annotated-reply
      registers eight commands and zero hooks, and its `/reply-diff` and
      `/reply-diff-editor` duplicate what `ctrl+b` now does through neovim and
      diffnote. rpiv-advisor is one manually-invoked `/advisor` command paid for
      with a `before_agent_start` system-prompt injection on every agent start,
      and the adversarial-review skill plus pi-subagents already cover
      second-opinion review. Neither is named by any skill, doc, or instruction in
      this repo. Package list 23 -> 21. `mcp-cache.json`, stale since 2026-05-12
      and read by nothing since the MCP sidebar panel and pi-mcp-adapter went,
      deleted with a copy kept aside.

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
- [x] 6.2 Install the openspec skills and prompts globally for every harness, so
      no repo needs `openspec init`. Upstream ships `pi` as a first-class tool
      (`.pi/skills/openspec-*/SKILL.md`, `.pi/prompts/opsx-<id>.md`), `codex` and
      `agents` share `.agents/skills/`, and `opencode` uses `.opencode/skills/`.
      Nix owns those roots already `deps:` 6.1

      Done, and it exposed why builds were taking 40 minutes. The schema was
      copied into the openspec derivation, so every template edit rebuilt the CLI
      from source through pnpm. It never needed to be: `openspec schema which`
      reports a user-level schema shadowing the package's built-in of the same
      name. The schema moved to `modules/home/programs/llm/openspec-schema` and
      installs through `xdg.dataFile`; build went from 40+ minutes to 67 seconds.

      Two traps, both found by testing rather than assuming. It must be
      `xdg.dataFile`, because openspec reads XDG_DATA_HOME when set and
      `modules/home/default.nix` exports it. And it must be enumerated per file,
      because openspec's discovery skips a symlinked schema directory, so one
      recursive entry installs a schema it then refuses to list.

      Skills and opsx commands are generated once by a local derivation and land
      in `~/.claude/skills` and `~/.claude/commands/opsx`. `openspec init` needs
      `--force` and closed stdin: without them it reaches its legacy-cleanup
      prompt and, with no TTY, blocks forever instead of failing.
- [x] 6.3 Onboard the new opsx skills (`propose`, `explore`, `apply`, `update`,
      `sync`, `archive`, and the expanded `new`/`continue`/`ff`/`verify`/
      `bulk-archive`/`onboard`) into the generated skill set `deps:` 6.2

      Done, with a correction: openspec 1.6.0 offers `core` and `custom` only.
      There is no `expanded` profile, so `new`/`continue`/`ff`/`verify`/
      `bulk-archive`/`onboard` do not exist to onboard. `core` ships six:
      propose, explore, apply, update, sync, archive. All six installed.
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
- [x] 7.3 Evaluate an openspec store for the sysinit constellation. `store:` and
      `references:` are real keys in `ProjectConfigSchema`, so the wiring exists.
      The case for one is concrete: this work spans sysinit, sysinit.laurel, and
      specutil, and the change describing it can only live in one of them today.
      The case against is that stores are beta and upstream says file formats may
      still change. Decide adopt-now against wait `deps:` 7.1

      Decided: wait, with a named trigger. The multi-repo evidence is stronger
      than expected, 8 of 8 active changes reference sysinit.laurel, specutil, or
      seshy, so this is the normal case rather than an occasional one. But the
      pain a store removes is "planning lives in a repo that is not the one you
      work in", and all 8 are authored, gated, and applied from sysinit. laurel
      and specutil are satellites of it. Today a store would add a second repo to
      keep in sync, a per-machine registration step, and exposure to beta formats
      upstream says may still change, in exchange for solving a problem this
      layout does not currently have.

      Revisit when a change is authored primarily from laurel or specutil rather
      than sysinit. That is the point at which the hub assumption breaks and
      `store:` plus `references:` start paying for themselves.
- [x] 7.4 Decide how seshy relates to worksets. A seshy session already groups
      repos for one feature and a workset is a personal multi-folder view, so the
      question is whether they are the same object named twice. If they are,
      seshy should emit the store reference rather than both tracking it `deps:` 7.3

      Decided: they are not the same object, and one concrete fix fell out.
      A seshy session groups working copies and dies with the session; its
      `openspec/` is ephemeral. A store is a durable git-backed planning repo
      registered per machine. They compose rather than compete: a session that
      needs planning outliving it should reference a store instead of initing its
      own tree.

      The fix: seshy's postCreate ran `openspec init --tools all`, writing 30-plus
      per-tool trees into every session, one per harness, all identical. Now that
      the skills install globally that is pure duplication, so the hook is
      `--tools none` and only the session-scoped `openspec/` structure is created.
- [ ] 7.5 Adversarial review: whether an unattended refine that only proposes is
      actually read, or becomes a weekly file nobody opens `deps:` 7.2, 7.4
