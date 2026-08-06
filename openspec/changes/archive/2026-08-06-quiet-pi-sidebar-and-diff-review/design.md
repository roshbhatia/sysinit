## Context

The sidebar lives in
`modules/home/programs/llm/harnesses/pi/extensions/openspec-sidebar/index.ts`. It is
not a pi widget. Pi's `setWidget` offers `aboveEditor` and `belowEditor` only, so
the extension registers an empty widget to obtain the `tui` and `theme` handles and
then installs a `SidebarCompositor`. That class redefines `terminal.columns` to
shrink pi's own render width, wraps `tui.doRender`, and paints the right-hand column
itself with absolute cursor positioning.

That design is why the defect exists. `paint()` writes one row at a time:

```js
output += row <= lines.length ? truncate(lines[row - 1], this.width) : " ".repeat(this.width);
```

`truncate` returns a string shorter than the sidebar unchanged, so a short row never
erases the rest of its row. The previous frame stays visible to the right of it.
`renderSession` conditionally pushes a `tool` row on `tool_execution_start` and drops
it on `tool_execution_end`, so panel height changes constantly and every row below
the session panel shifts by one. A shifted header lands beside the old header and
reads as a duplicate. The observed tails, `Terra38.8%)` and `32/35ne` and `13k481`,
are the same bug at column granularity.

The diff review path consolidates on neovim. `modules/home/programs/git/default.nix`
already sets `diff.tool = "nvim"` and defines a `nvim` difftool calling `CodeDiff`,
which is `codediff.nvim` in the neovim configuration: a diffview-style changeset
view with its own file explorer. hunk supplied only `core.pager` and a review skill,
so removing it leaves the configured neovim path in place and unblocked.

The neovim configuration itself moves here. `modules/home/programs/neovim/sysinit-nvim.nix`
cloned `roshbhatia/sysinit.nvim` into `~/.config/nvim` on every switch. That clone
is 176 tracked files with no untracked work, and `programs.nh.flake` in
`modules/home/programs/nh.nix` already records where this repository is checked out
on this machine.

The annotation layer is new code, but not a new pattern.
`config/lua/harness/spec_watch.lua` already watches the filesystem for agent writes
with `vim.uv.new_fs_event`, deliberately, because that works for every harness with
no MCP and no cooperation from the CLI. `diffnote` is the same shape:
`runtime/agent-review.sh` is the closest existing CLI, and the note file is the
interface.

The package audit reads `piPackagePaths` in
`modules/home/programs/llm/harnesses/pi/default.nix` against the installed pi build
at `pkgs.pi-coding-agent`, and against what each package actually reads at runtime.

## Goals / Non-Goals

Goals:
- The sidebar reports state correctly, and says nothing when it has nothing to say.
- One surface owns each fact. The sidebar owns session state; the footer does not
  restate it.
- Diff review is one chord away, in neovim, and pi annotates the diff without being
  asked.
- Every loaded extension does something.
- One repository holds the harness configuration and the editor it opens.
- The annotation path is ours, so no third-party daemon sits between the agent and
  the review.

Non-Goals:
- Replacing the compositor. The API it works around still has no side placement.
- Choosing pi's MCP servers.
- Acting on the remaining extension overlaps, recorded under Risks below.
- Retiring the `sysinit.nvim` remote, or choosing a replacement git pager.
- Carrying annotation replies back from the owner to the agent.

## Decisions

- D1: Pad every painted row to the sidebar width, rather than erasing to end of
  line. `pad` measures with `visibleWidth`, so a styled row pads by visible columns
  and not by byte length. `reset()` gains SGR 49 so appended spaces cannot inherit a
  run's background.
  - Alternative rejected: emit `\x1b[K` after positioning each row. It erases to the
    real end of the line, which is correct only while the sidebar is flush right, and
    it erases with the current background rather than the terminal default. Padding
    is explicit and does not depend on either property.
