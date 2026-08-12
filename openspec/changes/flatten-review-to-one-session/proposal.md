> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

`rework-diff-review-surface` made the review span every repository under the
workspace. It did it by opening one codediff session per repository, one tab each,
bounded at four. That fan-out is the wrong shape, and two things this change fixes
are consequences of it rather than separate faults.

### The fan-out cannot be made deterministic

Four repositories mean four asynchronous sessions, and the tab the owner lands on
is whichever one moved the cursor last. `harness/api.lua` now holds four
workarounds for that single fact: opens are chained rather than looped, each waits
for a session to appear, each then waits for a render event, and the landing tab is
taken back 250ms later.

It is still not deterministic. Measured in a real WezTerm pane on
`~/github/personal/roshbhatia`, 46 repositories, 7 dirty, one `<leader>dd` per run:

```
run 1   focus = seshy       (14 changed files)
run 2   focus = neph.nvim   (77 changed files)
run 3   focus = neph.nvim   (77 changed files)
```

The same code passes headless every time. review.nvim focuses a session's modified
window 150ms after it attaches to it and does not check that the owner is still on
that tab (`review/hooks.lua:228`), so the outcome is decided by which render
finished last. No wait this side of the seam can close that, because the mover runs
after the wait ends.

### The fan-out is expensive to look at

The same run leaves 24 buffers and 18 windows open, and every session tab that
auto-session saves comes back as an empty tab. The saved layout for that workspace
now carries five:

```
$ grep -c '^tabnew' ~/.local/share/nvim/sessions/%2FUsers%2Froshan%2Fgithub%2Fpersonal%2Froshbhatia.vim
5
```

That number grows by one for every restart after a review.

### The workspace boundary names one tool

`utils.gitrepo.workspace()` treats a cwd under `~/.local/state/seshy/sessions` as a
session directory and returns the session as the workspace. `repo.Workspace` in
`pkgs/sysinit-agent` carries the same rule. So a workspace is only a workspace when
seshy made it, and a plain directory of repositories, a `git worktree` set, or a
`~/src` tree gets the cwd rule by accident rather than by intent.

The editor should not know that seshy exists. Whatever puts the owner in a
workspace should say so.

## What Changes

- The review opens exactly one codediff session at a time, in one tab, for the
  repository that owns the file under review. `MAX_TABS`, the chained opens, the
  session poll, the render wait, and the focus re-assertion all go away, because
  none of them has a race left to guard.
- The changed files of every repository under the workspace become one quickfix
  list, absolute paths, status in the entry text. That list is the cross-repository
  index; codediff's own explorer stays the within-repository index.
- Moving to a quickfix entry in a different repository swaps the session in place,
  so `]q` walks the whole workspace without the owner naming a repository.
- The workspace root comes from `$SYSINIT_WORKSPACE` when it is set, else the cwd.
  The seshy shell integration exports it, in the `s()` function that already
  resolves and enters the session. `repo.Workspace` reads the same variable.
- codediff and review.nvim stay. They are 25k lines of upstream that answer the
  inline rendering, the merge editor, and the comment layer, and this change touches
  none of that.

### Non-goals

No change to codediff or review.nvim, and no fork of either. Every claim about the
diff, the merge editor, and the comment layer is a claim about what they already do.

No new plugin. The list layer uses the quickfix list and the renderers already
pinned here, `nvim-bqf` and `trouble.nvim`.

No change to what the edit bus writes. This change only alters which directory the
reader calls the workspace.

No multi-repository view. Reading two repositories side by side is what the fan-out
bought and what this change deliberately gives up.

## Behavior

### The review reads the same at any repository count

- WHEN the workspace holds one repository
- THEN the review opens one session on it, with the quickfix list holding that
  repository's changed files

- WHEN the workspace holds forty repositories and seven have changes
- THEN the review opens one session, on the repository with the most changes, with
  the quickfix list holding every changed file in all seven

- WHEN the owner moves to a quickfix entry in a repository other than the open one
- THEN the open session closes, a session for that repository opens in its place,
  and the tab count returns to what it was before the move

#### Scenario: nothing has changed (negative)

- WHEN every repository under the workspace is clean
- THEN one session opens on the repository the owner is standing in, reading
  `Changes (0)`, and the quickfix list is left alone

An empty diff is a diff. A message saying "nothing changed" reads the same as a
review that looked somewhere else, and a pane naming the repository does not.

- WHEN any entry point is given a repository with nothing changed
- THEN it opens the same empty session, whether or not the caller already knew the
  repository was clean

#### Scenario: no repository at all (negative)

- WHEN the workspace holds no git repository
- THEN no session opens and the message names the directory that was searched

### The landing tab is decided, not raced

- WHEN a review opens over any number of repositories
- THEN the tab the owner lands on is the one session that was opened, and repeated
  runs of the same review land in the same place

- WHEN a review has finished opening
- THEN the number of tabs holding a diff is exactly one, whatever the repository
  count

### The workspace boundary is stated by whoever set it

`utils.gitrepo.workspace()` and `repo.Workspace` SHALL agree, and both SHALL read
the boundary from the environment before applying any rule of their own.

- WHEN `$SYSINIT_WORKSPACE` names a directory
- THEN both the editor and `sysinit-agent` treat it as the workspace root, whatever
  created it

- WHEN it is unset
- THEN both fall back to the cwd, and a single-repository checkout still reviews
  itself

#### Scenario: the variable names a directory that is gone (negative)

