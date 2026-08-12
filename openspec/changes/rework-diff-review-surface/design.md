## Context

`utils/gitrepo.lua` is 78 lines and already holds the hard part. `M.scan` shells
out to `fd -H -I -t d -t f --max-depth 5 '^[.]git$'` and returns a sorted,
deduplicated list of roots, asynchronously. What is missing is a caller that wants
more than one.

`M.resolve` was written for a different question: "which single repo does this
command mean?" Its preference order, buffer root then cwd root then scan, answers
that question well and answers "what is in this workspace?" wrongly, because a
workspace directory that happens to be a git repo satisfies `cwd_root()` and the
scan never runs.

The scale is real. `sy list` reports seshy sessions spanning 3 repos
(`edit-bus-trial`), 5, 6, 8, and 20 (`fra-region-spin-up`). So a design that opens
a tab per repo without a bound is a design that opens 20 tabs.

Both inline renderers already exist upstream, pinned and installed, so the layout
half of this change is configuration plus proof, not implementation.

The coupling already hurts. `harness/api.lua:255-259` reaches into
`codediff.ui.lifecycle` for a session and then calls
`require("review")._check_codediff_session()`, an underscore-prefixed function in
another plugin. `plugins/review.lua` monkey-patches `vim.filetype.match` globally
to work around the two plugins disagreeing about whether a path is a string or a
record. Both are the same defect: this config joins two plugins by reaching
through their internals, so either plugin's next release can silently remove the
comment layer. That is the coupling this change must not add more of.

## Goals / Non-Goals

Goals: every review entry point sees every repo under the workspace; the scoped
agent review stops discarding edits; inline is what opens; side-by-side and the
conflict view stay reachable; each layer is useful and testable without the ones
above it.

Non-goals: a multi-root session inside codediff or review.nvim; a new plugin; any
change to the edit-bus writer; a per-hunk accept model for agent edits competing
with codediff's index staging.

## Decisions

### Three layers, each useful alone, joined by plain data

The complaint that a review surface is irritating on a machine where the watching
does not work is a coupling complaint. Today the scoped review needs the edit bus,
a running watcher, codediff, review.nvim, and one git root, and it degrades to a
warning if any of the five is missing. So the design is layered, and each layer
answers one question with plain output.

```
sysinit-agent workspace        # layer 1: which repos, what changed. git only.
        ^ text on stdout
utils.gitrepo                  # layer 2: the Neovim adapter. CLI if present, git if not.
        ^ list of paths
codediff / neogit / review     # layer 3: surfaces. Each consumes paths.
```

The contract between layers is a list of absolute paths, nothing richer. A layer
MUST NOT import a layer above it, and a surface MUST NOT import another surface.

Two rules follow, and they are the ones worth checking in review:

- Every layer works when the layer above is absent. Layer 1 is a shell command
  and needs no editor. Layer 2 answers with `git` when the binary is missing.
- A missing optional input narrows the answer, it never fails the call. No edit
  events means the full diff, not a warning and nothing.

### Layer 1 is a `sysinit-agent` subcommand, because a shell can use it

`sysinit-agent workspace roots` prints one absolute repo path per line.
`sysinit-agent workspace changes` prints one changed path per line, each already
resolved against the repo that owns it. Both take a directory and default to the
working one. Both exit 0 with empty output when there is nothing, and non-zero
only when the argument is unusable.

The reason to put it in the Go binary rather than in Lua is composability in the
literal sense: the answer becomes available to a shell, to `fzf`, to another
editor, to a harness hook, and to a machine with no Neovim at all.

```bash
# good: the answer composes, because it is lines of paths on stdout
sysinit-agent workspace changes | fzf --multi | xargs -o nvim

# bad: the same answer trapped behind an editor's require()
nvim --headless -c 'lua print(vim.inspect(require("utils.gitrepo").changes()))'
```

`internal/repo` already holds `RootAt`, `Workspace`, and `RelativeToRoot`, so the
subcommand is composition of existing functions plus a walk.

