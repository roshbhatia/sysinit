---
name: spec-driven-implementation
description: Specify and verify expected behavior when explicitly asked for a spec-first workflow. Start in the conversation and keep local working notes only when they help.
metadata: {"sysinit-claude-disable-model-invocation":"true"}
---

# Spec-driven implementation

## Intent capture

Start from the request, the current implementation, and one concrete example.
Capture the outcome, constraints, and what would demonstrate success. Keep
this in the conversation by default. Inspect or run a bounded probe to resolve
factual uncertainty. Ask about choices that materially change acceptance and
require the user's judgment.

## Elaboration

Use the smallest representation that answers the next question. A behavior
example can go straight to implementation. Read source and tests for behavior
to preserve. Trace the relevant triggers, decisions, and state reads when
control flow or ownership is unclear. Load `docs-write-technical` for a
material design decision. Consider a bounded model when possible event orders
make a specific invariant hard to check.

Keep a single [local working note](references/intent-and-feedback.md#working-note)
if an open decision, multiple dependent checks, or an interruption makes it
useful. Reuse the existing task and note when resuming.

## Actualisation

Implement the smallest complete change and exercise its intended interface.
Use `code-validate-change` to compare observations with the current acceptance
conditions and record any gaps. A probe should answer a named question and
have a stopping condition. Move to the implementation once a sketch or model
has answered the question it was introduced for.

## Pivot, resume, or continue directly

- When intent or implementation changes, identify which decisions, checks,
  and observations depended on the changed part. Revise or rerun those and
  retain evidence that still applies. Check late results against what they
  exercised before using them.
- If resuming after an interruption, inspect the current checkout and diff,
  then reconcile any note with the latest confirmed intent and relevant code.
  Continue from the next open decision or verification gap.
- If the user asks to proceed directly, or the working material has served its
  purpose, continue in the ordinary implementation or debugging workflow.
  Carry forward confirmed constraints, applicable evidence, and open checks.
  Leave the worktree and task in place. Code and tests carry durable behavior,
  and durable rationale belongs in the usual project record when needed.

<!-- include: local-planning.md -->

See [intent and feedback](references/intent-and-feedback.md) for worked
examples and modeling guidance, and the [tool comparison](references/tool-comparison.md)
when considering a project-level spec tool.
