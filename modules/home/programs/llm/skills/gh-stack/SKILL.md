---
description: Operates stacked pull requests with `gh stack`, one branch and one PR per reviewable concern. Use when opening a PR for a multi-concern change, when a PR grows past one concern, or when the user says 'stack', 'split this PR', or 'rebase the stack'.
allowed-tools: Bash(gh:*) Bash(git:*)
model: haiku
effort: low
---

# Stacked pull requests

`gh stack` is a GitHub CLI extension. One concern per branch, one PR per branch,
each PR based on the one below it, so a reviewer reads a small diff instead of a
large one. It owns the branch chain, the rebases, and each PR's base branch.

The house rule this serves already exists: one concern per commit. A stack is
that rule carried through to review.

## When to stack, and when not to

```
Change carries one reviewable concern?      -> ordinary PR, no stack
Change carries two or more?                 -> stack, one layer per concern
A layer only exists to satisfy the next?     -> merge them; that is one concern
Reviewer asks for a split mid-review?        -> `gh stack modify`, do not reopen
Refactor plus the feature it enables?        -> stack: refactor below, feature above
Mechanical sweep plus a behavior change?     -> stack: never one PR
```

A stack of one is just a PR. Do not create a stack to hold a single concern.

## The loop

```bash
gh stack init                 # start a stack from the current trunk
gh stack add <branch>         # add a layer on top, one concern per layer
gh stack view                 # what the stack looks like now
gh stack rebase               # pull trunk and cascade the rebase upward
gh stack sync                 # fetch, rebase, push, and reconcile PR state
```

Navigation, while a stack is open:

```bash
gh stack up [n]      gh stack down [n]
gh stack top         gh stack bottom      gh stack trunk
gh stack checkout <number | PR number | URL | branch>
```

`gh sv`, `gh su`, and `gh sd` are configured aliases for `stack view`, `stack up`,
and `stack down`.

## Submitting is the owner's call

`allowed-tools` above cannot scope to a subcommand: the grammar takes one command
word. The real gate is `lib/allowlist.nix`, which carries the reading and
navigation forms and deliberately carries none of the forms that reach GitHub.

`gh stack submit` pushes branches and creates or updates PRs on GitHub. That is
outward-facing, so the rule from `writing-pr-description` applies unchanged:
never submit unless the immediately preceding user turn directed it.

Prepare the stack, show `gh stack view`, and let the owner submit. Same for
`gh stack merge`, `gh stack push`, `gh stack unstack`, and `gh stack delete`.

Each layer's body is written with the `writing-pr-description` skill. The bottom
layer carries the issue URL; a layer above it does not repeat it.

## Ordering a stack

Bottom to top, each layer must stand on its own:

1. Mechanical or generated changes, which a reviewer can skim.
2. Refactors that introduce no behavior change.
3. The behavior change the refactors were for.
4. Tests, when they are not in the same layer as the behavior.
5. Documentation.

A layer that does not build or pass its own checks is in the wrong position.

## After a rebase

`gh stack rebase` rewrites every branch above the one that moved, so a force push
is how the remote catches up. `gh stack sync` does the push as part of its own
sequence. Never reach for `git push --force` by hand: it is denied, and the
extension already knows which branches it rewrote.

## Common errors

- A conflict during `gh stack rebase` stops the cascade at the conflicting layer.
  Resolve it in that layer, then rerun; the layers above have not moved yet.
- `gh stack checkout` against a PR number needs that PR to be part of a stack.
  Use `gh stack link` to adopt PRs that were opened separately.
- A layer whose base drifted shows in `gh stack view` as out of position. `gh
  stack modify` restructures rather than recreating.
