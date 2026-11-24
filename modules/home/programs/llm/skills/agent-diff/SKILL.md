---
name: agent-diff
description: Open or reuse Reviewr in a Neovim split beside the invoking agent. Use when asked to review this agent’s edits, see a local worktree diff, or draft line feedback to the agent.
---

To open a review beside this agent in WezTerm, run `agent-diff` from its
checkout. Pass `--cwd` when the command runs from a different directory.
Use the current session directory, including its worktree, rather than a parent checkout.
The command validates the invoking pane and reuses its live Neovim diff pane.
When the user names a pane or asks to preserve focus, load `terminal-wezterm` for targeting.
Use `--pane-id <id>` for an explicit caller and `--background` to preserve
focus. Both flags can be used together:

```sh
agent-diff --cwd "$checkout" --pane-id "$caller_pane" --background
```

Reviewr uses a temporary index for untracked worktree files. The review
launcher refreshes that index when called again. Reviewr can draft feedback
to the invoking agent when WezTerm reports its TTY. When that metadata is
absent, export uses the repository's `.reviewr/inbox` or clipboard. Use the
Neovim local leader for Reviewr actions, such as `,c` to comment, `,s` to
paste a draft into the agent's input, and `,y` to copy it. Use
`:ReviewrTurn` before the next edit for a deliberate baseline in WezTerm.

Use `agent-diff --allow-directory --file PATH --line LINE` to select a
changed file in the same Reviewr split. Unchanged files open as source.
Use `--base` for explicit Diffview comparisons. Plain directories open in
Neovim's directory view.
To offer a clickable review without opening a split, run `agent-review-link`
with the checkout directory and show the returned `review://` link. Ordinary
file links open the file.
Use `review-change-groups` for durable Changes notes and grouped analysis.
