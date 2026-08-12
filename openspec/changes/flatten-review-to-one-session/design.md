## Context

The review surface has four layers today, and only the third is at issue.

```
sysinit-agent workspace roots|changes|health     lines on stdout, no editor
utils.gitrepo                                    asks it, degrades to fd, then git
harness.api.open_review                          fans out to N codediff sessions
codediff.nvim + review.nvim                      the diff, the merge editor, the comments
```

Layer 1 is a filter and composes from a shell. Layer 4 is upstream and is what makes
the diff worth reading: the inline view puts the real file buffer on the modified
side, proven in a headless run against three real repositories:

```
repo=.../neph.nvim buf=.../proposal.md buftype="" modifiable=true listed=true
```

Layer 3 is the whole problem. It is the only layer that reaches into another
plugin's internals, and it does so four times, all to answer one question that the
fan-out created: which of these tabs is the owner supposed to be in.

## Goals / Non-Goals

- Goal: one code path for one repository and for forty, with no branch on the count.
- Goal: the landing state is decided by this repository's code, not by which
  asynchronous render finished last.
- Goal: the boundary of a workspace is data, supplied by whoever created it.
- Non-goal: replacing the diff engine, the merge editor, or the comment layer.
- Non-goal: Neogit, which stays one repository per status buffer.
- Non-goal: reviewing several repositories at once on screen. One at a time is the
  decision, not a limitation to be lifted later.

## Decisions

### Keep codediff.nvim and review.nvim

The tools are not what failed. codediff answers three things that the built-ins do
not: a single-pane inline view whose modified side is the real file buffer, a
three-pane merge editor with accept keymaps for a conflicted file, and
character-level highlighting from VS Code's own engine. review.nvim adds the comment
threads the harness sends to an agent.

Alternative rejected: a quickfix list plus built-in diff mode (`:diffthis` against a
`git show` scratch buffer). It costs about 150 lines and loses the single-pane
inline view, since diff mode needs two windows, and the merge editor.

Alternative rejected: a quickfix list plus gitsigns inline hunk overlays. This is
closer, because the overlay lands in the real buffer, but it loses the merge editor
and the comment layer, and gitsigns has no character-level highlight.

Alternative rejected: keeping the store and rebuilding the comment layer.
`review/store.lua` and `review/export.lua` carry no codediff dependency, so the
comment data is portable, but `marks.lua`, `keymaps.lua`, `hooks.lua`, and
`popup.lua` are bound to codediff's buffers. That is 300 to 500 lines to rebuild and
then own, against 25k lines of upstream that already works.

### One session at a time, in one tab

`:CodeDiff` creates its own tab, lands the owner in it, and closes it when issued
from inside. Measured over three real repositories opened and closed in sequence:

```
OPEN1  tab=2 tabs=2 repo=.../neph.nvim
CLOSE1 tab=1 no session, tabs=1
OPEN2  tab=3 tabs=2 repo=.../seshy
CLOSE2 tab=1 no session, tabs=1
```

The tab count returns to one every time and nothing accumulates. With one session
there is no tab to choose, so the chained opens, the session poll, the render wait,
and the focus re-assertion are all deleted rather than tuned.

Alternative rejected: keep the fan-out and wait harder. The mover runs 150ms after
review.nvim attaches and does not check the current tabpage, so any wait can be
outlasted. The GUI measurement in `proposal.md` is that alternative, already tried.

Alternative rejected: one session covering several repositories. git pathspecs are
relative to one repository and `git status` reports a nested repository as one
untracked directory, so a single session cannot see across roots at all.

### The quickfix list is the cross-repository index

The natural unit of a review is a changed file, and a file's path is absolute, so a
list of changed files is indifferent to how many repositories they come from. The
quickfix list is Neovim's own structure for that, which means `:cdo`, `]q`, bqf, and
any picker already read it with no knowledge of this feature. Within a repository,
codediff's explorer stays the index, with `view_mode = "list"` and
`cycle_hunks_across_files`.

Two granularities, one data structure: the quickfix entry carries its file, and the
repository is derived with `gitrepo.owning_root`, so stepping to the next repository
is a filter over the same list rather than a second list.

Alternative rejected: a bespoke list buffer. It would duplicate what bqf, pqf, and
trouble already render, and nothing else could consume it.

Alternative rejected: one quickfix list per repository. The list would then have to
be swapped in step with the session, which reintroduces a second thing to keep
synchronised.

### The workspace boundary comes from the environment

`workspace()` reads `$SYSINIT_WORKSPACE`, and falls back to the cwd when it is unset
or names a path that does not exist. The seshy integration exports it from `s()`,
which already resolves the session directory and enters it, so one line there
replaces the hardcoded path in two languages.

This inverts the dependency. Today the editor knows seshy's state directory; after
this, seshy states its own boundary and the editor knows only the variable, which
direnv, a shell function, or a `cd` wrapper can set just as well.

Alternative rejected: a marker file, such as `.workspace` at the root. It needs an
upward walk, it needs a file written into a directory the owner did not ask to have
one in, and it cannot express "this session, not its parent".

Alternative rejected: keeping the seshy rule alongside the variable. Two sources for
one answer is the drift this change exists to remove, and the shell that enters a
session is exactly where the variable can be set.

Alternative rejected: walking up to the outermost `.git`. A workspace of repositories
is often not a repository, and when it is, the outermost root is the wrong answer
for a nested checkout.

## Rollout & Gating

- `stylua --check` over the changed Lua, `gofmt -l`, `go vet ./...`, `go test ./...`,
  and `nix flake check` exit 0 before each phase closes.
- `nix build .#darwinConfigurations.lv426.system` builds this tree, and the
  `sysinit-agent` in that closure answers with the new workspace rule. A bare
  `nh darwin build` does not gate this repository, since it reads `NH_FLAKE`.
- Every behaviour claim is proven by a headless run against a fixture and, for the
  focus and buffer-count claims, by a run in a real WezTerm pane, because the
  defect this change removes was invisible headless.
- The focus claim is proven over at least five consecutive runs, not one, because
  the state it replaces passed twice out of three.
- Applied with `nh darwin switch` from the `sysinit.laurel` checkout in its own
  pane, after `git push`.

## Risks / Trade-offs

- The edit-event log key derives from the workspace, so the log name for a directory
  can change when the variable starts being exported. A review that finds no events
  opens the full workspace diff and says so, which is the existing degraded path.
  The health report names the log it resolved, which is how a mismatch is read
  rather than guessed.
- One session at a time means reading two repositories side by side is no longer
  possible. That was the fan-out's only advantage, and it cost a nondeterministic
  landing tab, 24 buffers, and a growing pile of empty tabs in the saved session.
- The quickfix list is a global. A review overwrites whatever was in it. The list is
  filled with a title naming the review, so the overwrite is visible.

## Migration Plan

- `rework-diff-review-surface` is archived first, with its record intact. This change
  supersedes its fan-out decision and cites the measurement that broke it.
- The keymaps keep their names, so `<leader>dd`, `<leader>dr`, `<leader>dR`, and
  `<leader>d?` mean what they mean today.
- The health report gains the workspace source, so the first question after the
  switch has an answer in the editor.

## Open Questions

- Whether the repository step deserves its own keymap in addition to `]q` crossing a
  boundary. Deferred until the list has been walked on real work.
- Whether the quickfix list should hold hunks rather than files. Hunk entries would
  make `]q` a hunk walk, at the cost of computing every diff up front.
