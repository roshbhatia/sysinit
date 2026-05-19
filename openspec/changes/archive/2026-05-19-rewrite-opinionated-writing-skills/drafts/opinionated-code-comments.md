---
name: opinionated-code-comments
description: Opinionated style for inline source-code comments. Default to no comment. Add a comment only when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. No multi-paragraph docstrings. One short line max. Use when editing source files, when asked 'should I comment this', or whenever the agent considers adding a comment to code.
---

# Opinionated source-code comments

An opinionated style guide for inline comments and docstrings in source files. The default behavior is to write no comment.

Provenance: derived from the standing rule in `~/.claude/CLAUDE.md` (`# Doing tasks`, "Default to writing no comments…"), reinforced by the terse, lowercase-preferred prose voice observed in a personal-OSS corpus of 295 PRs and 504 commits authored before 2024-06-01. This skill does not have its own ground-truth corpus of code comments; it sharpens an existing CLAUDE.md stance into per-edit defaults.

## First, check the project's conventions

Some projects mandate header comments, license blocks, or structured docstrings (rustdoc, pydoc, jsdoc, godoc). Sweep before applying the defaults below:

```bash
ls CONTRIBUTING.md .github/CONTRIBUTING.md 2>/dev/null
grep -E "doc(string)?|comment|header" \
  CONTRIBUTING.md .editorconfig .github/CONTRIBUTING.md 2>/dev/null
```

Common overrides:

- Header license / copyright blocks: required by some repos at the top of every source file. Honor them; do not strip.
- Public-API docstrings: many libraries require documentation on every exported symbol (rustdoc on `pub fn`, godoc on exported identifiers, jsdoc on exported functions). Provide a one-line description when the language and repo expect one, and stop there.
- Inline tag comments (`TODO`, `FIXME`, `NOTE`): some repos forbid these in committed code; others require a linked issue. Check before adding.

When the repo has no documentation conventions, apply the defaults below.

## The default: no comment

Well-named identifiers describe what the code does. A comment that restates the identifier is noise. The default for every edit is no comment.

This applies inside function bodies, above function definitions, above blocks, and inline at the end of expressions.

## When to add a comment

A comment is justified only when the reason for the code is non-obvious from the code itself. Concretely:

- A hidden constraint (e.g. "must be called before the connection pool is initialized").
- A subtle invariant (e.g. "this map is never re-entered; the loop assumes single ownership").
- A workaround for a specific upstream bug, with a link or identifier.
- Behavior that would surprise a reader of the surrounding code (e.g. "intentionally returns the second match, not the first, to preserve compatibility with old config").
- A pointer to a non-obvious cross-file dependency (e.g. "this constant is mirrored in `<other-file>:NN`; bump both").

If a comment cannot be reduced to one of those categories, it is probably noise and should not be written.

## Shape when a comment is added

- One short line. Do not write multi-line block comments and do not write multi-paragraph docstrings. If the explanation does not fit on one line, the code is probably too clever or the explanation belongs in the commit / PR body instead of the source.
- Lowercase is preferred for inline comments and short docstrings; do not force lowercase when an identifier or proper noun begins the comment.
- Use `so`, `as`, `because` for causal connectives. Do not use em-dashes for elaboration.
- Backtick identifiers when referenced (`backtick the function or var name`).
- For language-mandated docstrings (rustdoc, godoc, pydoc, jsdoc) on public symbols, write one short line describing the symbol's purpose. Skip parameter-by-parameter elaboration unless the parameter is genuinely surprising.

## What to remove

When editing existing code that contains comments fitting any of the patterns below, the comment should be removed in the same edit. The comment is not load-bearing and rot is more likely than refresh.

- Restating-the-identifier comments (`// returns the user id` above `function returnsTheUserId()`).
- Task-context comments referencing the current change (`// added for the X flow`, `// used by Y`, `// handles the case from issue #NN`). Those belong in the PR description and rot as the codebase evolves.
- Section-header decoration comments (`// ============== SETUP ==============`).
- Commented-out code. Delete it. The history is in git.
- "Removed because..." stubs. Delete the stub; the removal is in git history.
- Walk-through comments narrating the algorithm step-by-step in plain English. The code is the algorithm.
- Apologetic or hedging comments (`// TODO: maybe refactor this someday`, `// not sure if this is right`). If the doubt is real, raise it in the PR; if not, drop the comment.

## What to avoid

- Multi-line block comments. One short line is the upper bound.
- Multi-paragraph docstrings. One short line on the symbol; details belong elsewhere.
- Comments that explain what well-named code already does.
- Comments referencing the current task, fix, issue, or caller. Those belong in commit/PR prose.
- Emojis in comments.
- Bolded prose in comments (most languages do not render Markdown in source; bolding is decorative).
- Comments containing tool-attribution lines (`// generated by claude`, `// AI-assisted`). Tool attribution belongs in commit/PR metadata, not in source.
- Mass-adding comments to "improve documentation" without a specific WHY for each comment.

## Negative scenarios

- WHEN editing a function with a clear, self-descriptive name and adding new behavior
- THEN add no comment. The function name and the diff are the documentation.

- WHEN editing code that contains a workaround for a known upstream bug
- THEN preserve or add a one-line comment naming the bug or issue identifier.

- WHEN tempted to add a docstring with parameter descriptions, return descriptions, and rationale
- THEN compress to one short line describing the symbol's purpose. Drop the parameter list unless a parameter's role is genuinely surprising.

- WHEN finding existing comments that restate the identifier or narrate the algorithm
- THEN remove them in the same edit. Do not preserve noise out of caution.

- WHEN a reader might be confused by the order of operations
- THEN consider whether a rename, a small refactor, or an assertion would carry the meaning better than a comment. Prefer those when they fit; fall back to a one-line comment when they do not.

- WHEN about to add a `// TODO` without a linked issue or owner
- THEN do not. Either raise the concern in the PR description, or open an issue and link it from the TODO. Naked TODOs rot.
