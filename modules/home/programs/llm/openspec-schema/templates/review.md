## Rubric

<!-- What the plan is judged against. Name the sources, do not restate them:
     the proposal `Behavior` criteria, the design `Decisions` and their rejected
     alternatives, the `Rollout & Gating` sequence, and the proposal `Non-goals`.
     An objection that does not cite a rubric item is out of scope. -->

## Recommendation

<!-- REQUIRED, and written before any critic runs. State whether model critique
     should run for THIS change, and why, so the owner is deciding against an
     argument rather than a blank. Name the concrete risk that critique would
     catch, or say plainly that there is none. Both answers are acceptable; an
     absent recommendation is not. -->

Recommendation: <run | do not run>

Reasoning:
- <the specific risk critique would surface, or why none exists>

## Owner decision

<!-- ONLY the owner fills this in. An agent MUST NOT write a decision here, and
     MUST NOT infer one from silence. `NOT-RUN` is not self-certifiable: the
     whole point of this section is that skipping adversarial review is the
     owner's call, not the author's. -->

Decision: <pending | run approved | not-run approved>
Decided by: <owner>
Date: <YYYY-MM-DD>

## Deterministic lint

<!-- Always runs, regardless of the decision above. This is evidence, not
     approval. -->

`specutil check --change <name>`: <exit code and summary>
`citelock verify <change-dir>`: <exit code>

## Rounds

<!-- One block per round. Omit entirely when the owner approved not-run.
     A claim with no reproducible failing scenario is discarded at step 3 of the
     loop, so every surviving finding here MUST carry one. -->

### Round <n>

<!-- A surviving finding still needs a disposition. Being real is not the same
     as being worth fixing here, and treating the two as one is what turns a
     review into an unbounded backlog.

     FIX means it threatens a proposal `Behavior` criterion or a phase `STOP`
     condition. Only FIX findings may reopen the loop.
     LOG means it is real, it does not threaten either, and it is written down
     and left. A logged finding is a result, not a failure to act.
     DEFER means it belongs to work outside this change; name where it went. -->

| Critic lens | Finding | Failing scenario | Verdict | Disposition |
| --- | --- | --- | --- | --- |
| <correctness / security / rollout / reuse> | <the objection> | <inputs or state that produce the wrong outcome> | SURVIVED / REFUTED | FIX / LOG / DEFER |

Revision: <what the author changed, against FIX findings only>
Surviving after revision: <n>

## Terminal state

<!-- One of: pending, CLEAN, CAPPED, STALLED, CHURNING, NOT-RUN.
     `pending` is the pre-run state: the artifact exists and the loop has not
     started, which is where a review sits while it waits on the owner.
     CLEAN means no critic objection survived. It is not owner approval and it
     is not peer approval. CAPPED, STALLED, and CHURNING all hand back with open
     work. See the `adversarial-review` skill for the state machine. -->

State: <pending | CLEAN | CAPPED | STALLED | CHURNING | NOT-RUN>
Rounds run: <n>
Surviving-objection trend: <n, n, n>

## Open objections

<!-- Everything still standing at hand-back. "None" is a valid answer only when
     the terminal state is CLEAN or NOT-RUN. A CAPPED or STALLED review with no
     open objections listed is a contradiction and `specutil check` should be
     able to say so. -->

- <objection, and what it blocks>

## Logged, not fixed

<!-- Findings dispositioned LOG or DEFER. They are real and they are recorded
     here so nobody rediscovers them, and this change does not act on them.
     Leaving this empty when every finding was FIX is correct. -->

- <finding, and why it does not threaten a criterion or a stop condition>
