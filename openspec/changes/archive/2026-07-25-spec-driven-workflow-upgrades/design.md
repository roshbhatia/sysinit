## Context

Three surfaces of the rosh-spec-driven workflow change here, all already established in the repo:

- Adversarial review: the `adversarial-review` skill (`modules/home/programs/llm/skills/adversarial-review.nix`) already separates a deterministic `specreview` lint (`modules/home/programs/llm/citation-tools/specreview.sh`) from the LLM critic loop. `schema.yaml` mandates the loop per slice. This change gates the loop (not the lint) behind owner approval.
- Task shapes: `templates/tasks.md` and the `schema.yaml` tasks instruction currently model a plan as linear numbered slices of checkboxes. `specreview.sh` enforces declared markers (`- **POLARITY**`, adversarial-review checkbox, Decision/Alternative rejected). This change adds two declared phase shapes and extends `specreview.sh` the same way. The shapes mirror well-known industry patterns: a `loop` is the gather-context → act → verify cycle (evaluator-optimizer style); a `graph` is orchestrator-worker fan-out over subtasks with dependency edges.
- External research: overlays already fetch per-platform release binaries (`overlays/localias.nix`, `overlays/crush.nix`) and skills already do external fact capture via `citelock` (`citation-verification` skill, Tier 1 capture). This change adds `overlays/pplx.nix` on the same fetch pattern and routes external research to pplx when authed.

## Goals / Non-Goals

**Goals:**
- Make the critic loop owner-gated (default on), record a waiver, keep `specreview` mandatory.
- Give a plan phase a first-class `loop` or `graph` shape, validated by `specreview`.
- Install `pplx` and route external web research to it when authed, WebSearch otherwise.

**Non-Goals:**
- No fork of the openspec CLI's checkbox tracking; shapes live in schema data + `specreview`.
- No auto-authentication of Perplexity; the owner authenticates.
- No removal of WebSearch or the citelock flow; pplx augments them.
- No quantified external-factual claims about the Anthropic patterns, so no `citations.lock` is required for this change.

## Decisions

- Decision: Gate only the LLM critic loop; keep `specreview` mandatory and unconditional.
  - Rationale: `specreview` is a pure, cheap function of the artifacts; the expensive, non-deterministic part is the critic loop. Gating the cheap lint would remove the reproducible floor.
  - Alternative rejected: gate the whole review (lint + loop). Rejected because it lets a slice skip even the deterministic rubric checks, which are the stable safety net.

- Decision: Express the waiver as a normal checkbox (`- [x] X.N Adversarial review: waived by owner`).
  - Rationale: `specreview`'s existing per-slice check matches any checkbox mentioning "adversarial review", so a recorded waiver satisfies the lint without a code change to that check, and the decision stays visible in `tasks.md`.
  - Alternative rejected: delete the review checkbox when waived. Rejected because a missing checkbox is indistinguishable from a forgotten one and fails `specreview`; the waiver must be explicit.

- Decision: Model phase shape as a declared marker (`- **SHAPE** loop|graph`) plus shape-specific markers (`- **STOP**`, `- **MAX-ITERS**`, `deps:`), validated by `specreview` in awk.
  - Rationale: matches the repo's declared-fact philosophy (specreview checks stated facts, never inferred prose) so validation stays deterministic and reproducible.
  - Alternative rejected: infer the shape from task wording. Rejected because inference is non-reproducible and contradicts how `specreview` is designed.
  - Alternative rejected: fork openspec to parse shapes as structured fields. Rejected per Non-goals; the CLI only tracks checkboxes and the schema is data.

- Decision: Graph validation checks dependency resolution (every `deps:` id exists), not full cycle detection.
  - Rationale: dangling-edge detection is a simple, deterministic awk check that catches the common authoring error; the DAG is small and human-reviewed.
  - Alternative rejected: full topological cycle detection in bash/awk. Rejected as heavy and error-prone for marginal gain at this scale; a cycle is visible in review.

- Decision: Package `pplx` as a per-platform prebuilt binary from the v0.2.2 release, hashes pinned.
  - Rationale: it ships as a signed binary release (no build), matching `localias`/`crush`. Assets and SRI hashes are known: darwin `sha256-6XZHj8/sUfNvWw8o1kd+oEIyMpQoTgawKi6bGzOcF3M=`, linux-arm `sha256-NfjfUxS2TupXONNuhTG4DgKeyvno3h1jF+XzsPZknqQ=`, linux-x86 `sha256-F+SP9yiuqaS5dptqCEQnq6lejhikPEvJxYR9BUw4tME=`.
  - Alternative rejected: build from source. Rejected because upstream ships only binaries; there is no public build path.
  - Alternative rejected: nvfetcher. Rejected because nvfetcher would auto-advance the pin on each release, and the owner wants a deliberate version bump for a research tool.

