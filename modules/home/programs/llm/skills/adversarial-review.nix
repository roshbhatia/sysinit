''
  Run an adversarial review: independent critics try to BREAK an artifact
  (plan, spec, design, or code), the author revises against surviving
  objections, and the loop repeats until nothing survives. This is the
  refutation loop, not a politeness pass. The full methodology and its
  citations live in `references/adversarial-review-methodology.md` — read it
  before running the loop the first time.

  ## When to run

  - At the rosh-spec-driven review gate: before a `tasks.md` slice is marked
    done, and to satisfy the design `Adversarial Review` section.
  - When asked to "adversarially review", "try to break this plan", or "red-team
    this design".
  - MUST NOT run as a same-instance self-review. An adversary MUST be a separate
    instance or a different model (see the reference: unaided self-correction
    degrades quality).

  ## Pick the execution path (harness-aware)

  Check the environment in this order and take the first match:

  1. **Already a critic** — `$CLAUDE_CODE_CHILD_SESSION` is set. You are a
     teammate or subagent spawned for review. Do NOT spawn more critics
     (recursion guard). Produce your own objection and return.
  2. **Claude Code with Agent Teams** — `$CLAUDECODE` is set AND
     `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is `1`. Spawn N=3 in-process
     teammates as adversarial critics, one per lens.
  3. **Any harness with subagents** — a Task/Agent subagent mechanism exists.
     Spawn N=3 critic subagents (fresh context each).
  4. **No sub-agent capability** — run N=3 sequential critique passes, each in a
     fresh reasoning context with authorship hidden.

  Detect the harness with a shell check, e.g.
  `printenv CLAUDECODE CLAUDE_CODE_CHILD_SESSION CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

  ## The loop (summary — reference has the sourced detail)

  1. **Bind the rubric.** For an OpenSpec change, the rubric is the spec
     scenarios (including the required negative scenarios), the design
     `Decisions` and `Rollout & Gating`, and the proposal `Non-goals`. A critic
     MUST cite the specific rubric item it believes is violated.
  2. **Spawn N=3 independent critics**, authorship hidden, one lens each (rotate
     across rounds: correctness, security, ops/rollback, cost, data-migration).
     Each critic contract: "Produce a concrete scenario in which this artifact
     fails. Name the violated rubric item. If you cannot, reply `NO SURVIVING
     OBJECTION`."
  3. **Keep only objections with a concrete failing scenario** — reproducible
     conditions or an isolated verification question. Reject prose-only comments.
  4. **Revise** the artifact against surviving objections only. The author
     revises; a critic never both blesses and rewrites unaided.
  5. **Repeat.**

  ## Stop

  - STOP when a full round returns `NO SURVIVING OBJECTION` from all N critics.
  - HARD CAP at K=4 rounds; report unresolved objections if the cap is hit.
  - An objection "survives" a round if a majority of critics uphold it on
    re-examination.

  ## Output

  Report, in order: the rubric bound, each round's surviving objections (with
  their failing scenarios), the revisions applied, and the terminal state
  (`no surviving objection` or `hit K=4 with N open objections`). Do not pad a
  clean result with invented objections — a critic that finds nothing MUST say
  so.
''
