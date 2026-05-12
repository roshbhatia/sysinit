## 1. Slice 1 — gemini-extensions

- [x] 1.1 Confirmed Gemini CLI extension shape via `gemini extensions --help` + a template scaffold (`gemini extensions new /tmp/probe`). Minimum manifest is `{ name, version }`; richer manifest supports `contextFileName`, `mcpServers`, `description`. Used `contextFileName: "CONTEXT.md"` for in-context prompt content (no startup hooks needed — Gemini auto-loads context files declared in the manifest).
- [x] 1.2 Created `modules/home/programs/llm/config/gemini-extensions/openspec-awareness/{gemini-extension.json,CONTEXT.md}`. Manifest declares name + version + description + contextFileName. CONTEXT.md documents the openspec CLI surface and the rosh-spec-driven workflow.
- [x] 1.3 In `config/gemini.nix`, added a `geminiExtensions` attrset mapping `<name> = ./gemini-extensions/<name>` and a `mkExtensionFiles` helper that reads each extension directory and emits `home.file.".gemini/extensions/<name>/<file>"` entries for every file inside.
- [x] 1.4 **Verify**: `nix build` green; rendered files appear in home-manager output.
- [x] 1.5 **Apply**: committed `feat(gemini): vendor extensions directory and ship openspec-awareness`, pushed, `nh darwin switch`.
- [x] 1.6 **Confirm**: `script -q /dev/null gemini extensions list` reports `✓ openspec-awareness (1.0.0)` with the CONTEXT.md path. `gemini extensions validate ~/.gemini/extensions/openspec-awareness` succeeds.

## 2. Slice 2 — aider-architect-mode

- [x] 2.1 Confirmed aider's config path: `~/.aider.conf.yml` (YAML; documented in `aider --help`). The conventions surface uses `--read FILE` or `read:` config key. Chose `~/.aider/CONVENTIONS.md` for the symlinked conventions file.
- [x] 2.2 In `config/aider.nix`, added `architect = true`, `model = "anthropic/claude-sonnet-4-5"`, `editor-model = "anthropic/claude-haiku-4-5"`, `read = "<home>/.aider/CONVENTIONS.md"` to `programs.aider-chat.settings`.
- [x] 2.3 Added `home.file.".aider/CONVENTIONS.md"` sourced from `kit.mkInstructions "~/.claude/skills"` so aider reads the same convention surface as AGENTS.md.
- [x] 2.4 **Verify**: build green. Rendered `~/.aider.conf.yml` contains `architect: true`, both models, and the `read:` path.
- [x] 2.5 **Apply**: committed `feat(aider): architect/editor model split and conventions file`, pushed, `nh darwin switch`.
- [x] 2.6 **Confirm**: `aider --dry-run` startup output: `Model: anthropic/claude-sonnet-4-5 with architect edit format` and `Editor model: anthropic/claude-haiku-4-5`. CONVENTIONS.md loaded as read-only context.

## 3. Slice 3 — goose-recipes

- [x] 3.1 Confirmed goose's recipe schema via the upstream docs: top-level `description`, `title`, `version`, and at least one of `instructions` or `prompt`. Recipes loaded from `GOOSE_RECIPE_PATH` env var (defaulted to `~/.config/goose/recipes/`).
- [x] 3.2 The Claude skills at `modules/home/programs/llm/skills/openspec-<verb>.nix` return Nix strings — used as the canonical workflow bodies.
- [x] 3.3 In `config/goose.nix`, added a `recipes` attrset for the four verbs and a `mkRecipe` helper that emits each as a JSON-encoded YAML-compatible file (using JSON form is valid YAML). Files installed at `~/.config/goose/recipes/openspec-<verb>.yaml`.
- [x] 3.4 Added `GOOSE_RECIPE_PATH` to `home.sessionVariables`.
- [x] 3.5 **Verify**: build green; all four files rendered.
- [x] 3.6 **Apply**: committed `feat(goose): vendor recipes for the openspec workflow`, pushed, `nh darwin switch`.
- [x] 3.7 **Confirm**: `goose recipe list` (via wezterm pane) reports all four recipes with descriptions.

## 4. Slice 4 — cursor-rules-mdc