- D2: Render one OpenSpec change, chosen by the `lastModified` field that
  `openspec list --json` already returns, and report the rest as a count.
  - Alternative rejected: render all changes and let the sidebar scroll. The
    compositor paints a fixed viewport with no scroll region, so more rows than the
    terminal has simply vanish, and this repository carries twelve changes. Rendering
    all of them also ran two `openspec` subprocesses per change every five seconds.
  - Alternative rejected: derive the mtime and the task counts ourselves, by stat-ing
    each change directory and reading each `tasks.md`. This was the first
    implementation, and it was wrong twice. A directory's mtime does not move when an
    existing artifact is rewritten in place, so a change edited all afternoon lost to
    one whose directory merely gained a file. Both substitutes also joined against the
    raw cwd, so running pi below the repository root made every stat throw, and the
    panel named an arbitrary change with no task counts and no error. The payload
    carries `lastModified`, `completedTasks`, and `totalTasks`; an earlier comment
    here asserted it did not, which is what made the wrong path look necessary.
- D3: Delete the MCP panel rather than repoint it at pi's native MCP config.
  - Alternative rejected: read pi's own `--mcp-config` path instead of the adapter's.
    Nothing in this repository writes any MCP config for pi, so the panel would be
    permanently empty, and a panel that can only be empty is not worth its code. The
    panel was reading a `mcp-cache.json` last written months earlier and rendering it
    as live, which is worse than absent.
- D4: Put the annotation instruction in the extension's message, not in
  `lib/instructions.nix`.
  - Alternative rejected: add a routing line to the shared conventions block. That
    file caps its rendered length and its own comment says a breach means a domain
    rule leaked in, to be moved to the owning skill. The prompt is also specific to
    one chord in one harness, which is not a cross-harness convention.
- D5: Open the split with the multiplexer's own CLI, and refuse when neither
  WezTerm nor tmux is present.
  - Alternative rejected: run the viewer in pi's terminal. Pi's TUI owns that
    terminal and the compositor already fights it for the column count. A second
    full-screen TUI in the same terminal has no way to coexist.
- D6: Use `nvim -c CodeDiff` for the neovim path.
  - Alternative rejected: `git difftool --tool=nvim`, which the repository already
    configures. It hands nvim one file pair per invocation, so a ten-file changeset
    is ten sequential nvim sessions. `:CodeDiff` opens the whole changeset with its
    own file explorer.
- D7: Narrow `tui.editor.cursorLeft` to `left` in `keybindings.json` instead of
  relying on `registerShortcut` precedence for `ctrl+b`.
  - Alternative rejected: bind `ctrl+b` and assume the extension wins. Pi's docs do
    not state precedence between a registered shortcut and a built-in editor
    binding, so the outcome would be undocumented behavior that a version bump could
    reverse silently. Removing the contest costs one line.
- D8b: Remove hunk rather than keep it for the pager alone.
  - Alternative rejected: keep hunk as `core.pager` and use neovim only for review.
    That leaves a flake input, an overlay entry, a home-manager module, and five
    agent allowlist entries alive to serve one setting, and it keeps two diff
    viewers whose keybindings and themes both have to be maintained. `git diff`
    without hunk falls back to the pager it used before hunk arrived.
- D9: `~/.config/nvim` is a symlink into the working tree, targeted by a dedicated
  `sysinit.neovim.configPath` option.
  - Alternative rejected: derive the target from `programs.nh.flake`, which is
    already the one definition of which flake defines the host. It is the wrong one:
    a consuming flake (sysinit.laurel) overrides it to its own checkout, which
    carries no module tree from this repository, so activation would fail on exactly
    the host that consumes this repository rather than being it. Measured on this
    machine, where the target resolved into the sysinit.laurel checkout.
  - Alternative rejected: `xdg.configFile` recursive from the store. lazy.nvim
    writes `lazy-lock.json` into the config root, which a store path cannot accept,
    so it would need the lockfile relocated to `stdpath("state")` where its drift
    stops being tracked. It also puts a `nh darwin switch` between the owner and
    every keymap edit, which is the opposite of the loop the clone gave them.
  - Alternative rejected: copy the directory into place on activation. Writes work,
    but a live edit is silently clobbered on the next switch, which is a worse
    failure than refusing.
