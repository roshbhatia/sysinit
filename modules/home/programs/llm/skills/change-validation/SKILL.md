---
name: change-validation
description: Choose and run proportionate checks against the real implementation, including regression and failure cases. Use before reporting a coding or configuration change complete; not a substitute for repository-required gates.
---

# Validate changed behavior

Read the repository's declared commands and checks. Use its development shell.
Before editing, identify the acceptance condition, affected boundary, and an
observable that distinguishes correct behavior from the original defect.

| Change | Evidence to collect |
| --- | --- |
| Runtime logic | Focused real-component check, relevant failure case, and required repository gates |
| Configuration or packaging | Native parser/evaluation, generated output, and affected runtime behavior |
| API or persisted data | Producer/consumer compatibility and the owning migration procedure |
| UI | Affected user flow, relevant viewport/input state, and existing accessibility checks |
| Documentation only | Commands, paths, and factual claims affected by the edit |

Inspect the complete diff. Run required gates, then the affected flow. A test of
a copied algorithm is not evidence about the production implementation. Avoid
new tests that merely restate a reversible low-impact edit. Broaden testing when
failures, new changes, or unresolved risks justify it, rather than by repetition.

Preserve a failed check's log, investigate its cause, fix within scope, and rerun
the same check. Record a baseline failure separately from a regression. Do not
bypass hooks or suppress types to produce a passing result.

Report the commands and outcomes, what was not run, and material limits. Build,
activation, rollout, and behavior are separate observations. For a deployment,
verify the target's actual active version and the acceptance condition there.
