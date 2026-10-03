---
name: diff
description: Open or reuse a Neovim working-tree diff in a WezTerm split for the current repository.
---

Run `agent-diff --cwd <current repository or worktree directory>`.
Use the current session directory, including its worktree, rather than a parent checkout.
The command validates the invoking pane and reuses its live Neovim diff pane.
Report its result. Opening the viewer does not request a code review or annotations.
If the harness reserves `/diff`, invoke this skill by name or run `agent-diff` directly.
