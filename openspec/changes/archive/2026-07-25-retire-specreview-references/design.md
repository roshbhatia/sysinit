## Context

`openspec archive` rewrites requirement blocks from a change's deltas. It does not manage a spec's `## Purpose` header or a schema changelog, so those kept the retired tool name after the swap landed.

## Goals / Non-Goals

**Goals:**
- Every current spec names the tool a reader can actually run

**Non-Goals:**
- Any behavior change

## Decisions

- Decision: correct the two stale requirements through a change rather than editing the deployed specs directly
  - Alternative rejected: edit `openspec/specs/` in place. Rejected because a requirement edit that skips the change flow leaves no record of why the wording moved.
- Decision: edit the Purpose headers and the schema changelog directly
  - Alternative rejected: route them through spec deltas too. Rejected because neither is a requirement, so `openspec archive` would not apply them and the delta would silently do nothing.

## Rollout & Gating

One slice, documentation only. The gate is `specutil check` on this change plus `nix flake check`. No switch is required, so there is no kill switch to name.

## Risks / Trade-offs

- A MODIFIED block that renames a scenario drops the original. Mitigation: copy each requirement block verbatim from the current spec and change only the tool name.

## Migration Plan

No migration. The change is prose only and takes effect when archived.

## Adversarial Review

Reviewed against the spec scenarios below, the decisions above, and the non-goals. The deterministic gate is `specutil check` on this change. The critic loop is owner-gated per the `adversarial-review` skill.

## Open Questions

None.
