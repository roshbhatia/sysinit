---
name: debugging
description: Reproduce, diagnose, and verify a software defect from logs, errors, failing tests, or incorrect behavior. Use for ordinary debugging; follow the owning incident workflow for production incidents.
---

# Diagnose a defect

1. Read repository guidance and active changes. State the observed behavior,
   expected behavior, affected version, and smallest reproducible input.
2. Preserve the original error and reproduction before resets or dependency changes.
   Trace the input through its owning boundary; distinguish evidence from hypotheses.
3. Run a bounded check that separates the leading hypotheses. When evidence changes,
   change the approach; repeating a failed command is not a diagnosis.
4. Fix the owning cause with the smallest complete change. Do not add retries,
   compatibility branches, or adjacent refactors without a demonstrated requirement.
5. Load `change-validation`. Re-run the original reproduction and the relevant
   failure case against the actual implementation. Add a regression test when
   the defect warrants durable coverage; do not copy implementation logic into it.
6. Report cause, change, evidence, and remaining uncertainty. If reproduction was
   unavailable, say so and identify exactly what the substitute check establishes.

Production symptoms may need an incident or service-specific investigation skill.
Follow the repository's escalation procedure; this skill does not authorize
production mutations, credential changes, service restarts, or external messages.
