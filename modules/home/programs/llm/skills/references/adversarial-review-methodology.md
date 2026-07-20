# Adversarial review methodology (reference)

This reference grounds the `adversarial-review` skill in published methods. Every
citation was verified against arXiv. Read the skill's `SKILL.md` for the
operating procedure; read this file for the WHY and the exact loop.

## The loop

A generator proposes an artifact; independent adversaries try to break it; the
generator revises against surviving objections; repeat until no objection
survives or a hard round cap is hit. Each step below names its source.

1. **Propose.** The generator produces the artifact (plan, spec, design, code).
   Source: Self-Refine (Madaan et al., 2023, arXiv:2303.17651).
2. **Bind a rubric.** Collect the artifact's acceptance criteria, invariants, and
   non-goals into a written rubric. A critic MUST cite a specific rubric item it
   believes is violated — not give a global score. Source: Constitutional AI
   (Bai et al., 2022, arXiv:2212.08073), principle anchoring.
3. **Spawn N independent adversaries (default N=3).** Each critic is a fresh
   instance or a different model, with the artifact's authorship hidden. Each is
   prompted to REFUTE: "Produce a concrete scenario in which this artifact fails.
   Name the rubric item it violates. If you cannot, reply `NO SURVIVING
   OBJECTION`." Source: Multiagent Debate (Du et al., 2023, arXiv:2305.14325) for
   independence; anti-bias sourcing in the failure-modes section.
4. **Require a concrete failing scenario.** An objection is valid only with
   reproducible conditions or a verification question answered in isolation —
   never prose vibes. Source: Chain-of-Verification (Dhuliawala et al., 2023,
   arXiv:2309.11495); LLM Critics Help Catch LLM Bugs / "CriticGPT" (McAleese et
   al., 2024, arXiv:2407.00215).
5. **Revise against surviving objections only.** The generator rewrites to remove
   upheld defects. The same instance MUST NOT both bless and rewrite an artifact
   unaided. Source: Constitutional AI critique→revise (arXiv:2212.08073); the
   external-signal requirement of "LLMs Cannot Self-Correct Reasoning Yet" (Huang
   et al., 2023, arXiv:2310.01798).
6. **Rotate lenses each round.** Assign one lens per critic per round, e.g.
   correctness, security, ops/rollback, cost, data-migration. Source:
   Constitutional AI principle sampling (arXiv:2212.08073).
7. **Repeat.**

## Stop criterion (hybrid)

- **STOP** when a full round yields `NO SURVIVING OBJECTION` from all N critics.
  Generalizes Self-Refine's stop indicator (arXiv:2303.17651) to N critics.
- **HARD CAP** at K=4 rounds. From Self-Refine's max-4-iterations
  (arXiv:2303.17651).
- **Objection survival tie-break.** Inside a round, an objection "survives" if a
  majority of critics uphold it on re-examination. Majority voting is a common
  extension of Multiagent Debate, NOT Du et al.'s stated organic-convergence
  mechanism — treat it as an engineering choice, not a paper result.

## Failure modes and required mitigations

Self-critique and LLM-judge setups fail in documented ways. The mitigations are
mandatory for this skill.

1. **Unaided self-correction degrades reasoning.** Models flip correct answers to
   wrong ones without an external signal. Huang et al., 2023 (arXiv:2310.01798).
   → Use a separate adversary, not a same-instance self-review.
2. **Sycophancy.** RLHF models agree with the stated view of the prompt. Sharma
   et al., 2023 (arXiv:2310.13548). → Strip authorship/ownership cues; never
   signal the artifact is "ours" or already approved; instruct the critic to
   disagree.
3. **Self-preference / self-enhancement bias.** Judges favor their own
   generations. Panickssery et al., 2024 (arXiv:2404.13076); Zheng et al., 2023
   (arXiv:2306.05685). → The critic MUST be a different model or a fresh instance
   with no generation context.
4. **Position and verbosity bias.** Judges reward order and length over quality.
   Zheng et al., 2023 (arXiv:2306.05685). → Judge objections on the concrete
   failing scenario, not on which draft reads better.
5. **Polite, non-refutational critique.** Cooperative prompts produce comments,
   not breakage. Multiagent Debate (arXiv:2305.14325); CriticGPT
   (arXiv:2407.00215). → Force a concrete defect; run N independent critics;
   require survival across the panel.

Consolidated: (a) separate/independent critic; (b) hide authorship; (c) prompt
for refutation + a concrete failing scenario; (d) rotate lenses; (e) N critics,
require survival; (f) bound with fixed K and an explicit stop rule.

## Mapping to rosh-spec-driven OpenSpec artifacts

- **Rubric source.** A change's spec scenarios (including the required negative
  scenarios), the design `Decisions` and `Rollout & Gating`, and the proposal
  `Non-goals` ARE the rubric. The critic cites which scenario/decision/gate the
  plan violates.
- **What the critic breaks.** For a plan, "fails" means: a scenario the plan
  cannot satisfy, a decision whose rejected alternative was actually better, a
  rollout step that mutates shared state with no verification gate, or a non-goal
  the plan silently crosses.
- **Where it runs.** The `tasks.md` review-loop gate per slice and the design
  `Adversarial Review` section reference this skill; the skill decides teammate
  vs subagent execution.

## Citation index

| Short name | arXiv | Role in the loop |
|---|---|---|
| Self-Refine | 2303.17651 | base propose→critique→revise loop; K=4 stop |
| Constitutional AI | 2212.08073 | rubric anchoring; critique→revise; lens rotation |
| Multiagent Debate | 2305.14325 | N independent critics |
| Chain-of-Verification | 2309.11495 | isolated verification questions |
| CriticGPT | 2407.00215 | critic must name a concrete defect |
| Cannot-Self-Correct | 2310.01798 | external signal required; no unaided self-review |
| Sycophancy | 2310.13548 | hide authorship, prompt to disagree |
| Self-Preference | 2404.13076 | different model / fresh instance |
| LLM-as-a-Judge | 2306.05685 | position/verbosity bias controls |

URL form: `https://arxiv.org/abs/<id>`.