- D10: Notes travel through a file the editor watches, not through an RPC socket.
  - Alternative rejected: have the CLI find nvim's socket under `stdpath("run")` and
    call `--remote-expr`. That is what a daemon-backed tool does, and it fails when
    no editor is running: the note is simply lost. Watching a file means `diffnote`
    works before, during, and after a review, and `spec_watch.lua` already
    established the pattern here.
- D13: A write publishes only content that parses, and a zero-byte store is
  repaired rather than trusted.
  - Alternative rejected: `cat > tmp; mv tmp store`, which is the ordinary atomic
    replace. It is not atomic in the sense that matters here: the producer is
    upstream in a pipeline, so `mv` commits before the failure is observable, and a
    zero-byte result then passed the `-f` existence test forever. Measured: one
    truncation made every later write report success and store nothing,
    permanently. A non-empty store that does not parse is refused instead of
    rebuilt, because those notes are the owner's.
- D14: The renderer owns attribution, at the head of the note, and there is no
  trailing signature line.
  - Alternative rejected: keep the trailing `— <author>` line. `rationale` is split
    into lines with the same prefix, so a note could render lines byte-identical to
    that signature. Demonstrated: a note that appeared to carry the owner's own
    approval of the diff they were reviewing. No prefix fixes this, because the body
    is arbitrary text; removing the forgeable position does.
- D15: Control bytes are stripped once on the way in, not at each renderer.
  - Alternative rejected: sanitize in the two renderers. There are two of them in
    two languages, and `diffnote list` is the one that reaches a terminal, where an
    escape sequence can clear the screen or hide the note's own text. Stripping at
    the single write path means neither renderer has to be trusted. `list` also
    re-sanitizes on output, because a store written by an older build is still
    untrusted input.
- D11: `diffnote` keeps hunk's `session comment` command surface.
  - Alternative rejected: design a fresh CLI surface. The harness skills already
    emit `{"comments":[{"filePath","newLine","summary"}]}`, so accepting that shape
    costs one jq expression and makes every existing prompt work unchanged. What is
    deliberately not copied is the daemon and the session concept.
- D12: `M.draw` is public on the Lua module.
  - Alternative rejected: keep it local and test through `refresh`. The window
    lookup needs `codediff.ui.lifecycle`, which needs the plugin, which a
    `runCommand` check cannot install. Exposing the render step is what lets the
    check assert extmark placement against a real buffer.
- D8: Remove the four inert packages rather than configure them.
  - Alternative rejected: give `pi-mcp-adapter` an `mcp.json` and select an
    Anthropic provider so `pi-claude-code-use` engages. Both are real options and
    neither is this change. An extension that is loaded and inert reads as a working
    capability, which is the defect being fixed.

## Rollout & Gating

Six phases, each independently verifiable, in this order.

1. Sidebar correctness. Gate: `nix flake check` exits 0 and the extension parses.
   Nothing outside the sidebar changes, so this phase can ship alone.
2. Footer retirement and package removal. Gate: `nix flake check` exits 0, the four
   pi checks build, and `nh darwin build` exits 0. This phase only deletes.
3. Diff review. Gate: `nh darwin build` exits 0, then the owner exercises the chord
   in a live pane.
4. hunk removal. Gate: `nix flake lock` records no hunk input and `nix flake check`
   exits 0. Nothing else depends on it, so this phase only deletes.
5. The neovim move. Gate: `nh darwin build` exits 0, then the owner moves the old
   clone aside and confirms nvim starts from the new path with its plugins intact.
   This is the one phase with a step outside this repository.
6. The annotation layer. Gate: `checks/diffnote-roundtrip.nix` exits 0 and survives
   mutation, then the owner sees a note render in a live CodeDiff view.

The default dotfiles gate sequence applies with no deviation: edit, then
`nix flake check`, then `nh darwin build`, then owner spot-check, then
`nh darwin switch`.

Kill switches, in order of blast radius:
- `/openspec-sidebar off` disposes the compositor and restores the real column
  count, with no rebuild.
- Removing `diff-review.ts` from `customExtensionFiles` drops both chords and leaves
  everything else in place.
- The old `~/.config/nvim` is moved aside, never deleted, so restoring the clone and
  reverting one module returns the previous arrangement.
