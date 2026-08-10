---
description: Uses the global OpenSpec workflow for spec-driven repositories without relying on per-project openspec init scaffolding. Use when a task mentions OpenSpec, proposals, designs, specs, tasks, or named changes, and prefer the Explore planning {{agent}} for discovery before implementation.
allowed-tools: Bash(openspec:*) Bash(specutil:*) Read Glob
---

Use OpenSpec as a managed workflow, not as a project-local install step.

## Start

1. If the repository contains `openspec/` or the task touches OpenSpec changes, run:
   ```bash
   specutil graph --as mermaid
   openspec list --json
   ```
2. If the user names a change, inspect it before planning:
   ```bash
   openspec status --change "<name>" --json
   ```
3. Read `proposal.md`, `design.md`, and `tasks.md` before editing. The proposal's
   `Behavior` section carries the acceptance criteria; the schema has no separate
   requirement spec.

## Explore

Use the Explore planning {{agent}} for discovery and planning work. Explore is read-only by default: it can inspect code, map options, and surface tradeoffs, but it should not implement application code.

When there is no active change, explore freely and offer to create a proposal once the problem is clear. Do not run `openspec init` just to make commands or skills available; this sysinit configuration provides the global OpenSpec workflow. Use `openspec init` only when the user wants to initialize OpenSpec artifacts in a repository that does not already have them.

## Implement

- Keep edits tied to a named OpenSpec change when one exists.
- Update `tasks.md` as work is completed.
- Preserve proposal/design/spec intent; if implementation discovers a mismatch, update the OpenSpec artifact instead of silently drifting.
- Read the complete diff before handoff and map each edit to a Behavior criterion.
- Address review feedback with targeted edits. Do not regenerate the whole change.
- Keep automation evidence, model critique, peer review, and owner approval distinct.
- Validate the specific change with `openspec validate "<name>"` when the project supports it.

<examples>
<example>
<bad>Implementation needed a third state, so the code has one and the design still lists two.</bad>
<good>Implementation needed a third state, so update `design.md` to list three, then write the code.</good>
</example>
<example>
<bad>Phase 2 is done. All checks passed.</bad>
<good>Phase 2 is done: `specutil check` exits 0, and each of the 4 edits maps to Behavior criterion B2.</good>
</example>
</examples>

## Useful Commands

```bash
openspec list --json
openspec status --change "<name>" --json
openspec instructions <artifact> --change "<name>" --json
openspec validate "<name>"
openspec schema validate spec-driven
```

For DAG visualization, rendering a change as RFC/design/tickets, and
Linear/Notion sync planning, load the `specutil` skill; its commands are not
restated here.

For general external web research during a change (not internal or in-repo
content), prefer the `pplx` CLI when it is authenticated, and fall back to the
built-in WebSearch otherwise. See the `pplx-cli` skill for the routing rule.
