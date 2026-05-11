## Context

The `modules/home/programs/llm/` tree already implements the right architecture: skills are `.nix` files that render to SKILL.md, an `instructions.nix` library composes per-agent context, and `home.file` symlinks everything into place. The gap is **coverage and conventions**: only one skill flows through the pipeline today, several useful skills live elsewhere (project-local, opaque symlinks, in user memory), and the rendered files predate the May 2026 SKILL.md and AGENTS.md guidance from Anthropic and agents.md.

Three concrete signals motivate doing this now:

- The user re-types the same "manual rules" at every OpenSpec session. These belong in a forked schema's template/instructions so the rules ship with the artifact instructions agents already pull via `openspec instructions`.
- `AGENTS.md` references `modules/home/configurations/llm/skills/` (the path doesn't exist) and lists skills (`nix-development`, `lua-development`, `session-completion`) that aren't in the registry. The file is already drifting.
- `find-skills` works today only because of an undocumented `~/.agents/skills/find-skills` symlink. New machines won't have it. The fix is reproducible Nix vendoring.

Constraints:
- Single-user, Nix-managed dotfiles. No multi-tenant concerns.
- OpenSpec 1.3.0 ships custom schemas as the only first-class extension surface — no plugin/hook API.
- Claude Code does not natively read `AGENTS.md` (as of April 2026 per the hivetrail comparison cited in research). CLAUDE.md remains required.
- Existing global gitignore at `~/.config/git/ignore` already covers `**/openspec/`, `**/.claude/`, `**/.agents/`. The proposal preserves that, doesn't reinvent it.

## Goals / Non-Goals

**Goals:**

- One declarative registry of globally-installed agent skills, sourced of truth in `modules/home/programs/llm/skills/default.nix`.
- Every required skill exists for every configured agent (claude, codex, gemini, …) with reproducible content.
- SKILL.md frontmatter and bodies conform to the May 2026 spec — and a build-time linter enforces it.
- `AGENTS.md` and per-agent context files are regenerated from one Nix source and follow 2026 conventions on what to include and exclude.
- The user's recurring "manual rules" for OpenSpec authoring become schema-level constraints surfaced by `openspec instructions <artifact>` so agents see them without per-session reminders.
- A drift-detection script flags when upstream OpenSpec prompts or vendored third-party skills change.

**Non-Goals:**

- Standing up the cocoindex MCP service and pgvector backend. The `cocoindex-query` skill in this change documents the contract; the service is a follow-up.
- Replacing or wrapping the OpenSpec CLI. The fork uses its supported `openspec schema fork` mechanism.
- Per-project agent context overlays (Cursor `.cursor/rules/`, Copilot `.github/copilot-instructions.md` path-scoped variants). Out of scope; would be a separate change once the global story is settled.
- A new MCP server for the skill registry itself. Static SKILL.md files are sufficient.

## Decisions

### D1. Skill registry stays Nix-attrset, not a directory-glob

**Decision:** Continue declaring skills in `skills/default.nix` as an explicit attrset keyed by name. Do **not** switch to globbing `*.nix` files in the directory.

**Alternatives considered:**
- *Glob:* Cleaner for adding skills (just drop a file), but loses the per-skill metadata channel (`description`, `skip = [...]`, `allowed-tools`) that the attrset gives us as first-class attributes. Also makes "what's required vs optional" implicit.
- *External JSON manifest:* No benefit over Nix; loses ability to compose with other Nix logic.

**Why attrset:** explicit, lets us attach metadata other than `content`, and lets `nix flake check` assert required skills exist.

### D2. Linting and conformance checks live in Nix `assert`s, not a separate script

**Decision:** Frontmatter rules (no `license`, name regex, description length, body line count) are enforced by Nix builder assertions inside `skills.nix`, evaluated at `nix flake check` / `nix build` time.

**Alternatives considered:**
- *Pre-commit hook:* Easy to bypass with `--no-verify`. Doesn't catch drift introduced by `nh os switch` from a CI machine.
- *Runtime check by the agent:* Wrong layer; checks should fail builds, not sessions.

**Why Nix-level:** the build is the only place all skill content is materialized at once. Asserting there gives one canonical gate.

### D3. AGENTS.md and CLAUDE.md are both generated, not symlinked

**Decision:** `instructions.nix` produces two separate files. They share six top-level sections (`Stack`, `Commands`, `Conventions`, `Skills`, `Prohibitions`, `Context`); CLAUDE.md gets additional Claude-Code-specific text appended after the shared block.

**Alternatives considered:**
- *Symlink CLAUDE.md → AGENTS.md:* The OpenAI repo does this. But blocks adding Claude-Code-specific guidance (e.g., `/opsx:*` slash command discovery hints) without polluting AGENTS.md. The research cites dev.to/datadog recommending against symlinking for exactly this reason.
- *Single file written to both paths:* Same problem as symlink.

**Why generated-twice:** keeps the shared content byte-identical (verifiable in build) while leaving room for divergent extensions. Nix makes "two files from one source" trivial.

### D4. The OpenSpec fork lives in-repo, not as a separate Git repo

**Decision:** `openspec/schemas/rosh-spec-driven/` lives inside sysinit. Projects reference it by Git URL pointing at this repo, sub-path `openspec/schemas/rosh-spec-driven/`.

**Alternatives considered:**
- *Standalone repo `roshbhatia/openspec-schema-rosh`:* Cleaner separation, but adds a second repo to release-manage. The schema co-evolves with the user's habits captured in sysinit; co-location reduces cross-repo PRs.
- *Vendor the upstream schema into a private fork:* Heaviest. Loses the `openspec schema fork` provenance that makes upstream-drift detection easy.

**Why in-repo:** lowest maintenance overhead for a single-user setup. If a second user ever wants the schema, the sub-path URL still works.

### D5. Drift detection runs on demand, not in CI

**Decision:** `hack/sync-openspec-skills.sh` and `hack/sync-openspec-schema.sh` are user-invoked maintenance scripts that report drift but do not auto-merge.

**Alternatives considered:**
- *CI job that fails when drift detected:* For a single-user, CI-light repo, this is heavier than warranted and would block unrelated PRs whenever upstream openspec ships a prompt tweak.
- *Auto-merge:* Risks silently overwriting deliberate local edits.

**Why on-demand reporting:** detection without coupling. Run when bumping `overlays/openspec.nix`.

### D6. seshy skill targets the multi-repo session model

**Decision:** Ship a `seshy` SKILL.md focused on the non-interactive subcommands of the `sy` binary (`sy new <name>`, `sy add <path>`, `sy list`, `sy path <name>`, `sy delete <name>`, `sy --greedy <name>`). The skill directs the agent to use these for any operation that needs a named multi-repo session — creation, repo attachment, lookup, teardown. The interactive fzf flow (`sy` with no arguments) is documented as human-only.

**Alternatives considered:**
- *Skip seshy — agents call tmux directly:* Loses seshy's project-aware multi-repo model. `tmux new-session` doesn't know about `~/.config/seshy/config.yaml` project discovery or the named multi-repo grouping.
- *Document the fzf picker for agents:* Hangs non-interactive sessions; never appropriate.

**Why subcommand-focused:** The non-interactive surface is rich enough that seshy is a genuine agent tool, not just a human convenience. The skill is the place to disambiguate the binary name (`sy`, not `seshy`) and surface the subcommand layout.

### D7. cocoindex skill ships now, service later

**Decision:** Include `cocoindex-query` SKILL.md in this change describing how agents will query the cocoindex MCP endpoint (assumed at `cocoindex:semantic_search` and `cocoindex:read_chunk`). Do **not** install/run cocoindex in this change.

**Alternatives considered:**
- *Defer skill until service exists:* Forces a second drive-by skills change later. Skill content is forward-compatible documentation.
- *Build the service now:* Drags Postgres/pgvector lifecycle into this change. Too big a blast radius.

**Why now-with-stub:** decouples the SKILL.md authoring (which fits this change's scope) from the service rollout (which deserves its own change with its own risk surface).

## Risks / Trade-offs

- **[Risk]** Vendored upstream SKILL.md from `anthropics/skills` or `vercel-labs/skills` could change in ways that break our linter (e.g., they introduce a field we ban). **Mitigation:** the sync script reports the diff; we vendor a known-good revision and bump deliberately, not on every flake update.

- **[Risk]** Forking the OpenSpec schema couples us to its template format; an upstream major version could rename templates and break the fork. **Mitigation:** the sync script catches this at openspec version bumps; `openspec schema validate` is run in flake check.

- **[Risk]** The byte-identical-shared-section assertion between AGENTS.md and CLAUDE.md is annoying if someone tweaks one inadvertently. **Mitigation:** both files are build outputs; direct edits are blocked by D2's `nix flake check`.

- **[Risk]** Removing `license`/`compatibility`/`metadata` fields from existing openspec SKILL.md copies could in theory affect tools that parse them. **Mitigation:** none of the agents in our stack consume those fields per the research; if a third party does, the fork preserves them as a per-skill opt-in field that defaults off.

- **[Risk]** "Manual rules" encoded in the schema may not match the user's actual rules — captured from session memory rather than asked for explicitly. **Mitigation:** the schema fork is reversible; the first revision of `rosh-spec-driven` will be reviewed before adoption and adjusted iteratively. Rules can also be removed by editing the fork without re-running `openspec schema fork`.

- **[Trade-off]** Generating both AGENTS.md and CLAUDE.md from the same Nix source means non-Nix contributors can't tweak them with a text editor. Acceptable: this is single-user dotfiles, the user is the only contributor, and Nix is the established toolchain.

- **[Trade-off]** Keeping cocoindex deferred means the `cocoindex-query` skill describes a contract the agent can't actually exercise until the service exists. The skill explicitly notes "service availability TBD; verify the MCP endpoint responds before invoking" to avoid spurious failures.

## Migration Plan

1. Add new skill `.nix` files alongside the existing `shell-scripting.nix`. Existing skill unchanged. New skills are inert until registered.
2. Register them in `skills/default.nix`. They begin generating into `~/.claude/skills/`. Existing skill still works.
3. Add the lint assertions to `skills.nix`. Fix any violations in the existing `shell-scripting` skill (likely none, but verify).
4. Rewrite `instructions.nix` to the May 2026 structure. Existing `AGENTS.md` is replaced wholesale by build output; old file is deleted from the tree in the same commit so contributors don't read a stale copy.
5. Fork the schema: `openspec schema fork spec-driven rosh-spec-driven` inside this repo, then commit. Update `openspec/config.yaml` in this repo to reference the fork by relative path.
6. Delete `sysinit/.claude/skills/openspec-*/` and `sysinit/.claude/commands/opsx/` once their Nix-managed equivalents are verified to render correctly.
7. Run `nh os switch` on the workstation; verify `~/.claude/skills/`, `~/.claude/CLAUDE.md`, and the root `AGENTS.md` are populated as expected.
8. Smoke test: `/opsx:propose` in a scratch repo to confirm the skill loads from the new location.

**Rollback:** every change is a Nix module edit; `nix profile rollback` reverts. The forked schema directory can be deleted and `openspec/config.yaml` reverted to `schema: spec-driven`.

### D8. Schema rule placement is split by audience

**Decision:** The four manual rules from `specs/openspec-customization/spec.md` land in the upstream schema's two text channels as follows:

| Rule                                          | `template` change                                         | `instruction` change                                                          |
|-----------------------------------------------|-----------------------------------------------------------|-------------------------------------------------------------------------------|
| Non-goals subsection in proposals             | Add a `### Non-goals` block under `## What Changes`        | Add: "When the change touches more than one capability, fill in Non-goals."   |
| `tasks.md` phased when multi-capability       | No change (numbering already supports it)                 | Add: "Group tasks under phase headings (`## 1. Phase name`) when the change spans more than one capability." |
| Every requirement has a negative scenario     | No change                                                 | Add: "Every requirement MUST include at least one negative scenario (`WHEN <unexpected condition> THEN <error/rejection>`)."  |
| `design.md` Decisions records alternatives    | No change (header already present)                        | Add: "Each entry under Decisions MUST list at least one alternative considered and why it was rejected." |

**Alternatives considered:**
- *All rules in `template` only:* Templates are static scaffolds; agents see them once when the file is created. Rules don't get re-surfaced when an artifact is amended.
- *All rules in `instruction` only:* Loses the structural cue that a Non-goals subsection should exist — the agent might honor it once and drop it on revision.
- *Hybrid:* Best of both for the structural rule; instruction-only is sufficient for procedural rules.

**Why split:** matches the upstream schema's own two-channel design. Template carries shape; instruction carries authoring rules.

### D9. Fork named `rosh-spec-driven`

**Decision:** Fork name is `rosh-spec-driven`. Path: `openspec/schemas/rosh-spec-driven/`.

**Alternatives considered:**
- *`sysinit-spec-driven`:* Ties identity to the host repo, but the schema captures *the user's* authoring preferences, not properties of sysinit. Misleading for users of other projects.
- *`lean-spec-driven`:* Presumptuous; the fork isn't necessarily leaner than upstream, just opinionated.
- *No prefix, just override `spec-driven`:* Loses the ability to compare against upstream and breaks `openspec schema which` reporting.

**Why `rosh-`:** owner-identity prefix is honest, matches how the fork is actually scoped, and avoids implying portability claims the fork doesn't make.

## Open Questions

- Should the lint assertions be a single combined check at the top of `skills.nix`, or per-skill `assertions` so failures pinpoint the offender? Leaning per-skill for ergonomics — final form decided when implementing.
