# Review decision: flatten-review-to-one-session

## Rubric

- `proposal.md` `Behavior`, every WHEN/THEN pair including the four negative
  scenarios.
- `proposal.md` `Non-goals`, in particular that no multi-repository view survives.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines. The two that
  carry the change are keeping codediff and running one session at a time.
- `design.md` `Rollout & Gating`, in particular that the focus claim needs five
  consecutive runs in a real pane rather than one.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

Every factual claim in `proposal.md` and `design.md` is about a file in this
repository, an installed plugin under `~/.local/share/nvim/lazy/`, or measured
output on this machine. None is external-factual, which is why `citations.lock`
carries no records rather than being absent.

## Deterministic lint

Recorded per phase as each closes.

| Check | Result |
| --- | --- |
| `specutil check` | pass, at the plan gate |

## Adversarial critique: not run, per phase

Recorded per phase as each closes. The policy is the same one the archived change
recorded and the same reason: the defects this surface produces are timing and
plugin-contract behaviours that reading a diff cannot show. The measurement that
motivated this change is itself the example, since the code that lost the focus race
in a WezTerm pane passed every headless run.

## Rounds

None run.

## Owner decision

Decision: not-run approved
State: NOT-RUN

2026-08-12: approved. The plan was put to the owner with the alternatives priced,
including dropping codediff for a quickfix list with built-in diff mode, and
approved in session ("i approve. then proceed"). Critics NOT-RUN under the same
direction, against a plan whose review tasks say to run critics only when requested
or risk-justified. Neither applied.
