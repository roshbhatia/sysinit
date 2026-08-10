## Rubric

The proposal `Behavior` criteria, the proposal `Non-goals`, and the design
`Decisions`. An objection citing none of these is out of scope.

## Recommendation

Decision: not-run approved

The owner approved this change on 2026-08-09, in session, in their own words:
"approve decompose-wezterm-ui". The approval is of the change being opened and
runnable. It is not a review of the phases below, which do not exist yet in any
detail: phase 2's boundary is scoped by task 1.2's measurement, which has not
run.

Recommendation: hold, overridden by the decision above

Reasoning:

- The rendering paths have no automated coverage. Design decision 4 accepts an
  owner-run confirm rather than inventing a gate, and whether that is an
  acceptable trade is the owner's call, not the author's.
- Phase 2's boundary rests on task 1.2's measurement, which has not run. Scoping
  the remaining phases before that measurement exists would be guessing.

## Risks

- A wrong extraction reaches the owner as a broken tab bar rather than as a
  failing check.
- Splitting closures turns implicit shared state into explicit arguments, and
  the derivation-path gate cannot see a wrong choice there.

## Open questions

- Whether the lua tree installs file by file or as a directory, which task 1.3
  answers.
- Whether one mux walk with two reducers is actually cheaper than two walks.
