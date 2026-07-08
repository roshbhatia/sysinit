---
name: openspec-workflow
description: Use when working in a repository with OpenSpec, when the user mentions a spec/change/proposal/design/tasks, or when planning spec-driven work. Keeps OpenSpec available globally without relying on per-project init scaffolding.
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
3. Read `proposal.md`, `design.md`, `tasks.md`, and relevant spec deltas before editing.

## Explore

Use the Explore planning subagent for discovery and planning work. Explore is read-only by default: it can inspect code, map options, and surface tradeoffs, but it should not implement application code.

When there is no active change, explore freely and offer to create a proposal once the problem is clear. Do not run `openspec init` just to make commands or skills available; this sysinit configuration provides the global OpenSpec workflow. Use `openspec init` only when the user wants to initialize OpenSpec artifacts in a repository that does not already have them.

## Implement

- Keep edits tied to a named OpenSpec change when one exists.
- Update `tasks.md` as work is completed.
- Preserve proposal/design/spec intent; if implementation discovers a mismatch, update the OpenSpec artifact instead of silently drifting.
- Validate the specific change with `openspec validate "<name>"` when the project supports it.

## Useful Commands

```bash
openspec list --json
openspec status --change "<name>" --json
openspec instructions <artifact> --change "<name>" --json
openspec validate "<name>"
openspec schema validate rosh-spec-driven
specutil graph --as mermaid
specutil render --as rfc|design|tickets --change <name>
specutil plan --target linear|notion --change <name>
```
