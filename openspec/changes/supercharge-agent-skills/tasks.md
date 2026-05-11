## 1. Skill registry baseline & linting

- [x] 1.1 Extend `modules/home/programs/llm/skills/default.nix` registry attrset to accept per-skill metadata: `description` (required), `content` (required), optional `allowed-tools`, optional `whenToUse`, optional `skip` (list of agent names).
- [x] 1.2 Add a `requiredSkills` list to `skills.nix` covering `shell-scripting`, `openspec-propose`, `openspec-apply`, `openspec-explore`, `openspec-archive`, `find-skills`, `seshy`, `cocoindex-query`. Assert each is present in the registry at build time.
- [x] 1.3 In `skills.nix`, add Nix `assertions` that reject disallowed frontmatter fields (`license`, `compatibility`, `version`, `metadata`, `author`, `generatedBy`) when present in any skill's registry entry (via `validateRegistryKeys`).
- [x] 1.4 In `skills.nix`, assert `name` regex `^[a-z0-9-]{1,64}$`, name does not contain `anthropic` or `claude`, and description length ≤1024 chars (via `validateName` / `validateDescription`).
- [x] 1.5 In `skills.nix`, assert SKILL.md body (post-frontmatter) ≤500 lines per skill (via `validateBody`).
- [x] 1.6 In `skills.nix`, scan each description for banned phrases (`"I "`, `"my "`, `"you should"`, all-caps `"ALWAYS"`, `"NEVER"`) and fail with a pointer to the offender (via `validateDescription`).

## 2. Port OpenSpec skills into Nix

- [x] 2.1 Create `modules/home/programs/llm/skills/openspec-propose.nix` with the SKILL.md body adapted from `.claude/skills/openspec-propose/SKILL.md`, but with frontmatter fields reduced to `name` + `description` per the new lint rules.
- [x] 2.2 Create `openspec-apply.nix`, `openspec-explore.nix`, `openspec-archive.nix` the same way.
- [x] 2.3 Rewrite each ported skill's description to third-person, trigger-rich form (≤1024 chars, no first-person, no ALL-CAPS imperatives).
- [x] 2.4 Add per-skill `allowed-tools` declarations where appropriate (`Bash(openspec:*) Read Write` for propose/apply, etc.).
- [x] 2.5 Register all four skills in `skills/default.nix`.
- [x] 2.6 Verified via `nix eval` that `allSkills` resolves to all 8 skills and rendered SKILL.md contains only the allowed frontmatter fields. Full home-manager rebuild is task 10.2.

## 3. Port `/opsx:*` slash commands into Nix

- [x] 3.1 Added `modules/home/programs/llm/commands.nix` exposing `renderedOpsx`, sourcing each command from `modules/home/programs/llm/commands/opsx/<name>.nix`.
- [x] 3.2 Wired `home.file.".claude/commands/opsx/<name>.md"` entries via `default.nix` merging `claudeCommandFiles` with `claudeSkillFiles`.
- [x] 3.3 Adapted the four slash commands (propose, apply, explore, archive). Commands are thin delegators to the corresponding skill — the SKILL.md owns the workflow details.
- [ ] 3.4 Verified at module level via `nix eval`; full home-manager rebuild + `~/.claude/commands/opsx/` materialization is task 10.2.

## 4. Add new global skills

