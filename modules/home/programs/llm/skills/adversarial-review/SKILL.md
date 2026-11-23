---
name: adversarial-review
description: Red-team a concrete plan, design, spec, or code change. Use for an explicit adversarial review that tests a named revision against its acceptance criteria.
allowed-tools: Read Grep Glob Bash(review policy:*) Bash(review status:*) Bash(git diff:*) Bash(git log:*) Bash(calldiff:*)
---

# Adversarial review

Use a stable revision and a rubric that names the required behavior,
invariants, and stopping conditions. Run the checks that can answer those
questions directly. Carry relevant failures and missing evidence into the
review.

## Select the supported workflow

Check the [harness requirements](references/harnesses.md) before running
`review open`. A judged pass requires authorized delegation, the native
read-only critic and mediator roles, and the active `review-gate` hooks.
If any prerequisite is missing, report that the judged pass is unavailable,
name the missing prerequisite, and describe the direct validation you can
perform. Reserve ledger state words for recorded passes.

An agent given `ADVERSARIAL-CRITIC-ROLE` or `ADVERSARIAL-MEDIATOR-ROLE`
returns its assigned evidence to the coordinator. The coordinator owns
the ledger, any artifact changes, and the final report.

## Run the pass

1. Run `review open --change <change-dir>`. Use the tier and critic count
   it reports. A trivial tier records `NOT_RUN`.
2. Start the authorized critics in fresh read-only contexts. Give each
   `ADVERSARIAL-CRITIC-ROLE`, one distinct failure lens, the scope and
   rubric, and the gate's revision context. Ask for a concrete failing
   scenario, the violated criterion, and a changed-file line. An
   unsuccessful attempt to disprove the behavior can return
   `NO SURVIVING OBJECTION`. A missing critic result leaves the pass
   incomplete.
3. Give the independent `review-mediator` the objections and rubric with
   `ADVERSARIAL-MEDIATOR-ROLE`. It attempts to disprove each claim against
   current files and returns a JSON list. The coordinator saves that list
   to the ledger's pass file and runs `review judge`. If the artifact
   changed during inspection, establish which revision the evidence covers
   before recording a result.
4. Use the ledger's result.

   | State | Action |
   | --- | --- |
   | `CLEAN` | Report the evidence for this revision. |
   | `REVISE` | Correct surviving findings in scope. `review reopen` can start the permitted follow-up on a changed tree. |
   | `HANDBACK`, `CAPPED` | Show the unresolved findings from `review status --md` and stop the pass. |
   | `NOT_RUN`, `HALTED` | Report the reason the pass ended without a verdict on the artifact. |

Report the revision, tier, state, and open findings. A ledger result
records model evidence. Owner and peer approval come from their respective
review processes. Write the status block into an existing review artifact
when the repository or user requests one.

See [methodology](references/adversarial-review-methodology.md) for the
rationale and limitations of independent critique.
