## Rubric

<!-- What the plan is judged against. Name the sources, do not restate them:
     the proposal `Behavior` criteria, the design `Decisions` and their rejected
     alternatives, the `Rollout & Gating` sequence, and the proposal `Non-goals`.
     An objection that does not cite a rubric item is out of scope. -->

## Tier

<!-- Computed by `review open`, never chosen. Paste its status line: the tier,
     the rule that fired (lines and files, or the sensitive path), and the
     critic count the tier earned. A `trivial` tier is `NOT_RUN` and needs no
     signature: the owner decided the thresholds once, in the gate policy. -->

## Deterministic lint

<!-- Always runs, regardless of the tier. This is evidence, not approval. -->

`specutil check --change <name>`: <exit code and summary>
`citelock verify <change-dir>`: <exit code>

## Passes

<!-- At most two. Pass 1 always; pass 2 only when the tree changed after the
     fixes and `review reopen` allowed it. Paste `review status --md` after
     each judge; the ledger holds the findings and their verdicts, so do not
     restate them here. -->

## Terminal state

<!-- One of: OPEN, REVISE, CLEAN, HANDBACK, CAPPED, HALTED, NOT_RUN. CLEAN
     means no actionable finding survived the judge. It is not owner approval
     and it is not peer approval. HANDBACK carries a DEFER or a blocking
     finding for the owner. CAPPED is the last pass with open findings. -->

State: <from `review status`>
Passes run: <n> of <cap>
Actionable-finding trend: <n, n>

## Open findings

<!-- Everything still standing at hand-back. "None" is a valid answer only when
     the state is CLEAN or NOT_RUN. -->

- <finding, and what it blocks>