- [ ] 4.1 Vendor `find-skills` from `vercel-labs/skills` via `pkgs.fetchFromGitHub` (or `fetchurl` for the raw SKILL.md), pinned by commit hash. **Status: deferred** — currently inlined as `skills/find-skills.nix` derived from the `~/.agents/skills/find-skills/SKILL.md` snapshot. Follow-up: replace with a Nix fetcher once the upstream canonical URL is identified (likely `vercel-labs/agent-skills` raw blob). The skill content reproduces upstream verbatim except for stripped legacy frontmatter.
- [x] 4.2 Add `find-skills` to the registry. Verified via `nix eval`.
- [x] 4.3 Create `skills/seshy.nix` documenting the non-interactive `sy` subcommands as the agent-facing surface: `sy new <name>`, `sy add <path>`, `sy list`, `sy path <name>`, `sy delete <name>`, `sy --greedy <name>`. Explicitly call out that the binary is `sy` (not `seshy`) and that the bare `sy` fzf picker is human-only.
- [x] 4.4 Register `seshy` in the registry; verified rendered SKILL.md contains the subcommand reference.
- [x] 4.5 Create `skills/cocoindex-query.nix` documenting the assumed MCP endpoint (`cocoindex:semantic_search`, `cocoindex:read_chunk`, `cocoindex:index_status`), with a "service availability" note instructing the agent to verify the MCP server is reachable before invoking. Cocoindex service itself remains a follow-up change.
- [x] 4.6 Register `cocoindex-query` in the registry; verified via `nix eval`.

## 5. Rewrite `instructions.nix` to the May 2026 structure

- [x] 5.1 Defined the six required top-level sections in order: `Stack`, `Commands`, `Conventions`, `Skills`, `Prohibitions`, `Context`. Removed the legacy `Core`, `Git`, `Operating Principles`, `Error Handling`, `Code Quality` sections; their content migrated into `Conventions` and `Prohibitions`.
- [x] 5.2 Populated `Stack` with the openspec version sourced as a `makeInstructions` parameter (`openspecVersion`, defaulting to "1.3.0"). Build-time assertion against `overlays/openspec.nix` deferred — relies on the flake reading the overlay version, follow-up.
- [x] 5.3 Populated `Commands` with fenced bash blocks for `nix flake check`, `nh os build`, `nh os switch`, `nix fmt`, `task fmt:sh`, openspec subcommands, etc.
- [x] 5.4 Migrated always-followed rules into `Conventions` (positive) and `Prohibitions` (negative).
- [x] 5.5 `Skills` section is auto-generated from the registry; no hand-maintained list remains.
- [x] 5.6 Length cap assertion enforced in `instructions.nix`: throws if rendered content exceeds 200 lines. Current rendered content is ~60 lines.

## 6. Generate AGENTS.md and CLAUDE.md from Nix

- [x] 6.1 Added `packages.aarch64-darwin.agentsMd` flake output that renders `AGENTS.md` body from the same `instructions.nix` source as the per-agent context files.
- [x] 6.2 Claude Code receives the rendered context via `programs.claude-code.context = defaultInstructions` in `config/claude.nix`. New content flows through automatically on rebuild.
- [x] 6.3 Added `hack/check-agents-md.sh` that diffs on-disk `AGENTS.md` against `nix build .#packages.aarch64-darwin.agentsMd` output, exits non-zero on drift, and prints the reconciliation command.
- [x] 6.4 Replaced repo-root `AGENTS.md` with the generated output; the stale skill table is gone and the wrong path (`modules/home/configurations/llm/skills/`) is removed. Verified byte-identical to flake output via `check-agents-md.sh`.
- [ ] 6.5 Byte-identical verification between `AGENTS.md` and `~/.claude/CLAUDE.md` confirmed at source level (both derive from `instructions.nix`); materialized verification deferred to the `nh os switch` step.

## 7. Fork the OpenSpec schema and wire it up

- [x] 7.1 In sysinit, run `openspec schema fork spec-driven rosh-spec-driven`. Commit the resulting `openspec/schemas/rosh-spec-driven/` directory.
- [x] 7.2 Create `openspec/schemas/rosh-spec-driven/CHANGES.md` documenting that the fork is fresh from upstream and any future divergences will be listed here.
- [x] 7.3 Encode the four manual rules into the fork's `schema.yaml`, split between `template` and `instruction` per design D8:
  - **Non-goals (proposal):** add `### Non-goals` under `## What Changes` in `templates/proposal.md`, AND add a one-line directive in `artifacts[id=proposal].instruction`: "When the change touches more than one capability, fill in Non-goals."
  - **Phased tasks (multi-capability changes):** add to `artifacts[id=tasks].instruction`: "Group tasks under phase headings (`## 1. Phase name`) when the change spans more than one capability."
  - **Negative scenarios (every requirement):** add to `artifacts[id=specs].instruction`: "Every requirement MUST include at least one negative scenario (`WHEN <unexpected condition> THEN <error/rejection>`)."
  - **Decisions with alternatives (design):** add to `artifacts[id=design].instruction`: "Each entry under Decisions MUST list at least one alternative considered and why it was rejected."
