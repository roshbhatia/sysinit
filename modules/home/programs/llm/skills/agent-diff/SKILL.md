---
name: agent-diff
description: Open or reuse a Neovim working-tree diff in a WezTerm split for the current repository.
---

Run `agent-diff --cwd <current repository or worktree directory>`.
Use the current session directory, including its worktree, rather than a parent checkout.
The command validates the invoking pane and reuses its live Neovim diff pane.
Add `--allow-directory` in a shell to open a plain directory in the
same kind of split when it has no Git worktree.
Report its result. Opening the viewer does not request a code review or annotations.
