''
  Implement tasks from an OpenSpec change.

  **Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous, prompt for available changes.

  **Steps**

  1. **Select the change**

     If a name is provided, use it. Otherwise:
     - Infer from conversation context if the user mentioned a change
     - Auto-select if only one active change exists
     - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

     Always announce: "Using change: <name>" and how to override (e.g., `/opsx:apply <other>`).

  2. **Check status to understand the schema**
     ```bash
     openspec status --change "<name>" --json
     ```
     Parse the JSON to understand:
     - `schemaName`: The workflow being used (e.g., "spec-driven", "rosh-spec-driven")
     - Which artifact contains the tasks (typically "tasks" for spec-driven schemas, check status for others)

  3. **Get apply instructions**

     ```bash
     openspec instructions apply --change "<name>" --json
     ```

     This returns:
     - Context file paths (varies by schema)
     - Progress (total, complete, remaining)
     - Task list with status
     - Dynamic instruction based on current state

     **Handle states:**
     - If `state: "blocked"` (missing artifacts): show message, suggest using `/opsx:propose` or `/opsx:continue`
     - If `state: "all_done"`: congratulate, suggest archive
     - Otherwise: proceed to implementation

  4. **Read context files**

     Read the files listed in `contextFiles` from the apply instructions output.
     The files depend on the schema being used:
     - **spec-driven / rosh-spec-driven**: proposal, specs, design, tasks
     - Other schemas: follow the contextFiles from CLI output

  5. **Show current progress**

     Display:
     - Schema being used
     - Progress: "N/M tasks complete"
     - Remaining tasks overview
     - Dynamic instruction from CLI

  6. **Implement tasks (loop until done or blocked)**

     For each pending task:
     - Show which task is being worked on
     - Make the code changes required
     - Keep changes minimal and focused
     - Mark task complete in the tasks file: `- [ ]` → `- [x]`
     - Continue to next task

     **Pause if:**
     - Task is unclear → ask for clarification
     - Implementation reveals a design issue → suggest updating artifacts
     - Error or blocker encountered → report and wait for guidance
     - User interrupts

  7. **On completion or pause, show status**

     Display:
     - Tasks completed this session
     - Overall progress: "N/M tasks complete"
     - If all done: suggest archive
     - If paused: explain why and wait for guidance

  **Guardrails**
  - Keep going through tasks until done or blocked
  - Always read context files before starting (from the apply instructions output)
  - If task is ambiguous, pause and ask before implementing
  - If implementation reveals issues, pause and suggest artifact updates
  - Keep code changes minimal and scoped to each task
  - Update task checkbox immediately after completing each task
  - Pause on errors, blockers, or unclear requirements — do not guess
  - Use `contextFiles` from CLI output; do not assume specific file names

  **Fluid Workflow Integration**

  This skill supports the "actions on a change" model:

  - **Can be invoked anytime**: before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
  - **Allows artifact updates**: if implementation reveals design issues, suggest updating artifacts — not phase-locked, work fluidly
''
