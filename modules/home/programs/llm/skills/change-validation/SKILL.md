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
| Agent skill or routing | Rendered discovery, positive and adjacent negative prompts, observed skill loads, and the required tool behavior |
| Documentation only | Commands, paths, and factual claims affected by the edit |

Inspect the complete diff. Run required gates, then the affected flow. A test of
a copied algorithm is not evidence about the production implementation. Avoid
new tests that merely restate a reversible low-impact edit. Broaden testing when
failures, new changes, or unresolved risks justify it, rather than by repetition.

For agent workflows, separate selection, command plans, tool execution, and
end-to-end results. Inspect tool events to confirm a skill or reference was
read. Exercise a synthetic input with the permissions of the target harness
before treating one harness's result as evidence for another.

For stateful changes, name an invariant and test it through the real
implementation. Use a bounded model checker when event order produces
cases that are hard to enumerate. Declare the modeled assumptions and turn
counterexamples into implementation regression tests.

Preserve a failed check's log, investigate its cause, fix within scope, and rerun
the same check. Record a baseline failure separately from a regression. Do not
bypass hooks or suppress types to produce a passing result.

Report the commands and outcomes, what was not run, and material limits. Build,
activation, rollout, and behavior are separate observations. For a deployment,
verify the target's actual active version and the acceptance condition there.
