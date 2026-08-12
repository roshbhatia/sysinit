## Rubric

- `proposal.md` `Behavior`, every WHEN/THEN pair including the five negative
  scenarios.
- `proposal.md` `Non-goals`, in particular the claim that the editor-to-agent
  direction is finished work rather than deferred.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines.
- `design.md` `Rollout & Gating`, including the one named deviation from the
  default gate sequence.
- `design.md` `Open Questions`, which the plan deliberately leaves unsettled.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

## Deterministic lint

Run 2026-08-11, before any critic.

| Check | Result |
| --- | --- |
| `specutil check` | pass for all 3 changes, once the decision below was recorded |
| `citelock verify openspec/changes/add-agent-edit-bus` | pass, offline gate, 0 records |
| `spec-preflight all` | pass on citations, review decision, and Behavior present with 24 entries |
| `specutil render add-agent-edit-bus --as tickets` | renders every subtask whole, with `kind:apply` and `kind:confirm` extracted |
| `openspec validate add-agent-edit-bus --type change` | fails `at least one delta`, as do both sibling changes. Pre-existing: this repository does not promote to `openspec/specs/`, so no change here has ever carried a delta |

Every factual claim in `proposal.md` and `design.md` is about a file in this
repository, an installed store path, or a live state file on this machine. None
is external-factual, which is why `citations.lock` carries no records rather
than being absent. Those claims are verifiable by reading the cited path, and a
critic should read rather than trust them.

## Recommendation

Model critique SHOULD run, and the highest-value lens is not correctness.

The strongest risk is that the plan describes work that is already done. This
change was rewritten once for exactly that reason: the first proposal built a
Neovim IDE host for copilot and amp, and reading `harness/api.lua:158-178`
showed `send_review` already delivers annotations to every harness through
`adapter.send`, which removed roughly half the original scope. A critic should
assume the same error remains somewhere and look for it, starting with the
touched-set requirement in phase 3: `review.nvim` may already scope a diff to a
file list, which would collapse phase 5 into a configuration line.

The second risk is the capability claim in phase 4. Five of six hook surfaces
are unverified, and the plan's own answer is to record `false` rather than
approximate. A critic should check that no task quietly widens that: the
rejected `git status` polling fallback is exactly the shape a well-meaning
implementation would reach for.

The third risk is the reader's data-loss path. The `modified` check before a
reload is the only thing standing between an agent write and the owner's
unsaved buffer, and `checktime` today has Neovim's own conflict prompt behind
it. A critic should ask whether the new path preserves that prompt or replaces
it with something quieter.

Two risks a critic would NOT catch:

- Whether the touched set is worth the machinery at all, versus continuing to
  open the full working diff. That is task 5.5 and it is the owner's judgement.
- The size bound and retained-line count. Task 6.1 sets them from a measurement,
  and measuring settles it faster than any critic.

Suggested lens set: already-implemented, capability-overclaim, and
buffer-data-loss. Three critics, fresh context, read-only.

## Rounds

None run.

## Owner decision

Decision: not-run approved
State: NOT-RUN

2026-08-11: approved. Critics NOT-RUN at the owner's explicit direction, stated
in session ("do what you think is best for all. i approve"). The three risks
named under Recommendation stay open and unexamined. The already-implemented
risk is the one that has already materialized once in this change's history, and
phase 5 is where it would surface again.
