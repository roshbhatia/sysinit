# Adversarial review methodology (reference)

This reference grounds the `adversarial-review` skill in published methods. Every
citation was verified against arXiv. Read the skill's `SKILL.md` for the
operating procedure; read this file for the WHY and the exact loop.

## The loop

A generator proposes an artifact. Independent adversaries try to break it, and
the generator revises against surviving objections. Repeat until the loop
reaches one of six terminal states. No objection survives. Optional review is
not run. The owner halts it. The scaled round cap is hit. It stops early on
non-convergence or churn. Each step below names its source.

Model critique is optional unless the user or repository policy requires it.
After deterministic lint passes, a read-only mediator SHOULD recommend `RUN`
only when a concrete current-tree risk needs independent critique. It SHOULD
recommend `NOT_RUN` when deterministic evidence settles the risk or review
would add only preferences. This proportionality gate is an engineering cost
control, not a claim from the cited papers.

1. Propose. The generator produces the artifact (plan, spec, design, code).
   Source: Self-Refine (Madaan et al., 2023, arXiv:2303.17651).
2. Bind a rubric. Collect the artifact's acceptance criteria, invariants, and
   non-goals into a written rubric. A critic MUST cite a specific rubric item it
   believes is violated, not give a global score. Source: Constitutional AI
   (Bai et al., 2022, arXiv:2212.08073), principle anchoring.
3. Spawn N independent adversaries (default N=3). Each critic is a fresh
   instance or a different model, with the artifact's authorship hidden. Each is
   prompted to REFUTE: "Produce a concrete scenario in which this artifact fails.
   Name the rubric item it violates. If you cannot, reply `NO SURVIVING
   OBJECTION`." Source: Multiagent Debate (Du et al., 2023, arXiv:2305.14325)
   for independence. Anti-bias sourcing is in the failure-modes section.
4. Require a concrete failing scenario. An objection is valid only with
   reproducible conditions or a verification question answered in isolation,
   never prose vibes. Source: Chain-of-Verification (Dhuliawala et al., 2023,
   arXiv:2309.11495); LLM Critics Help Catch LLM Bugs / "CriticGPT" (McAleese et
   al., 2024, arXiv:2407.00215).
5. Mediate independently. A fresh read-only mediator verifies each objection
   against the named revision and current files. It returns `ACCEPT`, `REJECT`,
   `REFRAME`, or `DEFER`. It rejects nits, duplicates, fixed claims, unsupported
   claims, and scope expansion. It reframes a valid broad risk as the smallest
   in-scope defect. `DEFER` carries an evidence-resistant owner question, not a
   revision instruction. This is an engineering control for the documented
   sycophancy, self-preference, position, and verbosity biases below.
6. Revise against `ACCEPT` and `REFRAME` only. The generator rewrites to remove
   adjudicated defects. Neither a critic nor the mediator edits, blesses, or
   claims owner approval. Source: Constitutional AI critique→revise
   (arXiv:2212.08073). Also the external-signal requirement of "LLMs Cannot
   Self-Correct Reasoning Yet" (Huang et al., 2023, arXiv:2310.01798).
7. Rotate lenses each round. Assign one lens per critic per round, e.g.
   correctness, security, ops/rollback, cost, data-migration. Source:
   Constitutional AI principle sampling (arXiv:2212.08073).
8. Repeat.

## Stop criterion (hybrid)

- STOP when independent mediation leaves no `ACCEPT`, `REFRAME`, or `DEFER`
  verdict. This generalizes Self-Refine's stop indicator (arXiv:2303.17651) to
  an independently adjudicated critic round.
- ROUND CAP scaled to blast radius. K=2 for one file or one phase. K=4 for a
  single-capability change. K=6 for a cross-capability change, or one that
  mutates the live system.

  Earlier versions of this skill used a flat K=4 and cited Self-Refine's
  max-4-iterations (arXiv:2303.17651) as the source. That citation was an
  over-extension and is withdrawn. Self-Refine measures a *single-model*
  generate→feedback→refine loop on bounded tasks such as sentiment reversal and
  code optimization. This skill runs *N independent adversaries* against a
  multi-file design artifact. The two regimes have no reason to share an
  iteration budget, and the paper does not claim one. Treat the scaled cap as an
  engineering choice, not a paper result.

  Observed counter-evidence, sysinit, 2026-07: a three-change review produced
  surviving-objection counts of 6, 16, 6, and 8 across four rounds. The count
  never declined monotonically, and round 3 consisted entirely of defects
  introduced by round 2's fixes. A flat K=4 stopped that loop mid-flight with no
  clean round, which is the failure this scaling exists to make visible.
