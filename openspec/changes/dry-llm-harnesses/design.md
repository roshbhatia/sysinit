## Context

The LLM module follows the pattern already proven by `skills.nix` and `lib/mcp.nix`: collect a concern in one Nix file, expose helpers, and have callers consume them by name. The current weak spot is that each harness config still inlines the *plumbing* of getting to those helpers — six imports, four function calls, all duplicated. The same plumbing exists in eight of eleven files, with only a `skillsRoot` argument and a per-harness output shape changing.

A parallel weakness exists on the allowlist axis. `lib/mcp.nix` already exposes a `permissions` attrset categorized by domain (`git`, `nix`, `utilities`, etc.) — but only `goose` and `cursor` consume it through `lib/mcp.nix`'s `formatPermissionsForGoose` and `formatPermissionsForCursor`. The other allowlist-bearing harnesses (claude, opencode, crush, amp) each encode their own bash-allowlist locally. The newest of these is the Tier A list in `claude.nix` from the prior `agent-skill-library` change — 149 patterns embedded inline. Promoting that list into a canonical source is the obvious next step.

Existing patterns being reused:
- `modules/home/programs/llm/skills.nix` — single source of truth for one concern (skills), consumed by every harness that needs skills. The new `harness-kit.nix` follows the same pattern for the boilerplate concern.
- `modules/home/programs/llm/lib/mcp.nix`'s `formatFor<Harness>` family — one source of MCP server data, N formatters. The new `lib/allowlist.nix` mirrors this exactly: one source of `tierA`/`tierB` patterns, N formatters.
- `modules/home/programs/llm/lib/default.nix`'s aggregator role — already exports `instructions`, `mcp`, `subagents`. The new modules slot in here.

Constraints:
- **Byte-identity of rendered config files is non-negotiable.** This change is a pure structural refactor. Any rendered-output difference between pre- and post-refactor is a bug in the refactor, not a feature.
- `pi.nix` is out of scope. It just received its own refresh and has its own unique structure (mostly Nix-side derivation building rather than agent config). Pulling it into the kit pattern is Phase 2 work at the earliest.
- The kit interface is a chokepoint. Every harness flows through it. Breaking changes here cascade. The interface MUST be conservative — exactly `{ llmLib, skillsLib, mcpServers, mkInstructions }`, no more, no less.
- The user's CLAUDE.md says "no `any` or type suppressions" — Nix has no equivalent, but we should respect the spirit: no `lib.unsafeDiscardStringContext` or other escape hatches in the new helpers.

## Goals / Non-Goals

**Goals:**

- Every harness config's `let` block is reduced to a single `kit = harnessKit.mkKit { inherit lib pkgs config; };` line plus harness-specific code.
- Every bash-allowlist-bearing harness consumes `allowlist.formatFor<X> allowlist.tierA` (plus optional `tierB` where appropriate) instead of inlining patterns.
- Rendered config files are byte-identical (or, for allowlists, multiset-equivalent) before and after the change.
- The `~/.claude/settings.json`, `~/.config/opencode/opencode.json`, `~/.config/goose/config.yaml`, etc., all auto-allow the same set of read-only commands after this change.

**Non-Goals:**

- Reducing the harness-config file sizes for their own sake. The opencode 523-line file is mostly its bespoke 80-entry allowlist — once that consumes `formatForOpencode allowlist.tierA`, the file becomes ~50 lines, but that's a side-effect, not the goal.
- Touching `pi.nix`.
- Adding new patterns to the allowlist beyond what's already in `claude.nix`'s Tier A and what's already in `lib/mcp.nix`'s `permissions` blocks. Pattern hygiene is separate work.
- Reorganizing `lib/mcp.nix`'s `formatFor<Harness>` family. They stay where they are; only the allowlist axis gets a parallel `lib/allowlist.nix`.

## Decisions

### D1. `harness-kit.nix` is a function module, not a fixed-output

**Decision:** `harness-kit.nix` is a Nix file returning a single function `mkKit { lib, pkgs, config }`. Callers invoke it once per harness with their local `lib`/`pkgs`/`config` and destructure the returned attrset.

