''
  ---
  name: prd-workflow
  description: Use when starting a new feature, receiving a feature request, or when the user describes something that needs design before implementation
  ---

  # PRD Workflow

  ## Overview

  All new features begin with a Product Requirement Document (PRD). Use the OpenSpec tool to create PRDs from a template, review with the user, and explicitly approve before implementation. This prevents scope creep and ensures shared understanding.

  ## When to Use

  - User describes a new feature
  - User asks to "build", "add", "create", or "implement" something non-trivial
  - Work spans multiple files or modules
  - Requirements are ambiguous and need clarification

  ## When NOT to Use

  - Bug fixes with clear reproduction steps
  - Single-line changes or formatting fixes
  - Configuration tweaks
  - Refactoring with well-defined scope

  ## PRD Creation with OpenSpec

  1. Use the `plan` tool: `plan <feature-name>` (e.g., `plan user-authentication`)
  2. The tool will:
     - Initialize beads if not already initialized
     - Create OpenSpec feature with standard template
     - Open the spec for your review
  3. PRD is saved to `openspec/features/<feature-name>/spec.md`
  4. Review and edit the spec - do not proceed until explicitly approved

  ## Beads Integration

  After PRD approval:

  1. Create beads task linked to the spec:
     ```
     bd create "Implement <feature-name>" --external-ref openspec:<feature-name> --type feature
     ```
  2. The SysinitSpec plugin provides bidirectional sync:
     - OpenCode todos automatically sync to beads tasks
     - Beads task updates sync back to OpenCode todos
     - Conflict resolution: last-write-wins with timestamps
  3. If sync is not automatic, manually ensure todos and beads tasks stay in sync

  ## Todo Syncing

  The plugin attempts automatic bidirectional sync, but verify:

  - When you create a todo in OpenCode, check `bd list` shows the task
  - When you close a beads task, verify the todo is marked complete
  - If they get out of sync, manually update with matching `--external-ref` links

  ## The `.sysinit/` Directory

  - Located at project root
  - Globally gitignored -- contents are never committed
  - Used for lessons learned and scratch work
  - Check for `.sysinit/lessons.md` at session start for prior context

  ## Approval Gate

  - Present the PRD to the user for review
  - Do NOT proceed to task breakdown until PRD is explicitly approved
  - The user may request changes -- iterate until approved
  - Once approved, transition to beads-workflow for task tracking

  ## Transition to Implementation

  After PRD approval:

  1. Break PRD into atomic tasks using `bd create`
  2. Add dependencies between tasks with `bd dep add`
  3. Begin sequential execution per beads-workflow skill

  ## Lessons Learned

  If the user pushes back, notes issues, or provides architectural correction:

  1. Create or update `.sysinit/lessons.md`
  2. Record the lesson, failure mode, or style preference
  3. Refer to these lessons in future tasks to prevent regression

  ## Critical Rules

  - NEVER check in the `.sysinit/` folder or any of its contents into git
  - NEVER check in `openspec/` folder into git (it is gitignored)
  - NEVER check in `.opencode/` or `.claude/` folders into git
  - NEVER check in any gitignored files unless specifically told otherwise
  - NEVER proceed to implementation without explicit PRD approval
  - Use the user's words verbatim in the PRD, do not embellish or assume
''
