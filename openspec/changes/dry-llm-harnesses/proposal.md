## Why

The 11 harness configs under `modules/home/programs/llm/config/` each repeat the same 5–10 line `let` block — `llmLib` import, `skillsLib` import, `mcpServers` import, `defaultInstructions` call — with only the `skillsRoot` argument varying. Eight of the eleven files duplicate this boilerplate verbatim. Separately, the "what bash is safe to auto-allow" decision is encoded six different ways: a 149-entry Claude allowlist, a ~80-entry opencode per-tool allowlist, a goose formatter, a crush `allowed_tools` list, an amp permissions DSL, and a cursor `Shell(...)` formatter. Same intent, six encodings, no canonical source. Both duplications make adding a new harness expensive and make changing the trust model touch six files instead of one.

This is Phase 1 of a two-phase overhaul. Phase 2 (`optimize-llm-harnesses`, separate change) will ship per-harness max-use updates against the cleaner base.

## What Changes

- Add `modules/home/programs/llm/lib/harness-kit.nix` exposing one function `mkKit { lib, pkgs, config }` that returns `{ llmLib, skillsLib, mcpServers, mkInstructions }`. `mkInstructions` takes a `skillsRoot` string and returns the rendered instructions.
- Add `modules/home/programs/llm/lib/allowlist.nix` exposing canonical `tierA` (read-only) and `tierB` (reversible writes) patterns plus formatters `formatForClaude`, `formatForOpencode`, `formatForGoose`, `formatForAmp`, `formatForCrush`, `formatForCursor`. Source-of-truth for "what's safe to auto-allow."
- Migrate the 149-entry Tier A list currently embedded in `config/claude.nix` into `lib/allowlist.nix`. Claude's allowlist is now `allowlist.formatForClaude allowlist.tierA`.
- Refactor each affected harness config to consume `harnessKit` for imports and (where applicable) `allowlist` for permissions: `aider`, `amp`, `claude`, `codex`, `copilot-cli`, `crush`, `cursor`, `gemini`, `goose`, `opencode`. (`pi.nix` was just refreshed; it stays special-snowflake until Phase 2.)
- Verify each affected harness's rendered config file is **byte-identical** before and after the refactor — this change is pure restructuring, no semantic shift.
- Verify each binary still launches in a real terminal (`wezterm cli`) and reads its expected context file after `nh darwin switch`.
- Update `lib/default.nix` to export the two new modules so callers don't reach past it.

### Non-goals

- Adding new features to any harness (deferred to Phase 2).
- Adopting new pi packages or extensions (deferred to Phase 2; `pi.nix` is unchanged).
- Adding new MCP servers (the `lib/mcp.nix` formatters and `config/mcp-servers.nix` registry both stay as-is — this change consumes them, doesn't rewrite them).
- Building a "harness registry" that lets you turn harnesses on/off — over-engineering for an 11-file module.
- Refactoring the `subagents/` tree or the `skills/` tree (both already DRY).
- A `mkHarness` builder that absorbs the entire harness file's let-block (Sketch 2 from explore) — defers harness-specific quirks into a generic, hides where each agent's idiosyncrasies live.

## Capabilities

### New Capabilities

- `harness-kit`: The shared imports helper. Defines the contract `mkKit { lib, pkgs, config }` → `{ llmLib, skillsLib, mcpServers, mkInstructions }`, the constraint that callers must not reach past it into `lib/instructions.nix`, `mcp.nix`, or `skills.nix` directly, and the rule that adding a new harness requires only one `let kit = harnessKit.mkKit { ... }; in ...` line of boilerplate.
- `harness-allowlist`: The canonical bash-allowlist source. Defines the `tierA` and `tierB` pattern lists, the contract for `formatFor<Harness>` (input: pattern list, output: harness-native shape), and the rule that any harness wanting to express "what bash is safe" MUST consume this rather than encode patterns locally.

### Modified Capabilities

None at the spec level. The previously-archived specs (`agent-skill-library`, `agent-skill-authoring`, `agent-context-files`, `openspec-customization`, `pi-package-vendoring`, `pi-extension-config`, `pi-openspec-bridge`) are unaffected by this refactor — only the Nix structure changes; the behaviors those specs describe remain intact.

## Impact

- **Code touched**: `modules/home/programs/llm/lib/default.nix` (export new modules); two new files `lib/harness-kit.nix` and `lib/allowlist.nix`; nine harness configs in `config/` (aider, amp, claude, codex, copilot-cli, crush, cursor, gemini, goose, opencode). `pi.nix` deliberately untouched.
- **Removed**: the 149-entry inline Tier A `tierAReadOnlyBash` list in `config/claude.nix` (moves to `lib/allowlist.nix`); the duplicated `let llmLib = ...; skillsLib = ...; mcpServers = ...; defaultInstructions = ...;` blocks (replaced by one `kit = harnessKit.mkKit { inherit lib pkgs config; };` line each).
- **External dependencies**: none added. `lib/mcp.nix`'s existing per-harness formatters (formatForClaude, formatForOpencode, …) stay where they are; only the allowlist axis gets the new helper.
- **Impactful actions** (each wrapped in verify/apply/confirm in tasks.md):
  - `nh darwin switch .` — re-renders every affected harness's config and `~/.claude/skills/` plumbing. Single biggest blast radius.
  - Byte-identity diff check between pre- and post-refactor rendered config files for each harness. Failure means the refactor changed behavior, not just structure.
  - wezterm smoke test per harness: launch `aider`, `codex`, `claude`, `gemini`, `goose`, `crush`, `cursor`, `amp`, `copilot`, `opencode` in a real terminal pane, confirm each reads its context file and reports a sensible startup state.
- **Risk surface**: The byte-identity invariant is the entire safety net. If a refactor changes a rendered file by even whitespace, `nh os switch` re-activates and the affected agent reloads with a (slightly) different config — usually harmless but worth catching. The diff check at every phase boundary is non-negotiable.
- **Gating signal**: Default for dotfiles work — `nix flake check` → `nh os build` → `git diff` review → byte-identity diff of rendered store paths → user spot-check → `nh os switch` → wezterm smoke test per harness. Each slice of the refactor (kit, allowlist, then N harness migrations grouped) ships independently so a regression is narrowly attributable.
