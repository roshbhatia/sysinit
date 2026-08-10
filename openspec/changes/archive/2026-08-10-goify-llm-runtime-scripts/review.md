## Rubric

The proposal `Behavior` criteria, the design `Decisions` and their rejected
alternatives, the design `Rollout & Gating` sequence, and the proposal
`Non-goals`. An objection citing none of these is out of scope.

## Recommendation

Recommendation: run

Reasoning:

- Phase 6 rewrites `bash-guard` and `exit-code-guard`, which sit on the deny
  path. Their failure mode is to fail open, which is silent: a permitted-by-
  mistake command runs and nothing reports it. `checks/destructive-guard-fixtures.nix`
  proves the cases it knows about and cannot prove the absence of a hole. This
  is the concrete risk, and it is the kind a critic reading only the diff finds
  better than the author who just wrote it.
- `internal/store` carries the locking and atomic-publish logic that every later
  phase depends on. Its shell original accumulated seven documented defects over
  time, each found in production rather than in review. A rewrite that reproduces
  the API without reproducing the hard-won behavior would pass its own tests,
  because the tests are written by the same author from the same reading.
- Against running: phases 1 to 5 are mechanical, well covered by existing
  `checks/` derivations, and reversible by a single commit revert. Critique
  there would mostly restate the checks.

So the useful shape is not "review the change" but "review two slices": the
deny path in phase 6, and `internal/store` in phase 1. Scoping it that way keeps
the cost proportional to the risk.

## Owner decision

Decision: run approved
Decided by: owner (roshan), stated in session 2026-08-06
Date: 2026-08-06

Scope approved as recommended: two slices, not the whole change. Phase 6
`bash-guard` / `exit-code-guard` (deny path fails open), and phase 1
`internal/store` (its shell original accumulated defects found in production,
not in review).

## Deterministic lint

`specutil check --change goify-llm-runtime-scripts`: pending re-run after this
artifact lands. It passed at `d758d4c70`, before `review.md` existed.
`citelock verify openspec/changes/goify-llm-runtime-scripts`: exit 0, offline
gate passed against an empty `records` list.

The empty lock is correct rather than a shortcut. Every quantity the proposal
asserts is about this repository (`3,646` lines across 30 scripts, `diffnote.sh`
at 510 lines with 23 `jq` invocations, `citelock.sh` at 395 with 17) and a
command decides each one. Nothing here depends on a third party's published
fact, so there is nothing to pin.

## Rounds

None yet. The loop does not start until the owner records a decision above.

## Terminal state

State: pending
Rounds run: 0
Surviving-objection trend: n/a

## Open objections

None recorded yet.
