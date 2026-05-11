''
  ---
  name: "OPSX: Propose"
  description: Propose a new change - create it and generate all artifacts in one step
  category: Workflow
  tags: [workflow, artifacts]
  ---

  Propose a new change - create the change and generate all artifacts in one step.

  Delegates to the `openspec-propose` skill. See `~/.claude/skills/openspec-propose/SKILL.md` for the full workflow.

  **Input**: The argument after `/opsx:propose` is the change name (kebab-case), OR a description of what the user wants to build.

  **High-level flow**

  1. If no input, ask the user what they want to build (AskUserQuestion).
  2. Derive a kebab-case name.
  3. Run `openspec new change "<name>"`.
  4. Loop through `openspec status --change "<name>" --json` artifacts in dependency order.
  5. For each ready artifact, fetch `openspec instructions <artifact-id> --change "<name>" --json` and produce the artifact file.
  6. Continue until all `applyRequires` artifacts are `done`.
  7. Report final status; suggest `/opsx:apply`.

  See the `openspec-propose` skill for guardrails, artifact creation guidelines, and the AskUserQuestion / TaskCreate patterns to use when artifacts need user input.
''
