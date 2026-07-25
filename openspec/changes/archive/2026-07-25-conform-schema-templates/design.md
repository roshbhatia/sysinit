## Context

`openspec new change` copies `openspec/schemas/rosh-spec-driven/templates/` into the new change directory. Those templates predate the schema rules added by `spec-driven-workflow-upgrades` and `add-citation-verification`: required design sections, a per-slice adversarial-review checkbox, and a declared-negative scenario per requirement. The rubric now runs as `specutil check`, which made the gap visible as five concrete errors rather than as prose drift.

## Goals / Non-Goals

Goals:
- A scaffolded change is a conforming starting point
- The invariant is enforced mechanically, not by memory

Non-Goals:
- Any rubric change
- Any edit to already-archived changes

## Decisions

- Decision: fix the templates rather than relax the rules
  - Alternative rejected: allowlist the bullet style and drop the required sections, so the existing templates pass. Rejected because the rules encode decisions the schema made deliberately, and the templates are the cheaper thing to move.
- Decision: assert the invariant with a flake check that scaffolds and lints
  - Alternative rejected: a comment in each template telling authors to keep it conforming. Rejected because a comment is not a gate, and this exact drift already happened once unnoticed.
- Decision: keep the schema instruction prose as it is
  - Alternative rejected: rewrite its `- **Section**:` bullets to match the artifact rule. Rejected because the instruction describes the schema to a reader rather than modelling artifact output, and rewriting roughly forty bullets is churn with regression risk.

## Rollout & Gating

One slice, documentation and check only. The gate sequence is: edit the templates, scaffold a probe change and lint it, add the flake check, confirm the check fails when a required section is removed and passes when it is restored. No `nh darwin switch` is required because the templates are read from the repository, so there is no kill switch to name.

## Risks / Trade-offs

- The check could pass while the templates still mislead an author in ways the rubric does not encode. Mitigation: the rubric is the contract; anything it does not encode is not enforced anywhere, and that gap is a rule question rather than a template question.
- A future rule could make the templates non-conforming again. Mitigation: that is exactly what the new check reports, at evaluation time.

## Migration Plan

No migration. Existing changes are unaffected; the templates seed new changes only.

## Adversarial Review

Reviewed against the spec scenarios below, the decisions above, the gating sequence, and the proposal non-goals. The deterministic `specutil check` gate runs on this change. The critic loop is owner-gated per the `adversarial-review` skill.

## Open Questions

None.
