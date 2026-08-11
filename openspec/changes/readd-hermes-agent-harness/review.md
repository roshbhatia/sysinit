## Rubric

- `proposal.md` `Behavior`, both the "Must do" and the "Must still hold" lists.
- `proposal.md` `Non-goals`.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines.
- `design.md` `Rollout & Gating`, including the two named deviations from the
  default gate sequence.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

## Deterministic lint

Run 2026-08-10, before any critic.

| Check | Result |
| --- | --- |
| `specutil check --change readd-hermes-agent-harness` | 1 error: `review-decision-current`, expected until the owner records a decision below. No other rule failed. |
| `citelock verify openspec/changes/readd-hermes-agent-harness` | pass, offline gate, 11 records |
| `spec-preflight proposal` | pass on citations exists, valid, linked, fresh; Behavior present with 13 entries |
| `spec-preflight design` | pass, no rule failed beyond the pending review decision |
| `spec-preflight tasks` | pass, no rule failed beyond the pending review decision |
| `specutil render readd-hermes-agent-harness --as tickets` | renders every subtask whole, with `kind:confirm` extracted |

This is evidence. It is not approval.

## Recommendation

Model critique SHOULD run for this change, scoped to one concrete risk: the
package phase claims a negative property, and a negative property is the kind a
plan gets wrong quietly.

The claim is that `minimal` plus the `anthropic` extra pulls no member of the
speech stack. The evidence for it is upstream's own `[all]` membership list and
their stated policy, both pinned. What the evidence does not cover is the
transitive closure. `[all]` names nine extras, and any one of them could reach
`onnxruntime` or `torch` through a dependency this plan never read. The
`youtube` extra pulls `youtube-transcript-api`, and the `web` and `google`
extras pull their own trees. The plan's answer is the requisites grep in task
1.4, which is the right check, and a critic should attack whether that grep
covers the failure: it matches four names, and a transitively-pulled
`ctranslate2` variant under a different derivation name would pass it.

A second risk worth a lens: the plan asserts that no workflow in the pinned
upstream tree builds the Nix path, and it supports that with a method rather
than a citation, because an absence cannot be quoted. That reasoning is sound
and the method is stated, so a critic should test the method rather than the
conclusion. The grep covered `.github/workflows/` only. A build could be
triggered from a reusable workflow in another repository, or from a Cachix
watch-store agent outside CI entirely, and the substituter decision in
`design.md` turns on that being false.

Two risks a critic would NOT catch, named so the owner is not told the review
covers them:

- Whether the build time is acceptable. That is task 1.6 and it is the owner's
  judgement, not a finding.
- Whether `pablopunk/pi.nvim` style plugin coupling exists for hermes. This
  change writes a fresh adapter with no plugin dependency, so the risk lives in
  the sibling change instead.

Suggested lens set if the owner approves: closure-transitivity, upstream-drift,
and gate-coverage. Three critics, fresh context, read-only.

## Rounds

None run.

## Owner decision

Decision: not-run approved
State: NOT-RUN

2026-08-10: approved. Critics NOT-RUN at the owner's explicit direction, stated
in session. The three risks named under Recommendation stay open and unexamined;
the requisites grep in task 1.4 is the only check standing between this plan and
a closure-transitivity miss.

2026-08-10, later the same day: that approval no longer covers the plan.
Implementing phase 2 replaced task 2.4. The approved text said to restore the
hermes skill renderer; the pinned upstream version reads
`skills.external_dirs` instead, and no renderer is written. `specutil review`
reported the decision stale and named that one task as changed, so the decision
was set back to `pending` rather than carried forward. The owner was shown the
substitution and the evidence for it, approved it in session, and directed the
apply. The decision above is that re-approval, not the earlier one. Nothing else
in the plan changed.

Two further deviations, both recorded in `tasks.md` and neither reclassifying a
task:

- `context` is `~/.hermes/SOUL.md`, not `~/.hermes/config.yaml`.
- The linux half of task 1.4 was decided over the derivation closure, because
  lv426 has no linux builder. The criterion as written stays open.