- Decision: Route external research to pplx only when `pplx auth`/`PERPLEXITY_API_KEY` is present; default to WebSearch.
  - Rationale: the machine is currently unauthenticated, so WebSearch must stay the zero-config default; the check is a runtime gate the agent performs.
  - Alternative rejected: always prefer pplx. Rejected because it would break research on an unauthenticated machine (the current state).

- Decision: Enforce only the mechanical parts of the writing standard in `specreview` (em-dashes, disallowed bolded bullet leads); state the full standard in prose.
  - Rationale: em-dash and bold-lead checks are deterministic string patterns that fit `specreview`'s stated-fact philosophy. Sentence-length and one-term-per-concept need judgment and belong in the human/critic review, not a bash lint.
  - Alternative rejected: enforce sentence-length caps in `specreview`. Rejected because a reliable sentence tokenizer in bash is fragile and would produce false positives on code, paths, and lists.
  - Alternative rejected: leave the standard as prose guidance only. Rejected because a mechanical check catches the two most common violations at zero judgment cost, as the em-dash slip in this change's own tasks.md showed.

## Rollout & Gating

Three independently shippable slices, each ending green at `nix flake check` + `nh darwin build`, then a spot-check, then `nh darwin switch`.

1. adversarial-review-gating: edit the skill (elicitation) and `schema.yaml`/`CHANGES.md`; `specreview` unchanged. Gate: `openspec schema validate rosh-spec-driven` + `task openspec:sync` clean; the skill still runs the loop on approve.
2. task-phase-shapes: extend `templates/tasks.md`, the `schema.yaml` tasks instruction, `CHANGES.md`, and `specreview.sh`. Gate: `specreview` accepts a well-formed loop and graph slice and rejects a shapeless / stop-less / dangling-dep slice (unit-check against fixtures) before switch.
3. pplx-web-research: add `overlays/pplx.nix` (+ `default.nix` entry + `cacheAttrs`), the `pplx-cli` skill (+ `skills/default.nix`), and the routing text. Gate: `nh darwin build` resolves `pplx` on PATH; `pplx auth` reports unauthenticated and the routing falls back to WebSearch.

Default gate sequence per slice: edit → `nix flake check` → `nh darwin build` → spot-check → `nh darwin switch`. Kill switch: each slice is a revertible commit; the pplx routing self-disables when unauthenticated.

## Risks / Trade-offs

- [A waived critic loop lets a real defect through] → `specreview` still runs; the waiver is recorded and visible in `tasks.md` for audit. Human checkpoint: the owner owns the waive decision.
- [specreview awk changes reject valid existing tasks.md files] → The shape markers are additive and only enforced on new changes; test the extended `specreview` against the archived `nix-idiom-cleanup` tasks.md (no shape markers) and confirm it is not retroactively failed, or scope the shape checks to slices that opt in. Human checkpoint before switch.
- [pplx binary hash drifts or the release is re-cut] → hashes are pinned to v0.2.2; a mismatch fails the build loudly. Bump deliberately.
- [pplx used for private content by mistake] → the skill states an explicit prohibition and the routing rule; the negative spec scenario encodes it. Residual risk is agent adherence, mitigated by the skill text.

## Migration Plan

Per slice, in order:
1. Verify current state green: `nix flake check` on `main`.
2. Apply the slice edits.
3. Verify: `nix flake check`; for slice 2 also run `specreview` against pass/fail fixtures; for slice 3 also `nh darwin build` and confirm `pplx` on PATH.
4. Confirm: owner spot-checks; for slice 2 confirm the extended `specreview` does not retroactively fail the archived change.
5. Apply (impactful): `nh darwin switch` after step 4 confirms.
6. Rollback: `git revert` the slice commit and re-`nh darwin switch`.

## Adversarial Review

Rubric: the spec scenarios in all three capability specs (including the negative scenarios), the `Decisions` above (each with its rejected alternative), the `Rollout & Gating` gates, and the proposal `Non-goals`. Each slice runs the deterministic `specreview` lint, then the owner-gated critic loop per the `adversarial-review` skill: independent critics attempt to break the slice with a concrete failing scenario naming a violated rubric item, the author revises against surviving objections, repeating until no objection survives or K=4 rounds. Executor per the skill: in-process teammate critics under Claude Code, subagents elsewhere. Because this change itself introduces the owner gate, the owner MAY waive the critic loop on a small slice; the waiver is recorded. Per-slice checkmarks live in `tasks.md`.

## Open Questions

- Should the shape markers be required on every slice immediately, or opt-in for one release so archived and in-flight changes are not retroactively failed by `specreview`? Leaning opt-in first (see the Risks mitigation).
- Should `pplx content fetch` become the default citelock capture fetcher when authed, or stay an explicit opt-in per capture? Leaning opt-in to keep captures reproducible across authed/unauthed machines.