- WHEN `$SYSINIT_WORKSPACE` names a path that does not exist
- THEN both fall back to the cwd rather than reporting an empty workspace

### The list is a list other tools can use

- WHEN the changed files are collected
- THEN they are in the quickfix list, so `:cdo`, `]q`, and any quickfix picker act
  on them with no knowledge of this feature

- WHEN a review opens
- THEN one index of its files is on screen, codediff's explorer, and the quickfix
  list is filled and left closed

### The reasoning for an edit is in the review without being asked for

A note SHALL be derived from what the harness already wrote. Nothing in this
feature SHALL instruct an agent to file one.

- WHEN a hook-capable harness edits a file and its transcript holds text about that
  turn
- THEN a note is filed against the repository holding the file, anchored on the
  first line the edit changed, and the next review renders it in the diff

- WHEN the same region of the same file is edited again
- THEN the earlier derived note for that region is replaced rather than stacked,
  and a note on a different region of the same file is left alone

#### Scenario: the harness narrated nothing (negative)

- WHEN the transcript holds no text for the turn
- THEN no note is filed, because a note that restates the diff is worse than no
  note

#### Scenario: the hook cannot do its work (negative)

- WHEN the payload, the transcript, or the repository lookup fails in any way
- THEN the hook prints nothing and exits 0, so a bookkeeping failure never reads as
  a failed tool call inside the agent's loop

### One key means one thing

- WHEN the owner presses a `<leader>d` sequence
- THEN exactly one mapping owns it, and no sequence is both a which-key group and a
  mapping

- WHEN the owner presses `^x` on a row of the session switcher
- THEN what closes is the thing that row names: a session's panes, a tab's panes,
  or that one pane

- WHEN the close would leave the workspace the owner is in with no pane
- THEN the window moves to `default` first, and the switcher does not reopen over
  the session the owner has just landed in

- WHEN the row names `default`, from anywhere
- THEN `default` is reset to one pane rather than closed, because it is where every
  other close falls back to

- WHEN the owner presses `^[` or `^]`
- THEN the session steps back or forward through the same order the switcher lists

#### Scenario: the row names the pane the switcher was opened from (negative)

- WHEN closing the row would kill the pane running the selector
- THEN it is closed, and the switcher does not reopen, because it cannot reopen
  against a pane that is gone

#### Scenario: `default` already holds one pane (negative)

- WHEN `^x` names `default` and `default` holds one pane
- THEN nothing is closed and the switcher says so

### A layer taken out narrows the review, never fails it

Every input the review reads is optional. Each one SHALL degrade to a named
fallback, and the health report SHALL say which fallback is in use and what it
cost.

- WHEN `sysinit-agent` is not on PATH
- THEN the repository query falls back to the `fd` scan, the review opens with no
  notes, and the report names the binary that is missing

- WHEN neither `sysinit-agent` nor `fd` is on PATH
- THEN the query falls back to `git rev-parse`, which sees one repository, and the
  review opens on it

- WHEN an upstream plugin renames a seam this configuration reaches into
- THEN the review opens without the part that seam provided, says so once, and the
  health report names the seam and the cost

#### Scenario: a missing command reaches a process spawn (negative)

- WHEN a command the review runs is not on PATH
- THEN it is not spawned at all, because `vim.system` raises for a missing binary
  rather than returning a non-zero code, and a raise inside the open path would fail
  the diff rather than lose one layer of it

## Impact

- `modules/home/programs/neovim/config/lua/harness/api.lua`: the fan-out is
  replaced by a single-session open and a repository step. Net deletion. One git
  call now answers both whether a repository is unmerged and whether it is clean,
  where there were two questions and only one of them was asked.
- `modules/home/programs/neovim/config/lua/harness/notes.lua` and
  `modules/home/programs/neovim/config/lua/harness/health.lua`: the note layer
  guards its own command and the report names each layer's fallback, so a machine
  missing one of them narrows the review instead of failing it.
- `modules/home/programs/neovim/config/lua/utils/gitrepo.lua`: the seshy path rule
  becomes an environment read.
- `modules/home/programs/zsh/integrations/seshy-wezterm.zsh`: exports the boundary
  it already computes.
- `pkgs/sysinit-agent/internal/repo/repo.go`: the same environment read, so the
  edit-event log key and the editor cannot disagree.
- `pkgs/sysinit-agent/internal/note/auto.go`: the note half of the same hook the
  edit log already runs on. New file, and the only new command.
- `modules/home/programs/llm/runtime/default.nix` and
  `modules/home/programs/llm/harnesses/claude/default.nix`: a second PostToolUse
  hook on the matcher that is already there. Claude only, because the transcript
  shape read is claude's.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui/switcher.lua`: `^x` reads the
  row's kind instead of its workspace field, and the decision it makes is a pure
  function of the pane list, separate from the killing. `^[` and `^]` are re-stated
  here rather than stripped from the plugin. That costs `^[` as a way to send ESC:
  a pane never sees that keypress again, and locked mode is the way back to it.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui/format.lua` and `tabtitle.lua`:
  a wrapper process holding a pty is no longer what a tab or pane is named.
- Derived notes are stored with an author naming them derived, so the record can be
  told apart from a note a human or an agent wrote deliberately. Notes written
  before this change carry the old author and are untouched.
- The edit-event log file name derives from the workspace, so a log written before
  this change and one written after can differ for the same directory. The watcher
  reads whatever the current rule resolves, and a review that finds no events opens
  the full diff, which is the documented degraded path rather than a failure.
