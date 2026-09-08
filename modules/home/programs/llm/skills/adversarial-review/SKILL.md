---
description: 'Runs one adversarial review pass: fresh-context critics try to break an artifact, a mediator tries to disprove each finding, the ledger drops what it cannot anchor, and the author fixes what survived. Use at the spec-driven review gate or when asked to red-team a plan, spec, design, or code.'
allowed-tools: Agent Read Grep Glob Bash(review:*) Bash(specutil:*) Bash(git diff:*) Bash(git log:*) Bash(calldiff:*)
---

One pass, bounded by a ledger, not a loop bounded by prose. `review` keeps the
record and the `review-gate` hook enforces it: a critic cannot spawn outside an
open pass, past the tier's count, or as an agent type that can write. The
method and its citations are in `references/adversarial-review-methodology.md`.

## Recursion guard

If your own instructions carry `ADVERSARIAL-CRITIC-ROLE`, you are a critic:
produce one objection and return. If they carry `ADVERSARIAL-MEDIATOR-ROLE`,
you are the mediator: adjudicate and return. Neither spawns anything; the hook
denies it anyway.

## The pass

1. `specutil check <change-dir>` first. It is deterministic and cheap; fix
   every violation before anything else.
2. `review open --change <change-dir>`. It measures the diff against the merge
   base, picks the tier from the owner's policy, and records pass 1. A
   `trivial` change records `NOT_RUN` and you are done. The status line names
   how many critics the change earned.
3. Spawn that many critics, one lens each (correctness, security,
   ops/rollback, cost, data-migration, citation), as fresh-context read-only
   `Explore` agents. Every critic prompt opens with the literal line
   `ADVERSARIAL-CRITIC-ROLE: do not spawn further critics.` and carries the
   rubric: the proposal's `Behavior` criteria and `Non-goals`, the design
   `Decisions` and `Rollout & Gating`. The hook tells each critic which
   revision is under review; you do not. Contract: "Produce a concrete
   scenario in which this artifact fails and the rubric item it violates. If
   you cannot, reply `NO SURVIVING OBJECTION`."
4. Spawn the `review-mediator` agent with `ADVERSARIAL-MEDIATOR-ROLE` and every
   objection. It tries to disprove each one against the current files, then
   writes its verdicts as JSON to the pass file the hook names
   (`.gate/review/pass-N.json`).
5. `review judge`. The ledger drops any ACCEPT or REFRAME with no scenario, no
   disproof attempt, or a `file:line` that does not resolve inside the change;
   nits do not count. The state it prints is the result:
   - `CLEAN`: nothing actionable survived. Model evidence, not approval.
   - `REVISE`: fix the ACCEPT and REFRAME findings. Then, once, if the tree has
     changed, `review reopen` starts pass 2 and repeats from step 3.
   - `HANDBACK`: a DEFER or a blocking finding. Stop and hand the owner
     `review status --md`; the open items are theirs.
   - `CAPPED`: the last allowed pass still has actionable findings. Hand back
     the same way. There is no pass 3.
6. Paste `review status --md` into the change's `review.md` and record the
   phase checkbox from it.

## Rules the hook does not carry

- The author revises. Neither a critic nor the mediator edits the artifact.
- Chasing every finding over-engineers the work. A critic asked for gaps will
  report some; the judge is there to drop the ones that do not threaten a
  `Behavior` criterion or a `STOP` condition.
- `review halt` is the owner stopping early. Open findings stay recorded.
- Report the state word, the tier and its rule, and the open list. Never
  present `CAPPED` or `HANDBACK` as a pass, and never write owner or peer
  approval from a `CLEAN`.

<examples>
<example>
<bad>Round 3 found nothing, so the change is approved.</bad>
<good>review CLEAN: tier lite (48 lines and 3 files), pass 1/2, actionable per pass [0]. Model evidence, not owner approval.</good>
</example>
<example>
<bad>Spawn one more critic to be sure.</bad>
<good>The ledger says pass 1 spawned its critic; the next step is the mediator, then `review judge`.</good>
</example>
</examples>
