## Context

<!-- Background and current state. Name the existing patterns or files this
     change extends or parallels, and cite their paths. If you are introducing a
     new pattern, say why the closest existing one was insufficient. -->

## Goals / Non-Goals

Goals:
<!-- What this design aims to achieve -->

Non-Goals:
<!-- What is explicitly out of scope -->

## Decisions

<!-- One entry per decision. Each MUST record a rejected alternative on its own
     `- Alternative rejected:` line, so the reason is a stated fact. -->

- Decision: <!-- the choice made -->
  - Alternative rejected: <!-- what else was considered, and why it lost -->

## Rollout & Gating

<!-- spec-driven rule: REQUIRED section. Which phase ships first, what gate
     must pass before the next one, and where the kill switch is. The default
     gate sequence for this repo is: edit, `nix flake check`, `nh darwin build`,
     owner spot-check, `nh darwin switch`. Call out any deviation. -->

## Risks / Trade-offs

<!-- Known risks. Format each as: [Risk] -> Mitigation. Any risk that maps to a
     human-verification checkpoint in tasks.md belongs here. -->

## Migration Plan

<!-- Steps to deploy and to roll back. Every step that mutates shared state or
     is hard to reverse MUST be preceded by a verification step and followed by
     a confirmation step. -->

## Adversarial Review

<!-- spec-driven rule: REQUIRED section. Name the rubric this plan is
     reviewed against: the proposal Behavior criteria, the Decisions above, the
     Rollout & Gating gates, and the proposal Non-goals.
     The deterministic `specutil check` lint is mandatory. Model critique is
     optional evidence and never represents owner or peer approval. Record
     `not run` when no concrete risk justifies it. Cite the
     `adversarial-review` skill rather than re-deriving its methodology here. -->

## Open Questions

<!-- Outstanding decisions or unknowns. Write "None." if there are none. -->