**Alternatives considered:**
- *Top-level attrset module:* `lib/harness-kit.nix` returns `{ llmLib, skillsLib, mcpServers, mkInstructions }` directly, importing `lib`/`pkgs`/`config` from a fixed context. Doesn't work — `pkgs` is per-host, `config` is per-evaluation, can't be a singleton.
- *Auto-import via NixOS module options:* Add a `sysinit.llm.harnessKit` option that materializes the kit. Over-engineered; modules-of-modules adds an evaluation indirection for no benefit.
- *Pass the kit as an argument through the `imports = [ ... ]` chain:* Nix module merge semantics make this awkward.

**Why function:** matches how `skills.nix` already works (`import ../skills.nix { inherit pkgs; }`), and how every other Nix helper is consumed. Familiar shape, zero surprise.

### D2. `lib/allowlist.nix` is the canonical bash-allowlist source

**Decision:** A new file at `modules/home/programs/llm/lib/allowlist.nix` exposes `{ tierA, tierB, formatForClaude, formatForOpencode, formatForGoose, formatForAmp, formatForCrush, formatForCursor }`. Every harness with a bash allowlist consumes this; harnesses without (aider, codex, copilot-cli, gemini) do not touch it.

**Alternatives considered:**
- *Extend `lib/mcp.nix`'s `permissions` block:* The existing categorized permissions (`git`, `nix`, `utilities`, …) are MCP-server-related and used by goose/cursor's `formatPermissionsForX`. Putting Claude's Tier A in there mixes two concerns (MCP perms vs general bash) — they happen to overlap, but conflating them locks future flexibility. Separate file keeps both axes clean.
- *Inline in `harness-kit.nix`:* The kit is a boilerplate-removal layer, not a content source. Mixing them makes the kit fat and harder to reason about.
- *One mega-formatter that takes a `target = "claude" | "opencode" | …` arg:* Strings as types is fragile; per-name formatters fail at evaluation time on typos, the mega-formatter only fails at the call site.

**Why separate file:** mirrors `lib/mcp.nix`'s shape (one source, N formatters), keeps allowlist content distinct from kit plumbing, and gives Phase 2 (max-use) a clean place to extend `tierA`/`tierB`.

### D3. `tierA` is the existing Claude allowlist, lifted verbatim

**Decision:** The 149 entries in `claude.nix`'s `tierAReadOnlyBash` move to `lib/allowlist.nix` as `tierA` with no content changes in this refactor. `formatForClaude` reproduces the existing `"Bash(<pattern>)"` shape.

