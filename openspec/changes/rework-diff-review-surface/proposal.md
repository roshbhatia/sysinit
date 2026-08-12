> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

Two complaints, one surface. Every diff review path in this Neovim config assumes
the workspace is one git repository, and every one of them opens a two-pane or
three-pane diff when the owner wants to read the change in the buffer it lands in.

### One root cannot represent a workspace

`modules/home/programs/neovim/config/lua/utils/gitrepo.lua` already knows how to
find every repo. `M.scan` runs `fd` to depth 5 for `^[.]git$` and returns a sorted
list. `M.resolve` then throws that away: it returns `M.buffer_root() or
M.cwd_root()` and only scans when neither answers.

Measured on a fixture with `repoA` and `repoB` nested inside a workspace that is
itself a repo:

```
cwd_root  = .../ws
scan      = { ".../ws", ".../ws/repoA", ".../ws/repoB" }
resolve   = .../ws
```

`resolve` never prompts, because `cwd_root()` succeeded. The three consumers
(`<leader>dd` and `<leader>dH` in `plugins/codediff.lua:99,108`, `<leader>gg` in
`plugins/neogit.lua:99`) therefore operate on the outer repo alone.

Git makes that fatal rather than merely partial. In the same fixture the outer
repo reports the nested repos as untracked directories and names one changed file:

```
$ git -C ws status --porcelain     $ git -C ws diff --name-only
 M o.txt                           o.txt
?? repoA/
?? repoB/
```

`repoA/f.txt` is modified and no session rooted at `ws` can show it, whatever the
picker does. A picker only chooses which repo to be blind about.

Two more paths do not even reach `gitrepo`. `<leader>dr` is a bare
`<Cmd>Review<CR>`, and review.nvim `8e4bc16c` resolves its own root by running
`git rev-parse --show-toplevel` in the process cwd
(`lua/review/storage.lua:18`, `lua/review/picker.lua:22`). And
`harness.api.review_touched` (`harness/api.lua:212`) takes one root from
`vim.fn.getcwd()`, then counts every touched file outside it as `outside` and
drops it. The edit bus is workspace-wide by construction: an event carries an
absolute path, and a seshy session such as `edit-bus-trial` spans 3 repos. So the
one surface built to show what an agent just wrote discards the majority of it in
exactly the layout the owner works in.

### The side-by-side default is a choice, not a limit

Both diff plugins already ship the inline view.

codediff.nvim `31510a9b` has `diff.layout = "side-by-side" | "inline"`, a
single-pane mode rendering deletions as `virt_lines`
(`lua/codediff/ui/inline.lua:1-2`), a `t` toggle bound per session, and
`--inline` / `--side-by-side` per-invocation flags. Its conflict view is a
separate three-pane layout that `diff.layout` does not touch, so an inline
default costs nothing there. This config sets none of it and takes the
side-by-side default.

claudecode.nvim `2390c6e4` ships `lua/claudecode/diff_inline.lua`, described
upstream as "a VS Code-style unified inline diff view", reached by
`diff_opts.layout = "unified"`. `plugins/claudecode.lua:41-43` sets
`diff_opts = { open_in_new_tab = true }` and leaves `layout` at its `"vertical"`
default. So each edit Claude makes opens a new tab holding a vertical split, which
is the "various buffers open" and "two or three way diff" the owner is describing.

gitsigns `31d6fb2d` is the one path already correct on both counts: it attaches
per buffer, so each buffer resolves its own repo, and `<leader>ghp` already calls
`preview_hunk_inline()`. It is the existing proof that per-buffer beats
per-session here.

### The pieces are joined through each other's internals

The scoped review needs five things at once to produce anything: an event log, a
loaded watcher, a non-empty event set, codediff, and review.nvim. It reaches
`codediff.ui.lifecycle` for a session and calls
`require("review")._check_codediff_session()`, an underscore-prefixed function in
another plugin (`harness/api.lua:255-259`), and `plugins/review.lua` patches
`vim.filetype.match` globally to reconcile the two plugins' disagreement about
whether a path is a string or a record.

So on a machine where any one of the five is missing or older, the surface does
not narrow, it stops: `<leader>dR` warns and opens nothing. There is also no way
to ask what is wrong. Nothing reports whether the watcher attached, which log it
resolved, or how many events it read.

## What Changes

Root resolution becomes plural, and it moves down a layer so a shell can ask the
same question an editor asks. The scoped agent review becomes the full review with
a narrower file set, so a missing optional input narrows the answer instead of
failing the call. The inline layout becomes the default for both plugins.

Three layers, joined by lines of absolute paths and nothing richer. A layer never
imports a layer above it, and a surface never imports another surface.

- `pkgs/sysinit-agent/`: a `workspace` subcommand printing the repos under a
  directory and the changed paths within them, one per line, needing git alone.
- `utils/gitrepo.lua`: a cached workspace-roots API that prefers the subcommand,
  falls back to the existing `fd` scan, then to `git`, and stops letting a cwd
  toplevel hide nested repos.
- `harness/api.lua`: `review_touched` groups edits by the repo each lives in, and
  falls through to the full diff rather than warning when the bus is silent.
