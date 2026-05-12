## Context

`dry-llm-harnesses` shipped the structural refactor: every config consumes `harness-kit`, claude consumes the canonical allowlist. The LLM module is now in good shape to absorb per-harness feature adoption without growing the boilerplate it just shed.

The librarian audit (executed in explore mode before this change was proposed) identified specific adoption candidates per harness, ranked by leverage:

```
1. gemini       → .gemini/extensions/ + openspec-awareness extension
2. aider        → architect/editor split + CONVENTIONS.md
3. goose        → recipes for openspec workflow
4. cursor       → MDC rules
5. opencode     → glob-compacted allowlist
6. codex        → reasoning_effort per profile
(skipped: amp, crush, copilot-cli — at reasonable depth or limited upstream surface)
```

Each item is small in isolation (1–3 files per harness, dozens of LOC). The risk model differs: cursor and opencode change consumer-readable config shapes; gemini and goose add new files; codex and aider are pure feature toggles.

Existing patterns being reused:
- **pi.nix**'s package-attrset shape** for `gemini-extensions` — declare extensions in a Nix attrset, render to `home.file` entries.
- **claude.nix → openspec-status.ts** for the `openspec-awareness` Gemini extension — read-only shell-out to `openspec list --json` with graceful degradation.
- **harness-allowlist.formatFor* family** for `opencode-allowlist-globs` — extend `formatForOpencode` to emit compact glob keys, source-of-truth stays in `lib/allowlist.nix`.
- **mcp-servers.nix's attrset registry shape** for `goose-recipes` — declare recipe definitions in a single Nix attrset, render to YAML.

Constraints:
- No new flake inputs.
- Six harnesses × per-slice verify/apply/confirm = six `nh darwin switch` cycles. Each cycle costs ~10 seconds plus the wezterm smoke time.
- Aider's architect/editor mode requires the user to have valid Anthropic API credentials (which they do — claude-code-use confirmed earlier). If credentials aren't present in the test environment, the smoke test must degrade to `aider --help` rather than `aider --architect --message ...`.

## Goals / Non-Goals

**Goals:**

- Each adopted feature lands as one phase with its own verify/apply/confirm cycle.
- Configuration content for each new feature is declared in Nix and rendered to the harness's expected path — no hand-edited target files.
- The canonical allowlist (from `dry-llm-harnesses`) gains a glob-compacted formatter for opencode without touching the consumers we already migrated.
- Every recipe / extension / rule we ship is itself a one-source-of-truth Nix string — no duplicated workflow text between Claude skills and Goose recipes.

**Non-Goals:**

