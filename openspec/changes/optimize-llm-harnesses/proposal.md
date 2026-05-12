## Why

The just-archived `dry-llm-harnesses` change made every LLM config consume `harness-kit` and (where it fit) the canonical allowlist. The DRY base is in place. The next leverage is per-harness: each tool has shipped features over the last few months that we're not using, and each has a "one-paragraph integration" that earns its keep. The librarian audit during explore identified six high-value adoptions across six harnesses; the rest of the configured tools (amp, crush, copilot-cli) are either at reasonable depth already or dormant enough that further tuning would be premature.

Doing this against the now-cleaner base is meaningfully easier than it would have been pre-refactor — `harness-kit.mkKit` makes adding extension wiring or feature toggles a one-line change per harness, and the `allowlist` module's glob-pattern helpers (Phase 1 of the opencode work) compress what would otherwise be 30+ inline entries into a handful of glob keys.

## What Changes

- **gemini**: vendor a `.gemini/extensions/` directory wired via `home.file`, mirroring how Claude Code's skills are managed. Source-of-truth for which extensions to install: a small Nix attrset in `gemini.nix` similar to `pi.nix`'s package list. First extension: a thin "openspec-aware" prompt extension that loads the current `openspec list --json` output into Gemini's context on session start.
- **aider**: enable architect/editor model split. Architect = Claude Sonnet 4.5 (via Anthropic), editor = a cheaper model (e.g., Haiku 4.5). Symlink `CONVENTIONS.md` from the repo's `AGENTS.md` so aider sessions read the same convention source as every other harness. Add `.aider.conf.yml` defaults via the Nix module.
- **goose**: vendor `.config/goose/recipes/` with recipes for `openspec-propose`, `openspec-apply`, `openspec-archive`, mirroring the four `/opsx:*` slash commands we have for Claude Code. The recipes wrap the same shell-out patterns the existing skills use.
- **cursor**: migrate the legacy `.cursorrules` content into per-glob `.cursor/rules/*.mdc` files. Three rule files: `always.mdc` (alwaysApply), `nix.mdc` (globs `**/*.nix`), `markdown.mdc` (globs `**/AGENTS.md` `**/CLAUDE.md`). Keep the legacy `.cursorrules` for compatibility with older Cursor versions until verified safe to drop.
- **opencode**: compact the 80-entry `permission.bash` allowlist using glob patterns. Replace explicit per-subcommand entries (`git status*`, `git diff*`, …) with `git:*` style globs where opencode's matcher supports them. Net result: same auto-allow surface, ~75% fewer entries.
- **codex**: add per-profile `reasoning_effort` setting. Default profile gets `low`; a new `spec` profile gets `high`. Add a `model_reasoning_summary` setting so spec-work profiles emit visible reasoning summaries. Profiles wired via `~/.codex/config.toml`.

### Non-goals

- Adopting `cursor-agent` background agents or Cursor IDE companion features. Out of scope — pi already covers our long-running agent surface.
- Adding new MCP servers. The `mcp-servers.nix` registry (ast-grep, playwright) is sufficient; expansion is a separate concern.
- Enabling `aider --watch-files` mode (file-system watcher). Aider remains opt-in per session, not always-on.
- Goose recipes that auto-execute mutating commands. Recipes wrap the openspec workflow CLI calls only; no `nh os switch` or `git push` automation.
- Migrating `.cursorrules` to MDC and then immediately deleting the legacy file. Keep both during this change; deletion is a follow-up after we confirm the MDC files are honored.
- Touching amp, crush, copilot-cli. The audit flagged them as either at reasonable depth (amp's permission DSL is fine for now), dormant in the user's actual workflow (crush), or limited by upstream surface (copilot-cli has no plugin model). Revisit if/when usage patterns change.
- Touching pi.nix. Pi was just exhaustively refreshed; no max-use gap remains.
- Touching claude.nix beyond what `dry-llm-harnesses` already did. Claude is at the highest depth of any harness — skills, subagents, hooks, allowlist all wired.

## Capabilities

### New Capabilities

- `gemini-extensions`: How Gemini extensions are vendored under `.gemini/extensions/<name>/`, the manifest shape each extension exposes, and the contract for the openspec-awareness extension shipped in this change.
- `aider-architect-mode`: How the architect/editor model split is configured in `.aider.conf.yml`, the contract for which models play which role, and the conventions-file symlink scheme.
- `goose-recipes`: How recipe YAML files at `~/.config/goose/recipes/<name>.yaml` are generated from Nix, the canonical recipe set covering the openspec workflow, and the rules for what a recipe may and may not do (no irreversible system mutations).
- `cursor-rules-mdc`: The per-glob MDC rule file structure under `.cursor/rules/`, which rules are `alwaysApply` vs glob-scoped, and the migration path from legacy `.cursorrules`.
- `opencode-allowlist-globs`: The compacted glob-based shape for opencode's `permission.bash` allowlist, and the rule that future additions go through glob expansion rather than per-subcommand entries.
- `codex-reasoning-effort`: The per-profile `reasoning_effort` and `model_reasoning_summary` settings in `~/.codex/config.toml`, the named profile set (at least: `default`, `spec`), and which profile is selected by default.

### Modified Capabilities

None. Each adoption introduces a new capability surface; the previously-archived specs (`harness-kit`, `harness-allowlist`) describe scaffolding that this change uses but doesn't alter.

## Impact

- **Code touched**: `modules/home/programs/llm/config/gemini.nix`, `config/aider.nix`, `config/goose.nix`, `config/cursor.nix`, `config/opencode.nix`, `config/codex.nix`. New per-harness asset directories: `config/gemini/extensions/`, `config/goose/recipes/`, `config/cursor/rules/`. Possibly a new `lib/recipes.nix` helper if goose recipes need shared formatting; deferred to design.
- **Removed**: opencode's 80-entry `permission.bash` block (the explicit per-subcommand entries; replaced with globs). The legacy `.cursorrules` file is NOT removed in this change.
- **External dependencies**: no new flake inputs. The architect/editor model split for aider uses existing Anthropic/OpenAI keys the user already has configured. Gemini extensions are static markdown/prompts — no runtime deps.
- **Impactful actions** (each wrapped verify/apply/confirm in tasks.md):
  - `nh darwin switch .` after each harness's slice — re-renders that harness's config in the live system. Six switches total.
  - Cursor MDC migration is the highest-risk: if `.cursor/rules/` parsing changed between Cursor CLI versions and we don't notice, rules might silently stop applying. Mitigation: keep `.cursorrules` during this change; verify rules-loaded status with `cursor-agent --help` and/or by triggering a known-rule prompt response in a wezterm pane.
  - Opencode allowlist compaction: shape change to a key file the agent reads at every session start. Mitigation: byte-comparison of which commands would be allowed pre vs post compaction (script the matcher).
- **Risk surface**: highest is cursor MDC (parser change between versions). Lowest is codex reasoning_effort (additive setting, no removals). Per-slice rollback via `git revert` plus `nix profile rollback` works for all six.
- **Gating signal**: Default for this repo — `nix flake check` → `nh os build` → `git diff` review → byte-identity diff where applicable → `nh os switch` → wezterm smoke test launching the affected harness. The smoke test for each slice is enriched: not just `--version` but a brief interactive prompt that exercises the newly-adopted feature (e.g., aider's architect mode produces a known marker; goose recipe `--list` shows the new recipes; gemini extension manifest appears in `gemini --list-extensions` if such a command exists; cursor rules render in the welcome message).
