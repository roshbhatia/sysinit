## Why

The rosh-spec-driven workflow currently mandates an adversarial review on every slice, models plans only as linear checklists, and has no first-class path for external web research. This change makes the review owner-gated (default on), lets a plan phase declare a loop or graph shape, and adds a Perplexity CLI that agents use for external research when authenticated (falling back to WebSearch otherwise).

## What Changes

- Make the adversarial-review gate optional and owner-gated. The `adversarial-review` skill elicits an approve/deny at slice entry (default: run). On deny it records "review waived by owner" and skips. The `schema.yaml` tasks/design rules change the review from MUST to default-on-owner-gated.
- Formalize plan phase shapes in the schema. A `tasks.md` phase declares one of two shapes: a `loop` (gather → act → verify, with an explicit stop condition and max-iteration cap; one iteration is the degenerate case) or a `graph` (subtasks with `deps:` edges, orchestrator-worker fan-out). `templates/tasks.md`, the `schema.yaml` tasks instruction, and `specreview.sh` are extended to define and validate the shapes.
- Add the Perplexity CLI (`pplx`) via a new `overlays/pplx.nix` (per-platform binary from the `perplexityai/perplexity-cli` v0.2.2 release, matching the `localias`/`crush` fetch pattern) and a new `pplx-cli` skill adapted from the upstream SKILL.md.
- Add an auth-conditional web-research rule: skills check `pplx auth` / `PERPLEXITY_API_KEY` at runtime. When authed, general external research uses `pplx search web` / `pplx content fetch`. When not authed, it falls back to the built-in WebSearch. pplx is never used for internal, private, or in-repo-docs research.

### Non-goals

- No change to the openspec CLI parser. Phase shapes live in the schema data (`templates/`, `schema.yaml` instruction) and are enforced by `specreview.sh`, not by a fork of openspec's checkbox tracking.
- No auto-authentication of Perplexity. The owner runs `pplx auth login` or sets `PERPLEXITY_API_KEY` themselves; this change only adds the binary and the conditional routing.
- No removal of the built-in WebSearch or the citelock citation flow. pplx augments them; it does not replace them.
- No change to the other harness skills (writing-*, search-code-routing, etc.) beyond the web-research routing rule.
- No retroactive rewrite of archived changes' tasks.md into the new phase shapes.

## Capabilities

### New Capabilities
- `adversarial-review-gating`: the adversarial-review gate is default-on but owner-gated; the skill elicits approve/deny at slice entry, and a deny is recorded rather than silently skipped.
- `task-phase-shapes`: a plan phase declares a `loop` or `graph` shape with the required fields (loop: gather/act/verify steps, stop condition, max-iteration cap; graph: subtasks with `deps:` edges), enforced by `specreview.sh`.
- `pplx-web-research`: the `pplx` CLI is installed via overlay, exposed through a `pplx-cli` skill, and external web research is routed to pplx when authed and to WebSearch otherwise, never to pplx for internal/private content.

### Modified Capabilities
<!-- none: these are new capabilities; the schema and skills are implementation surfaces, not existing openspec/specs/ capabilities -->

## Impact

- Affected code: `openspec/schemas/rosh-spec-driven/schema.yaml`, `openspec/schemas/rosh-spec-driven/templates/tasks.md`, `openspec/schemas/rosh-spec-driven/CHANGES.md`, `modules/home/programs/llm/skills/adversarial-review.nix`, `modules/home/programs/llm/citation-tools/specreview.sh`, a new `overlays/pplx.nix` + its entry in `overlays/default.nix` and the `cacheAttrs` list, a new `modules/home/programs/llm/skills/pplx-cli.nix` + registration in `skills/default.nix`, and the web-research routing text in the openspec-workflow / citation-verification skills.
- Progressive rollout: three independently reviewable slices — (1) adversarial-review gating, (2) task-phase-shapes, (3) pplx tooling + routing. Each ends green at `nix flake check` + `nh darwin build`, and each skill/schema edit is verifiable by `openspec schema validate rosh-spec-driven` and `task openspec:sync`.
- Impactful actions requiring human checkpoints: `nh darwin switch` per slice; regenerating `AGENTS.md` / skill outputs; fetching the pplx release binary hashes (vendored-content add); `git push` to `main`. The pplx binary is a new external dependency and its per-platform hashes must be pinned.
- Gating signal: `nh darwin build` (verify) before `nh darwin switch` (apply). The pplx routing has a natural runtime gate: the `pplx auth` / `PERPLEXITY_API_KEY` check, which defaults the behavior to WebSearch when unauthenticated (the current state on this machine).
- External-factual claims: the design references Anthropic's agent-design patterns (Building Effective Agents; the Agent SDK gather/act/verify loop). Those claims MUST be anchored via `citations.lock` + `citelock` per the schema's rule 5 before the design is finalized.
