---
name: agent-diff
description: Open or reuse Reviewr in a Neovim split beside the invoking agent. Use when asked to review this agent’s edits, see a local worktree diff, or draft line feedback to the agent.
---

Run `agent-diff --review --allow-directory --cwd <current repository or worktree directory>`.
Use the current session directory, including its worktree, rather than a parent checkout.
The command validates the invoking pane and reuses its live Neovim diff pane.
When the user names a pane or asks to preserve focus, load `terminal-wezterm` for targeting.
Use `--pane-id <id>` for an explicit caller and `--background` to preserve
focus. Both flags can be used together:

```sh
agent-diff --review --allow-directory --cwd "$checkout" --pane-id "$caller_pane" --background
```

Reviewr uses a temporary index for untracked worktree files. The review
launcher refreshes that index when called again. Review feedback is drafted
to the invoking agent and never submitted by the review command. Use
`:ReviewrTurn` before the next edit for a deliberate baseline in WezTerm.

Use `agent-diff` with `--file` or `--base` for source links and explicit
Diffview comparisons. Plain directories open in Neovim's directory view.
Use `review-change-groups` for durable Changes notes and grouped analysis.