- `plugins/codediff.lua`: default to the inline layout; keep `t`; open the repos
  that have changes, bounded, naming the remainder.
- `plugins/claudecode.lua`: `diff_opts.layout = "unified"`, and stop opening a tab
  per edit.
- `plugins/review.lua`: route `<leader>dr` through the same resolution as the
  scoped path, so the two agree about what is being reviewed.
- `plugins/neogit.lua`: prompt whenever the workspace holds more than one repo.
- A health section reporting which layer answered, the repos found, the watcher's
  state, the log it resolved, and the events it read.

### Non-goals

No change to codediff or review.nvim upstream. A single explorer spanning several
repos needs a multi-root session model neither plugin has; this change composes
per-repo sessions instead.

No new plugin. Both inline renderers already exist in plugins that are already
pinned and installed.

No change to what the edit bus writes. The writer, its format, and its bound are
settled and archived. This change only fixes what the reader does with an event
whose path is outside one root.

No accept/reject of agent edits per hunk in the live buffer. codediff's hunk
staging (`<leader>hs`, `<leader>hr`) already operates on the git index, and a
second per-hunk accept model over the same buffer would be two sources of truth.

No removal of the two existing reaches into codediff and review.nvim internals.
They are the attach seam and there is no upstream API to replace them with yet.
This change adds no third reach, and makes their failure visible.

## Behavior

### Each layer answers on its own

The repository set and the changed-path set SHALL be obtainable without an editor,
as lines on stdout, so a shell, another editor, or a harness hook can consume them.
The Neovim adapter MUST NOT require that command to exist.

- WHEN the subcommand is on `PATH`
- THEN the editor uses it, and the health output names it as the source

- WHEN the subcommand is absent or older than the feature
- THEN the editor answers the same question from `git` and reports which fallback
  answered

#### Scenario: the directory is unusable (negative)

- WHEN the subcommand is given a path that does not exist
- THEN it exits non-zero with one message on stderr, and prints nothing on stdout

### A missing optional input narrows the review, never fails it

- WHEN no edit events exist, the watcher is not loaded, or the harness writes none
- THEN the review opens over the full working diff of the workspace's repos, and
  the message says why the scope is not narrower

- WHEN the recorded edits exist but name no path inside any workspace repository
- THEN the full diff still opens, and the count outside is named

### The state of the watching is reportable

- WHEN the owner asks for health
- THEN one place reports which layer answered the last roots query, the
  repositories found, whether the edit-event watcher is attached, the log path it
  resolved, the number of events read, and whether each review plugin is loaded

### The workspace, not the cwd, decides the repo set

`utils.gitrepo` SHALL expose the set of repositories under the workspace, and it
MUST include a repository nested inside another repository.

- WHEN the workspace root is itself a git repo and holds two nested repos
- THEN the workspace API returns all three, and no caller receives only the outer
  one

- WHEN the workspace holds exactly one repo
- THEN no prompt appears and every path behaves as it does today

#### Scenario: no repository anywhere (negative)

- WHEN the workspace holds no git repository
- THEN each entry point reports that in one message and opens nothing

### A scoped review covers every repo an agent wrote to

- WHEN the recorded edits span two repos in the workspace
- THEN the review reaches the files in both, and the count the owner is shown
  equals the number of scoped files, with nothing silently dropped

- WHEN an edit names a path under no repository in the workspace
- THEN it is reported as outside, with its count, and the rest still open

#### Scenario: the whole set is unreachable (negative)

- WHEN every recorded edit is outside every repo in the workspace
- THEN the message says so, names the count, and names the full-diff path

### Inline is what opens, and the other layouts stay one key away

The inline layout SHALL be the default for the working diff and for an agent's
own edit. Side-by-side MUST remain reachable without reconfiguration, and the
three-pane conflict view MUST be unaffected.

- WHEN a diff opens with no layout argument
- THEN it opens as one pane with deletions rendered in place

- WHEN the owner presses the layout toggle in that diff
- THEN it becomes side-by-side, and the comment layer survives the toggle

- WHEN a file in the diff holds a merge conflict
- THEN the conflict view opens with its own layout and its accept keymaps intact

#### Scenario: an agent edits a file (negative for tab spawning)

- WHEN an agent writes a file through the claudecode protocol
- THEN the diff renders inline, and reviewing several edits does not accumulate
  one tab per edit

## Impact

Two halves with different rollout costs, kept separable on purpose.

`pkgs/sysinit-agent/` gains one subcommand, which changes the closure and needs a
switch. `modules/home/programs/neovim/config/lua/utils/gitrepo.lua`,
`harness/api.lua`, and the four plugin specs under
`.../lua/plugins/` are Lua, installed as an out-of-store symlink
(`sysinit-nvim.nix:13`), so they are live without a switch. The adapter's fallback
is what lets either half land first.

Keymaps keep their current meanings. `<leader>dd`, `<leader>dH`, `<leader>dr`,
`<leader>dR`, and `<leader>gg` all still do what their descriptions say; what
changes is how many repos they see and which layout they open.