### Layer 2 prefers the CLI and never requires it

`utils.gitrepo` calls `sysinit-agent workspace` when it resolves on `PATH`, and
falls back to the `fd` scan it already has, and then to `git rev-parse` alone.
Each fallback is narrower and none is an error, because this config is also
deployed where the binary is older than the subcommand.

The fallback order is a behaviour, not an implementation detail, so it is stated
in the health output below rather than left for a reader to infer from a stall.

### The workspace set is separate from the single-repo resolver

`M.resolve` keeps its contract, because neogit genuinely opens one repository and
a status buffer spanning several would be a fiction. It changes only where it
looks: it consults the workspace set first and prefers the buffer's own repo
within it, so a nested repo can win over the outer one. When the set holds more
than one candidate and no buffer decides it, it prompts, which it already knows
how to do.

A new `M.workspace_roots` answers the plural question. It is the one callers use
when the review is over changes rather than over a repository.

### Roots are cached per workspace, invalidated on a directory change

`fd` to depth 5 over a 20-repo tree is not free, and `<leader>dr` would pay it on
every open. The set is cached against the workspace directory and dropped on
`DirChanged`. A cache keyed on anything finer would go stale the first time a repo
is cloned into the workspace, and the owner can already force a rescan by
reopening the picker.

### Which repos open is decided by changes, not by existence

A workspace repo with a clean tree has nothing to review, so it is not opened and
not counted. Layer 1 answers this, concurrently per root. That also means the
common case of one dirty repo in a workspace of five behaves exactly as it does
today, with no prompt.

### A bounded number of tabs, and the remainder named rather than hidden

At most four dirty repos open as tabs, ordered by changed-file count, with the
largest focused. Above four, the entry point prompts with the repo list and each
repo's count, and opens what the owner picks.

Four is chosen against the measured distribution: 3 of the 8 seshy sessions span
4 or fewer repos, and the 20-repo session is what makes an unbounded fan-out
untenable. The remainder is always named in the message with the command that
opens it, because a silent truncation reads as "that was everything".

### The scoped review groups by the repo each edit lives in

`review_touched` currently computes one root and one pathspec list. It computes a
map instead: each absolute path is assigned to the longest workspace root that
prefixes it, which is what makes a nested repo win over its parent. Each group
becomes one codediff session with its own pathspec list.

Paths under no root keep today's treatment, reported with their count, because a
pathspec cannot express them and inventing a repo for them would be worse than
naming the gap.

### The edit bus narrows a review and never gates one

The scoped path and the full path become the same code with a different file set,
so a missing bus, an unloaded watcher, an empty event set, or a harness with no
hook all land on the full diff rather than on a warning. The event count is
already documented as a floor; this is what makes the floor behave like one.

<example>
<bad>Harness: the edit-event watcher is not loaded (and nothing opens)</bad>
<good>Harness: no agent edits recorded, reviewing the full diff in 2 repos</good>
</example>

### The layout default is set in config, not per invocation

`diff.layout = "inline"` in the codediff setup, rather than passing `--inline` at
each call site. The `t` toggle reads the session's layout, and `--side-by-side`
overrides per invocation, so both escape hatches keep working. Setting it at the
call sites would leave `:CodeDiff` typed by hand on the old default and split the
behaviour by how the diff was opened.

The conflict view is untouched: `session.layout` gates only the two-pane path
(`lua/codediff/ui/layout.lua:47`), and the conflict layout has its own
positioning options and its own accept keymaps, which this config already binds
to `<leader>di`, `<leader>dc`, `<leader>db`, and `<leader>dx`.

### claudecode renders unified in the current tab

`diff_opts.layout = "unified"` selects `diff_inline.lua`, and `open_in_new_tab`
goes to false. The pair is what removes the accumulating tabs: a new tab per edit
was tolerable only because a vertical split needed the room.

### "Is the watching working" is a question with an answer, not a guess