**Alternatives considered:**
- *Take this opportunity to expand `tierA`:* The audit will identify additional candidates (e.g., from opencode's 80-entry list). Adding them here couples the refactor to content changes; safer to keep the refactor pure and let Phase 2 add new patterns one by one.
- *Curate down — remove rarely-used patterns:* Same coupling concern. The 149 patterns were already curated when Tier A was authored. Don't second-guess in a refactor.
- *Restructure `tierA` by category (like `lib/mcp.nix`'s permissions):* Worth doing but adds risk to byte-identity. Defer to Phase 2.

**Why verbatim:** byte-identity is the safety net for this refactor. Changing content invalidates it.

### D4. Byte-identity verification is per-harness, per-slice

**Decision:** After each slice of the refactor (kit migration of N harnesses), the workflow is: `nix build .#darwinConfigurations.hyperion.system` → for each affected harness, locate its rendered output path under the result, `diff` against the pre-refactor path (captured via `git stash` + build). Failure aborts the slice.

**Alternatives considered:**
- *Trust the build:* If `nix flake check` passes and `nh os build` succeeds, the resulting config files are *valid* — but valid is not the same as *unchanged*. A whitespace shift or attrset-order flip would pass build but break the byte-identity invariant.
- *Whole-system diff at the end:* Easier but harder to attribute failures. Per-slice gives narrow blame.
- *Diff only one harness per slice:* Slow. Per-slice with all affected harnesses is the right granularity.

**Why per-harness, per-slice:** matches the schema's progressive-rollout rule and gives narrow attribution when a regression appears.

### D5. wezterm smoke test is mandatory for each touched harness

**Decision:** After applying each phase, drive `wezterm cli` to spawn a new pane, launch the affected harness's binary (`claude`, `codex`, `aider`, `gemini`, `goose`, `crush`, `cursor`, `amp`, `gh copilot`, `opencode`) in its expected mode, capture the startup output, and verify (a) it doesn't error on missing context files, (b) it reports an MCP-enabled status if MCP is configured, (c) for skill-aware harnesses, it finds the skills directory.

**Alternatives considered:**
- *Headless smoke test (run binary, check stderr):* Some harnesses (claude, gemini, crush, opencode) are TUI-first and may behave differently in a real PTY vs headless. The wezterm-tui-test skill is the right tool — it drives a real PTY.
- *Skip smoke test, trust byte-identity:* Byte-identity proves the *config file* didn't change. It doesn't prove the binary's interpretation is unaffected (e.g., if a binary changed its config-parsing between releases without our knowing). Smoke testing closes that gap.
- *One smoke test at the end:* Doesn't satisfy the schema's per-phase confirm gate.

**Why wezterm:** matches the `wezterm-tui-test` skill we already have for exactly this kind of work.

### D6. `lib/default.nix` re-exports `harnessKit` and `allowlist`

**Decision:** `modules/home/programs/llm/lib/default.nix` adds `harnessKit = import ./harness-kit.nix;` and `allowlist = import ./allowlist.nix { inherit lib; };` to its returned attrset. Callers reach the new modules via `llmLib.harnessKit` and `llmLib.allowlist`, never via direct file imports from `config/`.

**Alternatives considered:**
- *Direct file imports from `config/`:* `import ../lib/harness-kit.nix` everywhere. Loses the aggregator role of `lib/default.nix`.
- *New top-level imports:* Add `harnessKit.nix` and `allowlist.nix` at `modules/home/programs/llm/`. Mixes new modules with pre-existing ones (`skills.nix`, `mcp.nix`) at the same level. Cleaner to keep new helpers under `lib/`.

**Why through `lib/default.nix`:** every existing harness already does `llmLib = import ../lib { inherit lib; }`. Adding to `lib/default.nix`'s exports means no caller needs a new import line.

### D7. Allowlist consumers stay close to harness-specific config shapes

**Decision:** Each consuming harness's config file is responsible for calling `formatFor<X>` against the right tier combination (some want `tierA`, some `tierA ++ tierB`). The allowlist module does not embed per-harness tier-selection logic.

**Alternatives considered:**
- *`allowlist.formatForClaude` takes a tier name string:* `formatForClaude "tierA"`. Stringly-typed again.
- *Per-harness default tier in the allowlist:* `allowlist.claudeDefault`. Couples the allowlist to harness-specific policy.

**Why consumer-side selection:** each harness owns its own trust policy. The allowlist provides patterns; the harness decides which tiers to grant.

## Rollout & Gating

**Sequenced slices** (each ending in a wezterm smoke test):

1. **Slice 1 — scaffolding only.** Add `lib/harness-kit.nix` and `lib/allowlist.nix`, wire both into `lib/default.nix`. Don't touch any harness config yet. **Gate:** `nix flake check`; `nh os build`; no rendered output should differ since nothing consumes the new modules.
2. **Slice 2 — claude migration.** Migrate `claude.nix` to consume `harnessKit.mkKit` and `allowlist.formatForClaude allowlist.tierA`. **Gate:** byte-identity diff of rendered `~/.claude/settings.json` (multiset equality on `permissions.allow`); `nh darwin switch`; wezterm smoke test launching `claude` in a pane.
3. **Slice 3 — small-config harnesses.** Migrate `aider`, `codex`, `copilot-cli`, `cursor`, `gemini` (all under 50 lines). **Gate:** byte-identity of each rendered file; `nh darwin switch`; wezterm pane per harness, capture startup output, confirm context files load.
4. **Slice 4 — medium-config harnesses.** Migrate `amp`, `crush`, `goose`. Each gets `allowlist.formatFor<X> allowlist.tierA` (plus `tierB` for goose's `allow_tools`). **Gate:** byte-identity; `nh darwin switch`; wezterm smoke test.
5. **Slice 5 — opencode.** This is the heavy one — the 80-entry inline `bash` allowlist becomes `allowlist.formatForOpencode (allowlist.tierA ++ allowlist.tierB)`. **Gate:** byte-identity is multiset on the `permission.bash` attrset (key set must match); `nh darwin switch`; wezterm smoke test launching `opencode`.

**Kill switch:** `nix profile rollback` reverts the live system. Per-slice rollback: revert the commit for that slice.

**Feature flag / config toggle:** none needed. The refactor is pure structural; there's nothing to toggle.

## Risks / Trade-offs

- **[Risk]** Byte-identity proves the config file didn't change but doesn't prove a tool's *interpretation* didn't. **Mitigation:** the wezterm smoke test at each phase confirms the binary still launches and reports a sensible state.
- **[Risk]** Multiset equality on `permissions.allow` (rather than ordered equality) tolerates a refactor that changes pattern order. Most harnesses don't care about order, but some might (e.g., a precedence-by-order semantics). **Mitigation:** the affected harness's smoke test catches behavioral changes; if a harness IS order-sensitive, capture-and-restore the original order in the allowlist module.
- **[Risk]** The new `mkInstructions` API is positional (single `skillsRoot` arg). If a caller in the future wants to pass a different `openspecVersion` or `localSkillDescriptions`, they can't through the kit. **Mitigation:** the kit exposes `llmLib` and `skillsLib` directly too; an unusual caller drops down to the raw `llmLib.instructions.makeInstructions` form, but that's a strong signal the kit interface should be revisited.
- **[Risk]** Adding `harness-kit.nix` and `allowlist.nix` to `lib/default.nix` increases the module's evaluation surface. **Mitigation:** Nix evaluation is lazy; unused exports cost nothing.
- **[Trade-off]** The refactor saves ~50–70 LOC of `let`-block boilerplate but adds ~150 LOC for `lib/harness-kit.nix` and `lib/allowlist.nix` themselves. Net-zero in line count. The win is single-source-of-truth, not file-size reduction.

## Migration Plan

1. **Verify:** working tree clean. `nix flake check` and `nh os build --no-link` green. `~/.claude/settings.json` content captured to a temp file for post-hoc diff.
2. **Apply:** in five slices, each its own commit. Each slice: edit Nix → format → `nh os build` → byte-identity diff → `nh darwin switch` → wezterm smoke test → commit → push.
3. **Confirm:** after the final slice, `./hack/check-agents-md.sh`, `./hack/sync-openspec-skills.sh`, `./hack/sync-openspec-schema.sh`, and `./hack/update-pi.sh` all exit clean. `openspec validate dry-llm-harnesses` exits clean.

**Rollback:** `git revert <slice-commit>` for a single slice; `nix profile rollback` reverts the live system.

## Open Questions

- Should `tierB` (reversible writes) ship in this change at all, given that Claude's current allowlist is Tier A only? Leaning yes: codifying the contract for "what's reversible" is part of what makes `allowlist.nix` valuable, even if Claude doesn't consume `tierB` initially. The opencode migration *will* consume `tierA ++ tierB` because opencode's existing list includes formatters like `nix fmt` already.
- The wezterm smoke test needs to know each harness's launch command and a way to detect "running cleanly." For TUI tools the easiest check is "still alive after 3s and no error text in last 10 lines of output." Per-harness specifics get worked out at apply time using the `wezterm-tui-test` skill.
- Whether to add a "double-gate" assertion in `harness-kit.nix` that throws if any harness in `config/` (excluding `pi.nix`) imports `../lib/instructions.nix`, `../mcp.nix`, or `../skills.nix` directly. Useful for enforcing D2 over time. Cheap to add. Probably yes — capture in tasks.md.
