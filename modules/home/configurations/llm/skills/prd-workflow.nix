''
  ---
  name: prd-workflow
  description: Use when starting a new feature, receiving a feature request, or when the user describes something that needs design before implementation
  ---

  # PRD Workflow

  ## Overview

  All new features begin with a Product Requirement Document (PRD). The PRD is created from a template, reviewed by the user, and explicitly approved before any implementation begins. This prevents scope creep and ensures shared understanding.

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

  ## PRD Creation

  1. Use the template from https://github.com/opulo-inc/prd-template/blob/main/prd.md
  2. Do not make assumptions on feature scope -- use what the user has said verbatim
  3. Save the PRD to `.sysinit/<prdname>.md`

  ## The `.sysinit/` Directory

  - Located at project root
  - Globally gitignored -- contents are never committed
  - Used for PRDs, lessons learned, and scratch work
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
  - NEVER check in any gitignored files unless specifically told otherwise
  - NEVER proceed to implementation without explicit PRD approval
  - Use the user's words verbatim in the PRD, do not embellish or assume
''
