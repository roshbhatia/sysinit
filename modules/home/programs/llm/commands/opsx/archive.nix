''
  ---
  name: "OPSX: Archive"
  description: Archive a completed OpenSpec change
  category: Workflow
  tags: [workflow, archive]
  ---

  Archive a completed OpenSpec change and merge its delta specs into the project's authoritative specs.

  Delegates to the `openspec-archive` skill. See `~/.claude/skills/openspec-archive/SKILL.md` for the full workflow.

  **Input**: Optionally specify a change name. If omitted, infer from conversation context or prompt with `openspec list --json`.

  **High-level flow**

  1. Select the change.
  2. Verify all `applyRequires` artifacts are `done` and tasks.md checkboxes are `[x]` (prompt if not).
  3. Run `openspec validate "<name>"` and fix any cited issues.
  4. Run `openspec archive "<name>"`.
  5. Confirm via `openspec list --json` that the change is no longer active.
  6. Suggest committing any merged spec changes.

  See the `openspec-archive` skill for guardrails (no archive with unchecked tasks unless confirmed, no archive with incomplete artifacts).
''