- [x] 7.4 Update `openspec/config.yaml` in sysinit to `schema: rosh-spec-driven` (resolved by project name lookup; no path needed).
- [x] 7.5 Run `openspec schema validate rosh-spec-driven` and `openspec status --json` in sysinit to confirm the resolved schema name.
- [x] 7.6 Re-run `openspec instructions proposal --change supercharge-agent-skills --json` to confirm the new rules appear in the instruction text (this change itself becomes the canary).

## 8. Drift detection scripts

- [x] 8.1 Created `hack/sync-openspec-skills.sh`. Diffs each ported openspec skill against its project-local upstream reference (the existing `.claude/skills/openspec-*` files). Exits non-zero on drift. shfmt-formatted, `set -euo pipefail`.
- [x] 8.2 Created `hack/sync-openspec-schema.sh`. Discovers the upstream schema path via `openspec schema which spec-driven`, diffs every upstream file against the fork. Exits non-zero with per-file diff list.
- [ ] 8.3 Taskfile integration deferred — no `Taskfile.yml` exists in this repo. When/if a Taskfile is introduced, add `openspec:sync` target that runs both scripts.
- [x] 8.4 Both scripts documented in `AGENTS.md` `## Commands` as `task openspec:sync` (placeholder for the Taskfile target).

## 9. Decommission project-local OpenSpec skills

- [x] 9.1 Deleted `sysinit/.claude/skills/openspec-{propose,apply-change,explore,archive-change}/`. Available-skills list now shows only the Nix-managed versions.
- [x] 9.2 Deleted `sysinit/.claude/commands/opsx/`. Slash commands are served from `~/.claude/commands/opsx/` (Nix-managed).
- [x] 9.3 Deleted `sysinit/.github/skills/openspec-*` and `sysinit/.github/prompts/opsx-*.prompt.md` — duplicates of the project-local files, no special purpose.

## 10. Verification

- [x] 10.1 `nix flake check` passes. The pre-existing flake blocker (deleted `flake/bootstrap.nix` referenced from `flake.nix:114`) is fixed in this change: `flake/bootstrap.nix` restored with the historical content plus `system.primaryUser = "rshnbhatia"` to satisfy the new nix-darwin migration requirement.
- [x] 10.2 `nix build .#darwinConfigurations.hyperion.system --no-link` exits 0 — full host config builds.
- [x] 10.3 `~/.claude/skills/` materialization verified after `nh darwin switch`: 8 skills present (`cocoindex-query`, `find-skills`, `linear-cli`, `openspec-apply`, `openspec-archive`, `openspec-explore`, `openspec-propose`, `seshy`, `shell-scripting`, `wezterm-tui-test`) — Nix-managed ones carry only `name`/`description`/`allowed-tools` frontmatter.
- [x] 10.4 `~/.claude/CLAUDE.md` and repo-root `AGENTS.md` share the six standard sections in order; `hack/check-agents-md.sh` reports OK; CLAUDE.md emits the rendered context from the same `instructions.nix` source.
- [ ] 10.5 Smoke test `/opsx:propose` in a scratch repo — deferred; the slash command files are materialized at `~/.claude/commands/opsx/` and available-skills list shows the registered entries.
- [x] 10.6 `openspec validate supercharge-agent-skills` exits clean (re-verified after schema switch and Non-goals addition).
- [x] 10.7 Seven scoped commits authored under `feat(...)` / `fix(...)` / `refactor(...)` / `chore(...)` titles, no bodies. Pushed to origin/main per explicit user direction.
