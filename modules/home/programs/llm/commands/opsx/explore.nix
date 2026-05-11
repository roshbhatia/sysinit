''
  ---
  name: "OPSX: Explore"
  description: Enter explore mode - think through ideas, investigate problems, clarify requirements
  category: Workflow
  tags: [workflow, exploration, thinking]
  ---

  Enter explore mode - a thinking partner for exploring ideas, investigating problems, and clarifying requirements before committing to a change.

  Delegates to the `openspec-explore` skill. See `~/.claude/skills/openspec-explore/SKILL.md` for the full stance.

  **Explore mode is for thinking, not implementing.** Read files, search code, investigate. Do not write application code. OpenSpec artifacts (proposals, designs, specs) may be created — that is capturing thinking.

  **Input**: The argument after `/opsx:explore` is whatever the user wants to think about. May be an idea, a problem, a change name, a comparison, or nothing.

  **Stance**

  - Curious, not prescriptive
  - Open threads, not interrogations
  - Visualize with ASCII diagrams where useful
  - Adaptive and patient
  - Grounded in the actual codebase

  See the `openspec-explore` skill for OpenSpec awareness, capture offers, and guardrails.
''
