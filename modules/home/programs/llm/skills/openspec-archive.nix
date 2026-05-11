''
  Archive a completed OpenSpec change after implementation is finished.

  **Input**: Optionally specify a change name. If omitted, infer from conversation or prompt the user with `openspec list --json` to pick.

  **Steps**

  1. **Select the change**

     If a name is provided, use it. Otherwise:
     - Infer from conversation context if the user mentioned a change
     - Auto-select if only one active change exists
     - If ambiguous, run `openspec list --json` and use the **AskUserQuestion tool** to let the user select

     Announce: "Archiving change: <name>".

  2. **Verify the change is apply-ready and tasks are complete**
     ```bash
     openspec status --change "<name>" --json
     ```
     - All `applyRequires` artifacts MUST have status `done`.
     - All checkboxes in `tasks.md` SHOULD be `[x]`. If some remain unchecked, ask the user whether to continue or pause for cleanup.

  3. **Run `openspec validate`**
     ```bash
     openspec validate "<name>"
     ```
     If validation fails, fix the cited issue and re-validate before continuing.

  4. **Run the archive**
     ```bash
     openspec archive "<name>"
     ```
     This moves the change into the archive area and merges any delta specs into the project's authoritative specs under `openspec/specs/`.

  5. **Show the result**
     ```bash
     openspec list --json
     ```
     Confirm the change no longer appears in the active-changes list, and (if applicable) report which spec files were updated by the archive operation.

  6. **Suggest follow-ups**
     - If new specs were merged, prompt the user to commit them.
     - If the change introduced new capabilities, suggest verifying the spec directory layout.

  **Guardrails**
  - Never archive a change with unchecked tasks unless the user explicitly confirms.
  - Never archive a change whose `applyRequires` artifacts are not all `done`.
  - If `openspec archive` fails, surface the exact CLI error and pause for user direction.
  - Do not delete files manually — use `openspec archive` as the source of truth.
''