A `:checkhealth` section reports, in one place: which layer answered the last
roots query, the repos found, whether the edit-event watcher is attached, which
log path it resolved, how many events it has read, and whether codediff and
review.nvim are loaded. `sysinit-agent workspace --health` prints the parts that
do not need an editor.

This is the answer to being irritated on a machine where the watching is not
working as expected. The failure is then readable in one command instead of
inferred from a review that opened fewer files than expected.

## Rollout & Gating

Two halves with different rollout costs, deliberately kept separable.

The Lua half is live without a switch: `modules/home/programs/neovim/config` is
installed through `mkOutOfStoreSymlink` (`sysinit-nvim.nix:13`), so a new Neovim
picks it up and a build reports an unchanged closure. Its gates are
`stylua --check`, `nix flake check`, and headless proofs.

The Go half changes the closure, so it needs `git push` and then
`nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane,
gated on `nix flake check`, `nh darwin build`, `gofmt -l`, `go vet`, and
`go test ./...`. Layer 2's fallback is what lets the Lua half ship first and work
before the binary exists.

Each behavior criterion is proved against a fixture workspace holding nested
repos, in headless Neovim, before the owner is asked to judge anything. The
fixture is built by the phase that needs it and is not committed.

The owner's confirm is the only judgment that matters here, because the complaint
was about how the surface feels: they open a real multi-repo workspace, run each
entry point, and accept or reject what appears.

## Risks / Trade-offs

Four tabs is still four tabs. A workspace with four dirty repos opens four
sessions and the owner navigates between them. The alternative, one aggregated
explorer, needs upstream work in codediff, and this change is explicitly composing
around that.

A CLI layer is a second implementation of a question Lua could answer alone. The
cost is real: two code paths, and a fallback that can disagree with the binary.
The mitigation is that the fallback answers the same question over the same `git`,
and that the health output names which one answered.

`fd` at depth 5 misses a repo nested deeper. That bound predates this change and
is kept rather than widened, because a deeper scan pays on every workspace. A
missed repo is silent, which is the sharp edge; the health output naming how many
roots were found is what makes it noticeable.

Inline diff of a large rewrite is long. A file whose every line changed renders as
its old lines and its new lines in one buffer, where side-by-side would show them
abreast. `t` is the answer, and the compact mode (`gc`) already folds unchanged
regions.

The unified claudecode view is read-only. Accepting or rejecting stays on
`ClaudeCodeDiffAccept` and `ClaudeCodeDiffDeny`, so the owner cannot edit the
proposed text in place before accepting it. That is upstream's model, not a
regression, and it is why the working-diff path keeps codediff's editable panes.

The two internal reaches into codediff and review.nvim survive this change. They
are the existing attach seam, and replacing them needs an upstream API that does
not exist yet. This change does not add a third, and the health section is what
makes their failure visible rather than silent.

## Migration Plan

No state to migrate. The edit-event log, its bound, and the review comment store
are unchanged, and every keymap keeps its current binding and description.

A workspace whose review previously showed one repo will start showing more, which
is the intent. Nothing that worked stops working: a single-repo checkout, which is
how most of these repos are opened, takes the same path it takes today with no
prompt added.

A box running an older `sysinit-agent` takes layer 2's fallback and gets the same
answer more slowly, so the Lua and Go halves can land in either order.

## Open Questions

Should the full working diff (`<leader>dr`) fan out across repos the same way the
scoped review does, or open only the repo the current buffer lives in and name the
others? The proposal assumes it fans out, because the owner asked for the normal
review to work this way, and the four-tab cap is what makes that safe. Worth
confirming against how it actually feels in the 20-repo workspace.

Is four the right cap, or should it be two? Four is defended from the seshy
distribution above, not from use. The owner's confirm task is where this gets
settled.

Should layer 1 also emit a machine-readable form? Lines of paths compose with
`xargs` and `fzf` and need no parser, and a second format is a second contract to
keep. Deferred until a consumer needs the change kind alongside the path.
