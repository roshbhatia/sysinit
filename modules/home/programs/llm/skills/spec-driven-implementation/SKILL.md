---
name: spec-driven-implementation
description: Plan and verify an explicitly requested spec-driven change with local working notes. Use when asked to specify expected behavior or use a spec-first workflow before implementation.
metadata: {"sysinit-claude-disable-model-invocation":"true"}
---

# Spec-driven implementation

## Intent capture

Read the request and the current implementation. Capture the outcome,
constraints, and observable acceptance conditions. Resolve ambiguities that
materially change acceptance. For a small, settled change, keep this in the
conversation.

## Elaboration

For existing code, extract current behavior from source and tests. Separate
observations from assumptions. Describe the behavior to change, the cases to
preserve, and how to check both. For new code, start with a concrete example
that can run through its intended interface. Load `docs-write-technical`
when there is a material design decision. Sketch the affected control flow and
data dependencies when several steps or owners interact.

For substantial work, keep one note in `$XDG_STATE_HOME/sysinit/planning/`,
using `$HOME/.local/state` when `XDG_STATE_HOME` is unset. Include the checkout,
starting revision, and source ticket when available. Use the existing
Taskwarrior UUID as the filename when there is one and record the local path
in that task alone. Reuse the note when resuming.

## Actualisation

Implement the smallest complete change and run the affected behavior. Compare
observations with current acceptance criteria. Revisit intent when feedback
exposes a material ambiguity and update the note when an agreed decision changes.
Load `code-validate-change` and map each condition to an observed result or a
verification gap. When evidence arrives after the intent or candidate changes,
check that it still applies.

Read [intent and feedback](references/intent-and-feedback.md) for the research
behind the loop and guidance on when to model a stateful protocol.

<!-- include: local-planning.md -->

See the [tool comparison](references/tool-comparison.md) before introducing
a project-level spec tool.