- Touching amp, crush, copilot-cli, pi, claude. Out of scope per the audit (and per the proposal's Non-goals).
- Adding tier-based allowlist consumption for opencode (the allowlist migration deferred from `dry-llm-harnesses` is still deferred — this change only addresses glob compaction for the existing inline entries).
- Removing the legacy `.cursorrules` file. MDC migration is additive in this change.
- Adopting OAuth-only or subscription-only auth changes for any harness (deferred until we have a separate "auth model alignment" change that touches every provider together).

## Decisions

### D1. Slice order is roughly audit-rank order

**Decision:** Phases proceed in the order: gemini → aider → goose → cursor → opencode → codex. Each is independent — no inter-phase dependencies — so the order is chosen to land highest-leverage changes first.

**Alternatives considered:**
- *Alphabetical:* irrelevant to leverage.
- *By risk (lowest first):* would put codex first and cursor last. Defensible but front-loads small wins; user-visible value is concentrated at the start of audit-rank order.

**Why audit-rank:** the librarian's ordering ranked by "biggest unlock per harness." Honor it.

### D2. Gemini extensions follow pi's vendoring model, not skills.nix's

**Decision:** Gemini extensions are vendored as a per-extension attrset in `gemini.nix` (analogous to `piPackages` in `pi.nix`), each mapping to a `home.file` entry. They are NOT registered in `modules/home/programs/llm/skills/default.nix` because they're Gemini-specific, not cross-agent skills.

**Alternatives considered:**
- *Extend `skills.nix` with a Gemini variant:* couples a Gemini-specific concern to a cross-agent registry. Wrong layer.
- *One big `lib/gemini-extensions.nix`:* over-engineering for a 1–2 extension surface. The pi pattern handles 27 packages; gemini will have far fewer.

**Why pi-pattern:** matches the closest existing precedent for "vendor a registry of small bundles per harness."

### D3. The openspec-awareness Gemini extension is read-only

**Decision:** The Gemini extension contains a prompt-injection block that reads `openspec list --json` and surfaces the active change. No tool registration, no slash command. Mirrors the read-only `openspec-status.ts` extension shipped for pi in `refresh-pi-stack`.

**Alternatives considered:**
- *Write a tool that mutates openspec state:* premature; the read-only pattern earned its keep in pi.
- *Skip the openspec-awareness extension; ship the `.gemini/extensions/` plumbing empty:* sets up scaffolding with no demonstration of value. Weak proof.

**Why read-only:** the rosh-spec-driven schema's "human verification before impactful actions" rule applies; read-only is the safe default for first-iteration extensions.

### D4. Aider's CONVENTIONS.md is a generated copy, not a symlink

**Decision:** `aider.nix` renders the `AGENTS.md` content to a `~/.aider/CONVENTIONS.md` regular file (or wherever aider's documented per-user conventions path lives — verify during apply). Not a symlink.

**Alternatives considered:**
- *Symlink to the repo's `AGENTS.md`:* requires the repo path to be stable. The user works across multiple repos; aider sessions outside sysinit wouldn't have a valid symlink target.
- *Inline-rendered string in aider config:* aider doesn't have a "conventions inline" config field; it reads a file.

**Why generated copy:** consistent across all sessions regardless of CWD; matches how `AGENTS.md` is generated from `instructions.nix`.

### D5. Goose recipes share their prompt body with the corresponding Claude skill

**Decision:** Both `~/.config/goose/recipes/openspec-<verb>.yaml` and `~/.claude/skills/openspec-<verb>/SKILL.md` source their workflow body from the **same Nix string**. The single source-of-truth lives at `modules/home/programs/llm/skills/openspec-<verb>.nix`; `goose.nix` imports and YAML-wraps it.

**Alternatives considered:**
- *Hand-write recipe bodies:* duplicate content; will drift.
- *Symlink the SKILL.md into the recipe directory:* shape mismatch (goose recipes are YAML with frontmatter; SKILL.md is markdown with YAML frontmatter — close but not identical).

**Why shared Nix string:** matches the harness-allowlist pattern from Phase 1 — single source, N formatters.

### D6. Cursor MDC migration keeps the legacy file

**Decision:** The legacy `.cursorrules` file (which we vendor today via `cursor.nix`) stays in place for this change. We add `~/.cursor/rules/*.mdc` files alongside. Deletion of `.cursorrules` is a follow-up after the user's actual Cursor sessions confirm MDC loading works.

**Alternatives considered:**
- *Delete `.cursorrules` in this change:* if Cursor CLI version the user runs doesn't honor MDC, rules silently stop applying. Bad failure mode.
- *Conditional install based on Cursor CLI version:* over-engineering; the legacy file is small and harmless.

**Why both:** the rosh-spec-driven schema's progressive-rollout rule favors a kill switch. The `.cursorrules` is that kill switch — if MDC breaks something, the user keeps working.

### D7. Opencode glob compaction goes through lib/allowlist.nix

**Decision:** Extend `formatForOpencode` in `lib/allowlist.nix` to emit glob keys (e.g., one `"git:*"` instead of 18 per-subcommand). `opencode.nix` consumes the canonical Tier A + Tier B through this formatter and KEEPS its inline `ask`/`deny` rules (those are policy, not auto-allow).

**Alternatives considered:**
- *Compact inline in `opencode.nix`:* defeats Phase 1's "single source of truth" goal.
- *Add an opencode-specific glob list to `lib/allowlist.nix`:* couples the canonical list to a per-harness glob shape. The formatter is the right place for shape mapping.

**Why formatter:** the canonical list stays neutral; per-harness shape concerns live in the formatter.

### D8. Codex reasoning_effort is set via two named profiles

**Decision:** `codex.nix` declares two profiles: `default` (`reasoning_effort = "low"`, no summary) and `spec` (`reasoning_effort = "high"`, `model_reasoning_summary = "detailed"`). The user selects `--profile spec` for openspec-heavy work.

**Alternatives considered:**
- *Single profile with `reasoning_effort = "high"`:* burns tokens on everything, including trivial questions.
- *Three profiles (`low`, `med`, `high`):* over-engineering. Two is enough until we know we need more.

**Why two profiles:** the binary choice (cheap default vs deep spec work) matches the workflow signal — `spec` work is the deep-thinking surface.

## Rollout & Gating

**Sequenced slices** (each ending in build → switch → wezterm smoke):

1. **Slice 1 — gemini-extensions.** Add `.gemini/extensions/openspec-awareness/` vendoring scheme to `gemini.nix`. Ship one extension. **Gate:** `nix build`, `nh switch`, wezterm pane spawning `gemini --help` and confirming the extension manifest is loaded.
2. **Slice 2 — aider-architect-mode.** Set `architect-model`, `editor-model`, `architect: true` in `aider.nix`. Generate `~/.aider/CONVENTIONS.md` from `instructions.nix` output. **Gate:** `nix build`, `nh switch`, wezterm pane spawning `aider --version` and `aider --help | grep architect` to confirm the config takes effect.
3. **Slice 3 — goose-recipes.** Add `recipes` attrset to `goose.nix` referencing the existing `skills/openspec-<verb>.nix` strings. Render four `.yaml` files. **Gate:** wezterm pane spawning `goose recipe list` (or `goose --help` if `recipe list` isn't available) and confirming the four named recipes are reachable.
4. **Slice 4 — cursor-rules-mdc.** Add `~/.cursor/rules/{always,nix,markdown}.mdc` from `cursor.nix`. Keep `.cursorrules` untouched. **Gate:** wezterm pane spawning `cursor-agent --help` (no MDC-specific introspection command exists in CLI yet; sanity-check on launch is sufficient).
5. **Slice 5 — opencode-allowlist-globs.** Extend `formatForOpencode` with glob compaction. Migrate `opencode.nix`'s inline `permission.bash` block to consume the canonical allowlist for `allow` entries; keep inline `ask`/`deny`. **Gate:** byte-comparison of "what commands would be auto-allowed under each rule set" (script the matcher) to confirm the post-compaction allow surface is a superset of the pre-compaction one. wezterm pane launching `opencode --version`.
6. **Slice 6 — codex-reasoning-effort.** Add two named profiles to `codex.nix`. **Gate:** wezterm pane spawning `codex --profile spec --help` to confirm the profile is recognized.

**Kill switch:** per-slice, `git revert <slice-commit>` plus `nh darwin switch` rolls back that harness. Per-harness kill switches embedded in the design: cursor keeps `.cursorrules`; opencode keeps its `ask`/`deny` rules inline; aider's architect mode is a config-level toggle.

**Feature flag / config toggle:** each harness has its own — no global toggle for this change.

## Risks / Trade-offs

- **[Risk]** Cursor CLI MDC parser may differ from documented behavior. **Mitigation:** keep `.cursorrules`; wezterm smoke + a brief manual session check before declaring slice 4 done.
- **[Risk]** Goose recipe schema may have shifted between versions; YAML keys we emit might not be recognized. **Mitigation:** consult `goose recipe --help` and a known-good upstream recipe before generating; `goose recipe validate` if available.
- **[Risk]** Aider's `architect-model` may require credentials the test environment doesn't have. **Mitigation:** smoke test degrades to `aider --help` only; deep architect-mode validation is a manual user check.
- **[Risk]** Codex CLI may not yet expose `reasoning_effort` as a config-file setting (only via flag). **Mitigation:** the spec's "unknown settings tolerated" requirement covers the silent-ignore case; verify during apply by reading codex CLI docs at that point.
- **[Risk]** Opencode glob compaction may inadvertently allow a previously-asked command (e.g., `git:*` covers `git commit*`). **Mitigation:** the spec's "compaction preserves ask rules" requirement forces the formatter to consider opencode's matcher precedence; the byte-comparison gate at apply time validates.
- **[Trade-off]** Six switch cycles is more friction than one big switch, but matches the schema's progressive-rollout rule and gives narrow rollback.

## Migration Plan

1. **Verify:** working tree clean. `nix flake check` and `nh os build` green. `~/.claude/skills/openspec-*` materialized (we rely on them as the source for goose recipes).
2. **Apply:** in six slices per the rollout. Each slice ends with a commit on main and `nh darwin switch`.
3. **Confirm:** after the final slice, `./hack/check-agents-md.sh`, `./hack/sync-openspec-skills.sh`, `./hack/sync-openspec-schema.sh`, `./hack/update-pi.sh` all clean. `openspec validate optimize-llm-harnesses` clean. wezterm smoke for every touched binary.

**Rollback:** `git revert <slice-commit>` + `nix profile rollback`. Per-harness; no cross-cutting state.

## Open Questions

- Whether the Gemini extension system supports startup hooks for prompt injection, or whether the extension can only contribute MCP server entries. If the latter, the openspec-awareness extension downgrades to a documentation file pointing users at `openspec list --json` rather than an automatic inject. Determined during apply.
- The exact path Aider reads `CONVENTIONS.md` from at the global level — `~/.aider/CONVENTIONS.md`, `~/.config/aider/CONVENTIONS.md`, or `~/.aider.conf.yml`'s `read` field. Determined during apply by consulting `aider --help` output.
- Whether `goose recipe validate <path>` exists as a CLI subcommand. If not, recipe correctness is gated only by the wezterm smoke test invoking `goose recipe run <name>`.
- For opencode allowlist compaction, whether opencode's matcher honors the `tool:*` shape (colon-separated tool prefix). The audit assumed yes; verified during slice 5 implementation.
- For codex profiles, whether the home-manager `programs.codex.settings.profiles` attrset is the correct shape, or whether the user has to pass a raw TOML block. Determined during apply.
