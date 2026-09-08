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

## Stop criterion (the ledger)

Earlier versions of this skill ran rounds until a mediated round left no
objection, under a blast-radius-scaled cap K with early stops on stall and
churn, all stated as prose the running model had to honor. Observed in this
repository, 2026-07: counts of 6, 16, 6, 8 across four rounds, round 3 made of
defects round 2 introduced. The answer was not a better sentence.

What the orgs that publish do instead (Spotify Honk, Cloudflare's AI review,
Anthropic's Claude Code guidance, Dropbox Nova, DoorDash): the thing that loops
is a deterministic check; a model review is one pass per revision; a second
model tries to disprove each finding before it posts; a finding with no anchor
in the change is dropped, not argued about; a new revision is what earns
another pass. The `review` ledger encodes exactly that:

- `review open` measures the diff and picks the tier, so how much review runs
  is a policy decided once, not a judgment made per change.
- One pass: the tier's critics, then the mediator's disproof attempt, then
  `review judge`, which drops any ACCEPT or REFRAME without a scenario, a
  disproof attempt, and a `file:line` inside the change.
- `CLEAN` when nothing actionable survives. `HANDBACK` on a DEFER or a blocking
  finding. `REVISE` otherwise, and `review reopen` allows one more pass only when
  the tree changed. `CAPPED` when the last pass still has findings.
- The `review-gate` hook denies a critic spawned outside an open pass, past the
  count, or as a writing agent type, so the bound is not a request.

None of this is a result the cited papers claim. It is an engineering control
for the failure modes below, with the round loop removed rather than tuned.

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
Bound with a ledger: a tier from the diff, one judged pass, one re-pass on a
changed tree, and an owner halt.

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