- `diffnote clear --yes` empties the note store, and removing the three hooks from
  `config/lua/plugins/codediff.lua` stops all rendering without touching the CLI.
  Three, not two: `CodeDiffOpen`, `CodeDiffFileSelect`, and `CodeDiffClose`. Removing
  only two leaves `CodeDiffFileSelect` rendering.
- Those two switches are not symmetric, and the asymmetry is worth knowing. The
  renderer is a symlinked working-tree file, so an edit takes effect on the next
  nvim start. `ANNOTATE_PROMPT` is installed from the store, so silencing the WRITER
  needs `nh darwin switch`. Until then `ctrl+b` still spends tokens writing notes
  that nothing renders.
- Reverting the commit restores the four packages, the two vendored extensions, and
  the hunk input, because each is a pinned hash in a tracked file.

## Risks / Trade-offs

- Risk: `pad` fixes residue but not the compositor's other unhandled case, a
  terminal resize. `installCompositor` reads `MIN_COLUMNS` once, so shrinking the
  terminal below it does not tear the sidebar down. Mitigation: out of scope here and
  named as an open question, because the pre-existing behavior is unchanged by this
  work.
- Risk: rendering one OpenSpec change hides the other eleven. Mitigation: the header
  carries the count, so the sidebar never implies there is only one.
- Risk: auto-annotation spends tokens on every `ctrl+b`, including a glance. It is
  the owner's stated preference over a quieter default. Mitigation: `deliverAs:
  followUp` means it never interrupts a running turn, and `/review` is the same path
  when the chord is too easy to hit.
- Risk: `ctrl+b` is muscle memory for cursor-left in readline. Mitigation: stated to
  the owner before the work, and `left` is unchanged.
- Risk: the extension overlaps this audit did not act on. Three diff renderers
  (`pi-tool-display`, `@heyhuynhgiabuu/pi-diff`, hunk), three orchestrators
  (`pi-subagents`, `taskplane`, `pi-btw`), two context managers (`pi-vcc`,
  `pi-context`), and two research packages (`pi-librarian`, `pi-web-access`).
  Mitigation: recorded here so the next audit starts from this list. Note that
  `pi-tool-display` already yields `edit` and `write` rendering to `pi-diff` through
  its Nix-written `config.json`, so that pair is deliberate rather than accidental.
- Risk: `~/.pi/agent/` holds hand-written config Nix does not own, at
  `pi-permission-system/config.json` and `pi-rtk-optimizer/config.json`. Mitigation:
  a human-verification checkpoint in the rollout phase, because deleting an owner's
  file is not the same decision as removing a package.
- Risk: the symlink points into one checkout. On a host whose `programs.nh.flake`
  names a different checkout, nvim follows that one. Mitigation: that is the
  intended behavior, and activation fails loudly when the target does not exist
  rather than leaving a dangling `~/.config/nvim`.
- Risk: `lazy-lock.json` now lives in this repository, so a `:Lazy update` shows up
  as a dirty working tree here. Mitigation: accepted, and the point. Lock drift was
  previously invisible in a second repository.
- Risk: nothing prunes the store, and no subcommand enumerates stores, so a store
  for a deleted checkout is orphaned. Mitigation: partial. The renderer caps one row
  at three notes and collapses the rest to a count, so accumulation degrades the
  reading experience gracefully rather than pushing code off screen. Pruning policy
  and a reaper are named as a Non-goal.
- Risk: an in-repo symlink pointing outside the repository is accepted, because path
  resolution is deliberately lexical. Mitigation: accepted. Resolving symlinks would
  require the file to exist, and a note may name a file the agent has not created
  yet. The note is keyed and rendered by its repo-relative path either way, so the
  editor never renders outside the repository.
- Risk: the allowlist grants `printf *`, so an agent can truncate the note store by
  redirection without `diffnote clear`. Mitigation: out of scope. That is a property
  of granting `printf *` at all, not of this feature, and D13 means a truncated store
  is now repaired rather than absorbing. Recorded so the next allowlist review sees
  it.
- Risk: a note's line number goes stale as the agent keeps editing. Mitigation: the
  renderer clamps a line past the end of the buffer to the last line, so a stale
  note is visibly wrong rather than silently absent. The check asserts the clamp.
- Risk: no git pager after hunk. Mitigation: `git diff` returns to its default
  pager, which is what it used before hunk, and `diff.tool = "nvim"` still routes
  `git difftool` to CodeDiff.

## Migration Plan

1. Verify: `nix flake check` exits 0, including `diffnote-roundtrip`.
2. Verify: `nix build .#darwinConfigurations.lv426.system` exits 0, and the built
   `home-manager-files` carries `diff-review.ts` and none of the three removed
   extensions.