- [x] 4.1 Drafted three MDC files at `modules/home/programs/llm/config/cursor-rules/{always,nix,markdown}.mdc`. always uses `alwaysApply: true`; nix scopes to `**/*.nix`; markdown scopes to `**/AGENTS.md`, `**/CLAUDE.md`, `**/GEMINI.md`, `**/.cursorrules`.
- [x] 4.2 In `config/cursor.nix`, generate `~/.cursor/rules/<name>.mdc` via `home.file` from each source. Added build-time assertion `validateMdc` that rejects MDC files declaring both `alwaysApply: true` and `globs:`.
- [x] 4.3 No legacy `.cursorrules` exists in the user's home or current cursor.nix — no preservation needed. MDC files are the only rule surface.
- [x] 4.4 **Verify**: build green; the three MDC files render with correct frontmatter.
- [x] 4.5 **Apply**: committed `feat(cursor): add MDC rule files for repo-wide conventions`, pushed, `nh darwin switch`.
- [x] 4.6 **Confirm**: `ls ~/.cursor/rules/` shows the three files; frontmatter inspected — `always.mdc` has `alwaysApply: true`; `nix.mdc` and `markdown.mdc` have `globs:` only.

## 5. Slice 5 — opencode-allowlist-globs (DEFERRED)

**Slice paused after audit of the existing opencode config.** Opencode's permission shape interleaves `allow` and `ask` rules per-pattern: `git status*=allow`, `git diff*=allow`, …, but `git commit*=ask`, `git push*=ask`, `git reset*=ask`. Same for `nix flake check*=allow` vs `nix build*=ask`, and many other tool families. The proposal's "compact to `git:*=allow`" plan would silently override the user-curated `git commit*=ask` etc., effectively expanding auto-allow to dangerous commands.

The proposal's own success criterion — "the rendered file's auto-allow surface MUST be a superset of the pre-compaction surface, AND `ask` rules MUST still classify their targets as `ask`" — cannot be honored with broad-prefix globs given opencode's matcher precedence (less-specific globs override more-specific ones in JSON attrset key order, which is the matcher's natural model).

Two paths forward, neither in scope of this slice:
1. **Canonical-source-only**: have opencode consume `kit.llmLib.allowlist.formatForOpencode tierA` for the *allow* axis, but keep its curated *ask* rules inline. Net effect: source-of-truth shift, no file-size reduction. Tracked as a separate future change.
2. **Opencode-matcher-aware compaction**: extend `formatForOpencode` to emit a structured ask/allow combination that respects opencode's precedence rules. Requires reading opencode's source to confirm matcher behavior. Bigger investment than the slice budget.

Leaving opencode's current allowlist intact. Moving to Slice 6.

- [-] 5.1–5.7 Deferred. See above.

## 6. Slice 6 — codex-reasoning-effort

- [x] 6.1 Confirmed home-manager `programs.codex.settings.profiles.<name>` shape works (it nests cleanly under the existing TOML structure).
- [x] 6.2 Added `default` (`reasoning_effort = "low"`) and `spec` (`reasoning_effort = "high"`, `model_reasoning_summary = "detailed"`) profiles.
- [x] 6.3 **Verify**: build green; rendered `~/.codex/config.toml` contains both `[profiles.default]` and `[profiles.spec]` sections with the declared keys.
- [x] 6.4 **Apply**: committed `feat(codex): add default and spec profiles with reasoning_effort`, pushed, `nh darwin switch`.
- [x] 6.5 **Confirm**: `~/.codex/config.toml` inspection shows both profile sections with correct keys. Codex CLI accepts `-p`/`--profile` flag.

## 7. Slice 7 — finalize

- [x] 7.1 `./hack/check-agents-md.sh` clean; `./hack/sync-openspec-schema.sh` reports the deliberate rosh-spec-driven divergences; `./hack/update-pi.sh` clean.
- [x] 7.2 No-direct-import lint still passes: `grep -rE "import \\.\\./(lib/instructions|mcp|skills)\\.nix" modules/home/programs/llm/config/ --include='*.nix' | grep -v 'pi\\.nix'` empty.
- [x] 7.3 `openspec validate optimize-llm-harnesses` clean.

## 8. Final validation

- [x] 8.1 `nix flake check` and `nh os build` green throughout.
- [x] 8.2 Five scoped conventional commits authored, one per LANDED slice (Slice 5 deferred). All pushed to main.
- [x] 8.3 `openspec validate optimize-llm-harnesses` clean.
- [x] 8.4 The six new spec files exist; five are satisfied by landed work (gemini-extensions, aider-architect-mode, goose-recipes, cursor-rules-mdc, codex-reasoning-effort). `opencode-allowlist-globs` is documented as deferred with reasoning in tasks.md Slice 5.
- [ ] 8.5 Archive: `openspec archive optimize-llm-harnesses --yes` (pending user confirmation).

## Deferrals

- **Slice 5 (`opencode-allowlist-globs`)** — opencode's per-pattern allow/ask matrix can't be safely compacted with broad-prefix globs without overriding deliberately-curated ask rules. See Slice 5 body for the two paths forward. The spec at `specs/opencode-allowlist-globs/spec.md` remains documented; satisfying it is reserved for a follow-up change once opencode's matcher precedence is verified.
