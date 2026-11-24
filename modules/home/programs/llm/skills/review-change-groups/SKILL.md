---
name: review-change-groups
description: Inspect grouped Git changes, changed calls, and saved review notes with Changes. Use for structured diff analysis or to open the interactive review workspace.
---

Use `changes workspace` from the selected repository for structured
`changes.workspace/v1` output. Read `comparison`, `freshness`, and
`failures` before drawing conclusions. Files and note anchors are scoped to
the returned repository and comparison.

Run `changes` from a terminal or use `changes interactive` to open the native
review workspace. Use `?` for its keymap. For staged comparisons use
`changes interactive --staged`. Select a checkout through
`changes interactive --recursive --root DIRECTORY` for multi-repo work.

Use `:ChangesNote` from the saved file or `changes note --help` when a note
needs to survive the editor. Keep notes with their original owner and
comparison. Use `review-worktree-diff` for immediate Reviewr feedback to an
agent and Atlas for GitHub review threads.