3. Move: the owner runs `mv ~/.config/nvim ~/.config/nvim.pre-inline`. Activation
   refuses while a real directory is there, so this precedes the switch and is the
   owner's action, not a script's.
4. Apply: `nh darwin switch` from the `sysinit.laurel` checkout, in a split pane.
5. Confirm: nvim starts from the symlinked path with its plugins loaded, the owner
   reads a live sidebar and judges that it says what they meant it to say, and the
   chord opens a CodeDiff split that shows a `diffnote` note.
6. Verify: `~/.pi/agent/settings.json` `packages` holds 23 paths and none of the
   four removed names.
7. Decide: the owner chooses whether the two hand-written extension configs move
   into Nix or are deleted, and when `~/.config/nvim.pre-inline` and the
   `sysinit.nvim` remote are retired. Nothing removes them without that decision.

Rollback: revert the commit, restore `~/.config/nvim` from `.pre-inline`, and run
`nh darwin switch` again. Every removal is a pinned hash or a tracked file, so
nothing has to be refetched by hand.

## Adversarial Review

The rubric is the proposal `Behavior` criteria, the decisions D1 through D8, the
gates in Rollout & Gating, and the proposal `Non-goals`.

The deterministic half is mandatory and runs on every phase: `specutil check`.

The critic half is default-on and owner-gated. The `adversarial-review` skill
elicits an approve or deny, runs independent critics that must break a phase with a
concrete failing scenario naming a violated rubric item, and repeats until the loop
reaches a terminal state. The skill scales the round cap and defines the terminal
states. A cap hit is reported as open objections and never as a pass. The owner may
waive the loop for a phase, recorded as `Adversarial review: waived by owner`.

- D16: The chord and the sidebar decide "changed" with the same question, and
  distinguish "not a repository" from "clean".
  - Alternative rejected: keep `git status --porcelain` in the chord. Porcelain counts
    an untracked file, and `:CodeDiff` shows tracked modifications, so one scratch file
    in an otherwise clean tree opened an empty diff and still spent a turn annotating
    it. Two surfaces added by one change answering the same question two ways is also
    how they drift.
- D17: A control byte in a note's PATH is rejected; in its TEXT it is stripped.
  - Alternative rejected: strip control bytes from the path too, as D15 does for text.
    The path is the key the editor matches against a buffer, so stripping keys the
    note on a file the caller did not name and it silently never renders. Rejecting is
    the only option that keeps `list` safe and the key faithful. Note that a newline
    needs its own detection: `grep '[[:cntrl:]]'` matches within a line and can never
    match a line separator, which is exactly the byte that forged a listing row.

## Open Questions

- Should the compositor tear itself down on a terminal resize below `MIN_COLUMNS`?
  Pre-existing, unchanged here, and worth its own change.
- Should pi reach the MCP catalog at all? Removing the adapter makes the current
  answer explicit rather than accidental.
- Do the remaining orchestration packages earn their place? Three extensions
  offering parallel work is the largest untouched overlap.
- Should a note carry an anchor stronger than a line number, so it survives the
  edits made after it was written? A content hash or a treesitter path would, at the
  cost of the simple payload every harness skill already emits.
- Should the sidebar show the open note count, now that one exists to show?
- Should a note carry an expiry, or be tied to the commit it was written against, so
  the store prunes itself instead of needing `diffnote clear`?
- Should `author` be set by the tool rather than passed in, so attribution is
  authentic rather than merely unambiguous? That needs a trustworthy identity for
  the writing harness, which nothing here has.
