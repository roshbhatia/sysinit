## Why

The Nix-managed LLM module (`modules/home/programs/llm/`) already proves the pattern of generating SKILL.md and per-agent context files from a single source — but only one skill (`shell-scripting`) currently flows through it. Useful agent capabilities live in three drifted locations: project-local `.claude/skills/openspec-*` directories that have to be hand-copied per repo, an opaque `~/.agents/skills/find-skills` symlink with no Nix provenance, and ad-hoc "manual rules" the user re-types at agents every session. SKILL.md and AGENTS.md authoring also predates the May 2026 conventions documented at agents.md and platform.claude.com — current files carry non-spec frontmatter and an architectural overview that the latest research shows costs ~19% inference overhead without measurable gain. Centralizing these now unblocks a coherent path to richer integrations (custom OpenSpec schemas, cocoindex semantic search) without compounding the drift.

## What Changes

- Move `openspec-{propose,apply,explore,archive}` SKILL.md files and `/opsx:*` slash commands into the Nix-managed llm module so every project receives them automatically.
- Add three new globally-installed skills: `find-skills` (Vercel Labs), `seshy` (scoped to spawning persistent dev sessions), and `cocoindex-query` (how agents talk to a cocoindex MCP endpoint).
- Rewrite SKILL.md frontmatter and bodies to the May 2026 spec: drop `license`/`compatibility`/`version`/`metadata` fields, enforce third-person trigger-rich descriptions, cap bodies at 500 lines, references one level deep, add opt-in `allowed-tools`.
- Rewrite `AGENTS.md` and the `instructions.nix` preamble to the May 2026 standard: drop the architectural overview, lead with stack+versions/exact-commands/conventions/prohibitions, cap at ~200 lines, fix the stale skill table and the wrong skills path (`modules/home/configurations/llm/skills/` → `modules/home/programs/llm/skills/`). Generate both AGENTS.md and CLAUDE.md from the same Nix source.
- Fork the `spec-driven` OpenSpec schema into `openspec/schemas/rosh-spec-driven/` and encode the user's recurring "manual rules" as schema-level constraints, so they become first-class instructions instead of session-by-session reminders.
- Document the global gitignore stance (OpenSpec artifacts already excluded via `**/openspec/` in `~/.config/git/ignore`) so future projects don't reintroduce per-repo `.gitignore` lines for it.
- Defer the full cocoindex + pgvector + MCP service integration to a follow-up change; this proposal only ships the `cocoindex-query` skill that documents the contract once the service exists.

### Non-goals

- Standing up the cocoindex MCP service or its pgvector backend (deferred to a separate change with its own risk surface).
- Replacing or wrapping the OpenSpec CLI — the fork uses `openspec schema fork` and stays compatible with upstream commands.
- Per-tool overlay files (`.cursor/rules/`, `.github/copilot-instructions.md` path-scoped variants); covered in a follow-up after the global story is stable.
- Multi-tenant or shared-team distribution of the schema and skills; this is single-user dotfiles.
- An MCP server for the skill registry itself; static SKILL.md files are sufficient.

## Capabilities

### New Capabilities

- `agent-skill-library`: Centralized, Nix-managed pool of SKILL.md files installed to every agent root (`~/.claude/skills/<name>/SKILL.md`, plus Codex/Gemini equivalents). Defines which skills are global, how they're declared in `skills/default.nix`, and how external skills (Vercel Labs, anthropics/skills) are vendored.
- `agent-skill-authoring`: Authoring contract for SKILL.md files — required frontmatter, trigger-rich description conventions, length caps, reference-file depth, `allowed-tools` hints. Lints applied at build time.
- `agent-context-files`: Generation rules for AGENTS.md and per-agent context files (CLAUDE.md, GEMINI.md, codex `instructions.md`) from a single `instructions.nix` source. Defines required sections, length caps, and the prohibition on architectural overviews.
- `openspec-customization`: Project-local OpenSpec schema fork (`rosh-spec-driven`) that encodes recurring authoring rules. Defines how the schema is referenced from each project's `openspec/config.yaml`, what rules it adds beyond the base `spec-driven` schema, and how it's kept in sync with upstream.

### Modified Capabilities

None. No prior `openspec/specs/` content exists.

## Impact

- **Code touched**: `modules/home/programs/llm/skills.nix`, `modules/home/programs/llm/skills/default.nix`, `modules/home/programs/llm/skills/*.nix` (new files), `modules/home/programs/llm/lib/instructions.nix`, `modules/home/programs/llm/config/{claude,codex,gemini,...}.nix`, `AGENTS.md`, `hack/sync-openspec-skills.sh` (new), `openspec/schemas/rosh-spec-driven/` (new), `openspec/config.yaml`.
- **Removed**: project-local `.claude/skills/openspec-*/` and `.claude/commands/opsx/` once their Nix-managed equivalents are wired and verified.
- **Dependencies**: No new runtime dependencies. cocoindex remains a follow-up change (would add Postgres/pgvector). seshy and find-skills are already in user's stack.
- **External services**: None in this change. A subsequent change will introduce the cocoindex MCP server.
- **Risk surface**: Drift between upstream `openspec instructions <artifact>` prompts and our vendored SKILL.md copies. Mitigated by `hack/sync-openspec-skills.sh` that diffs against upstream and fails CI when behind.
- **Users affected**: Single-user dotfiles; no API or external consumer surface.
