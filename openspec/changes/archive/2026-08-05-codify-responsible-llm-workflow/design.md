## Context

`instructions.nix` contains cross-repository rules. Skills contain domain rules.
The schema connects those rules to OpenSpec artifacts and review gates.

RFD 576 supplies the selected value model. This design translates it into
observable repository behavior without copying the source text into every file.

## Goals / Non-Goals

Goals:
- Make human responsibility explicit across all harnesses.
- Keep model critique distinct from approval.
- Preserve deterministic workflow gates.
- Keep policy near the mechanism that enforces it.

Non-Goals:
- Measure LLM usage.
- Require disclosure of model use.
- Add a new review service.

## Decisions

### D1. Put only invariants in global context

The global section covers ownership, evidence, maintainability, and handoff.
Skills retain detailed workflow rules.

- Alternative rejected: copy all RFD guidance into every context. It would exceed the context budget and duplicate skill policy.

### D2. Treat model critique as optional evidence

The critic loop can find defects, but its terminal state does not approve work.
The workflow records `not run`, `clean`, or the open-objection state.

- Alternative rejected: retain default-on review with `waived` language. That treats one optional tool as the expected path.

### D3. Keep deterministic checks mandatory

`specutil check`, tests, and format checks remain mechanical gates.

- Alternative rejected: make all review optional. Deterministic checks have stable cost and observable results.

### D4. Separate review records by authority

Review data distinguishes automation evidence, model critique, peer review, and
the owner decision. Only the relevant human can provide human approval.

- Alternative rejected: keep one generic review decision. It hides which authority made the decision.

### D5. Preserve authorship and iterative review

Writing tools preserve the user's supplied thesis. Code review responses use
targeted edits after the complete diff has been read.

- Alternative rejected: allow full regeneration during review. It prevents a reviewer from tracking the effect of feedback.

## Rollout & Gating

Phase 1 changes the global invariant and skill policy. Phase 2 changes the
schema and templates. Each phase runs `specutil check`, `nix flake check`, and
an explicit Darwin build before downstream rollout.

The kill switch reverts the responsibility section and schema policy before a
downstream configuration updates this flake.

## Risks / Trade-offs

- Optional critic runs may reduce review frequency. -> Deterministic gates remain mandatory, and the owner can select critique when it adds value.
- More review states can complicate `specutil`. -> Use explicit fields and keep existing records readable.
- Global context has a 45-line cap. -> Keep the responsibility section to six rules.
- The RFD can change after capture. -> `citelock` records the captured source and access date.

## Migration Plan

1. Change the global instruction and owned skills.
2. Change the schema, templates, and review vocabulary.
3. Run all deterministic checks.
4. Inspect the built contexts for the responsibility section.

Rollback reverts both policy phases before downstream rollout.

## Adversarial Review

Review this change against the proposal Behavior criteria, Decisions, rollout
gates, and Non-goals. Run `specutil check` first. The model critic is optional
evidence and cannot approve this change.

## Open Questions

None.
