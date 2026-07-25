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

  ## Owner gate (elicit before spawning critics)

  FIRST, the recursion guard takes precedence: if `$CLAUDE_CODE_CHILD_SESSION`
  is set you are already a critic, SKIP this entire owner gate and go straight
  to "Pick the execution path" path 1 (produce your objection and return). A
  critic never elicits and never runs the gate.

  Otherwise (a top-level review), the LLM critic loop is owner-gated; the
  deterministic `specreview` lint below is NOT. Before spawning any critics:

  1. Run `specreview <change-dir>` first regardless (it is cheap and pure). Fix
     every violation before offering the loop.
  2. Then elicit the owner's decision on the critic loop. In an interactive
     harness use the approve/deny prompt (AskUserQuestion under Claude Code);
     the DEFAULT is to run. Frame it per slice, e.g. "Run the adversarial critic
     loop for this slice? (default: yes)".
  3. On approve, run the loop as specified below.
  4. On deny, SKIP the critic loop and record the decision in the slice's
     review checkbox as `Adversarial review: waived by owner`. Do not leave the
     checkbox unmarked (indistinguishable from a forgotten one) and do not
     silently check it without the waiver note.
  5. Non-interactive / unattended runs (cron, CI, no TTY): default to running
     the loop; there is no owner to elicit, so the gate falls back to on.

  A waiver waives ONLY the critic loop. `specreview` must still pass, and the
  human-verification gates for impactful actions still apply.

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

  ## Deterministic rubric-lint first (`specreview`)

  Before spawning critics, run the deterministic half: `specreview
  <change-dir>` (installed on PATH). It checks only stated facts — every requirement has a
  declared-negative scenario (`- **POLARITY** negative`), design has the
  required sections, each `- Decision:` has an `- Alternative rejected:` marker,
  every slice has an adversarial-review step, `Non-goals` is present. This part
  is a pure function of the artifacts and is reproducible. The LLM refutation
  below is stabilized (pinned artifact snapshot, fixed rubric, fixed N and lens
  set, temperature 0, structured verdict, majority vote) but NOT
  bit-deterministic: two runs converge but are not identical. Do not claim
  otherwise. Fix every `specreview` violation before the critic loop.

  ## The loop (summary — reference has the sourced detail)

  1. **Bind the rubric.** For an OpenSpec change, the rubric is the spec
     scenarios (including the required negative scenarios), the design
     `Decisions` and `Rollout & Gating`, and the proposal `Non-goals`. A critic
     MUST cite the specific rubric item it believes is violated.
  2. **Spawn N=3 independent critics**, authorship hidden, one lens each (rotate
     across rounds: correctness, security, ops/rollback, cost, data-migration,
     citation). The `citation` lens adjudicates whether a pinned quote supports
     its claim (SUPPORTS / CONTRADICTS / UNRELATED over the snapshot); it MAY run
     only after the `citelock` offline gate (Tier 0) is green for the change.
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