- STOP EARLY on non-convergence. Stop before K when the surviving-objection
  count fails to decline across two consecutive rounds. Stop too when the
  previous round's fixes caused every surviving objection. Both indicate
  churn rather than progress. These are hand-back conditions: report the trend
  and let the owner decide. No paper backs these thresholds; they are engineering
  choices motivated by the observation above.
- Objection survival. Inside a round, an objection survives only when the
  mediator returns `ACCEPT` or `REFRAME`. A `DEFER` verdict remains open for the
  owner but does not authorize revision. Independent mediation is an engineering
  choice, not a result claimed by the cited papers.
- ELICIT AT EVERY ROUND BOUNDARY. Ask whether to continue before spawning the
  next round. Carry the decision inputs into the question: the round reached,
  the cap, the per-round objection trend, and what remains open. The
  owner should not have to interrupt to end a loop. Recommend halting when the
  count is flat or rising, or when a round produced only fix-induced
  regressions. Do not spend the round and report it afterward.
- OWNER HALT. The owner may stop the loop at any transition and go straight
  to the gate. Honor it at the next transition, apply nothing further, and
  report the open objections rather than dropping them. A halt is a decision
  made with the objection list visible. A waiver is made before the loop ran,
  and a cap hit is chosen by nobody.
- A cap hit is not a pass. An artifact that never reached a clean round
  carries known-unreviewed state. The report MUST name the terminal state
  explicitly rather than presenting a cap hit as completion.

## Failure modes and required mitigations

Self-critique and LLM-judge setups fail in documented ways. The mitigations are
mandatory for this skill.

1. Unaided self-correction degrades reasoning. Models flip correct answers to
   wrong ones without an external signal. Huang et al., 2023 (arXiv:2310.01798).
   → Use a separate adversary, not a same-instance self-review.
2. Sycophancy. RLHF models agree with the stated view of the prompt. Sharma
   et al., 2023 (arXiv:2310.13548). → Strip authorship/ownership cues; never
   signal the artifact is "ours" or already approved; instruct the critic to
   disagree.
3. Self-preference / self-enhancement bias. Judges favor their own
   generations. Panickssery et al., 2024 (arXiv:2404.13076); Zheng et al., 2023
   (arXiv:2306.05685). → The critic MUST be a different model or a fresh instance
   with no generation context.
4. Position and verbosity bias. Judges reward order and length over quality.
   Zheng et al., 2023 (arXiv:2306.05685). → Judge objections on the concrete
   failing scenario, not on which draft reads better.
5. Polite, non-refutational critique. Cooperative prompts produce comments,
   not breakage. Multiagent Debate (arXiv:2305.14325); CriticGPT
   (arXiv:2407.00215). → Force a concrete defect; run N independent critics;
   require survival across the panel.

Consolidated: (a) separate, independent critic. (b) Hide authorship. (c) Prompt
for refutation plus a concrete failing scenario. (d) Rotate lenses. (e) Have a
separate read-only mediator adjudicate current evidence before revision. (f)
Bound with a blast-radius-scaled K, early stops on churn, and an owner halt.

## Mapping to spec-driven OpenSpec artifacts

- Rubric source. The proposal's `Behavior` criteria, the design `Decisions`
  and `Rollout & Gating`, and the proposal `Non-goals` ARE the rubric. The critic
  cites which criterion, decision, or gate the plan violates. The schema carries
  no separate requirement spec: acceptance criteria live in the proposal.
- What the critic breaks. For a plan, "fails" means any one of five things. A
  `Behavior` criterion the plan cannot satisfy. A criterion no command or
  observation can decide. A decision whose rejected alternative was actually
  better. A rollout step that mutates shared state with no verification gate. A
  non-goal the plan silently crosses.
- Where it runs. The `tasks.md` review-loop gate per phase references this
  skill, and the findings land in the change's `review.md`. The skill decides
  between in-process and spawned execution.

## Citation index

| Short name | arXiv | Role in the loop |
|---|---|---|
| Self-Refine | 2303.17651 | base propose→critique→revise loop; stop-indicator idea. Its max-4-iterations does NOT justify this skill's round cap; see Stop criterion. |
| Constitutional AI | 2212.08073 | rubric anchoring; critique→revise; lens rotation |
| Multiagent Debate | 2305.14325 | N independent critics |
| Chain-of-Verification | 2309.11495 | isolated verification questions |
| CriticGPT | 2407.00215 | critic must name a concrete defect |
| Cannot-Self-Correct | 2310.01798 | external signal required; no unaided self-review |
| Sycophancy | 2310.13548 | hide authorship, prompt to disagree |
| Self-Preference | 2404.13076 | different model / fresh instance |
| LLM-as-a-Judge | 2306.05685 | position/verbosity bias controls |

URL form: `https://arxiv.org/abs/<id>`.
