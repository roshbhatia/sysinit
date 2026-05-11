''
  ---
  name: "OPSX: Apply"
  description: Implement tasks from an OpenSpec change
  category: Workflow
  tags: [workflow, implementation]
  ---

  Implement tasks from an OpenSpec change.

  Delegates to the `openspec-apply` skill. See `~/.claude/skills/openspec-apply/SKILL.md` for the full workflow.

  **Input**: Optionally specify a change name (e.g., `/opsx:apply add-auth`). If omitted, infer from conversation context or prompt with `openspec list --json`.

  **High-level flow**

  1. Select the change (announce "Using change: <name>").
  2. Run `openspec status --change "<name>" --json` to identify the schema and tasks artifact.
  3. Run `openspec instructions apply --change "<name>" --json` for context files, task list, and dynamic instruction.
  4. Read context files (proposal, specs, design, tasks for spec-driven schemas).
  5. Loop through pending tasks: implement, mark `[x]` in tasks file, continue until done or blocked.
  6. On completion, suggest `/opsx:archive`. On blocker, pause and report.

  See the `openspec-apply` skill for guardrails and the fluid-workflow integration notes.
''
