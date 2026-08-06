## Why

Pi's sidebar painted every panel header twice and left character residue on short
rows, so the surface that reports session state could not be trusted to report it.
Around that defect sit three more: the footer restates what the sidebar already
shows, diff review has no path out of the TUI, and four loaded extensions do
nothing at all.

Two decisions arrived while that work was in flight, and both belong in the same
change because they touch the same files. Diff review consolidates on neovim, so
hunk goes and the annotated diff becomes ours to build. The neovim configuration
comes back into this repository, so one checkout holds the harness and the editor
it opens.

## What Changes

- Fix the sidebar compositor so each painted row clears its full width. The
  compositor writes at absolute cursor positions over the previous frame, and a row
  narrower than the sidebar never erased the rest of its row.
- Replace the sidebar `Workspace` panel with a `Changes` panel: the changed-file
  list and a total, with no branch name, ahead count, or untracked count.
- Render one OpenSpec change, the most recently modified, with a `+N more` count.
  The panel previously rendered every active change.
- Remove the sidebar `MCP Servers` panel. Its only data source is
  `pi-mcp-adapter`, which this change removes.
- Retire the pi footer customization. Drop the `openspec-status` extension this
  repository authored, and drop `status-line` and `model-status` from the vendored
  list. The sidebar already carries the turn count, the model, and the change.
- Add `diff-review.ts`: `ctrl+b`, or `/review`, opens the working-tree diff in a
  neovim CodeDiff split beside pi.
- Remove four extension packages that are loaded and inert: `pi-mcp-adapter`,
  `@benvargas/pi-claude-code-use`, `pi-dcp`, and `pi-interview`.
- Remove hunk. Drop the flake input, the overlay entry, `programs/hunk.nix`, the
  five agent allowlist entries, and the `pager.log` setting that existed only
  because hunk was `core.pager`. Diff review is neovim's job now, and
  `diff.tool = "nvim"` plus the `CodeDiff` difftool were already configured.
- Move the neovim configuration into this repository. The `sysinit.nvim` clone
  under `~/.config/nvim` becomes a symlink into
  `modules/home/programs/neovim/config`, so one repository holds both halves.
- Build the annotated diff here rather than depending on hunk for it. Add
  `diffnote`, a CLI whose command surface follows hunk's `session comment` API,
  and render its notes as virtual lines in the CodeDiff view.

### Non-goals

- Wiring pi to the MCP catalog in `modules/home/programs/llm/lib/mcp-catalog.nix`.
  Removing an adapter that reads a file nobody writes is not the same decision as
  choosing which servers pi should reach. That is its own change.
- Archiving or deleting the `sysinit.nvim` repository on GitHub. This change stops
  reading from it. Retiring it is the owner's call and needs no code.
- A replacement git pager. Removing hunk returns `core.pager` to git's default,
  which is what `git diff` used before hunk existed. Choosing a different one is a
  preference, not part of this cleanup.
- Two-way annotation. `diffnote` carries notes from the agent to the editor. A
  reply from the owner back to the agent needs a reader on the agent's side and is
  its own change.
- A pruning policy for the note store, or a reaper for the store of a deleted
  checkout. The renderer caps what one row shows so accumulation degrades gracefully,
  and `diffnote clear` is the manual answer. Deciding when a note expires on its own
  is a separate change.
- Authenticating the author field. The renderer makes the claim unambiguous; binding
  it to the writing harness needs an identity none of them has today.
- Any key in pi's `settings.json` other than `packages`. The
  `modernize-opencode-and-pi-config` change owns that file's key manifest and is
  mid-flight.
- The remaining extension overlaps this audit found and did not act on: three diff
  renderers, three orchestrators, and two research packages. They are recorded in
  `design.md` so the next audit starts from a list rather than a re-derivation.
- Any change to `lib/instructions.nix`. The shared context has a line cap whose own
  comment says a domain rule belongs in the owning skill.
- Replacing the compositor with a supported API. Pi offers `aboveEditor` and
  `belowEditor` widgets and no side placement, so the column override stays.

## Behavior

- No sidebar row shows text from the previous frame. Painting a frame whose panels
  are shorter than the last frame's leaves no residue, which is decidable by
  driving two frames of differing height and comparing the second against its
  expected rows.
- Every painted row is exactly the sidebar width in visible columns.
- The `Changes` panel names no branch. A detached HEAD still renders the panel,
  because the repository test is `git rev-parse --git-dir` and not a current branch.
- The OpenSpec panel renders exactly one change plus a count of the rest, and the
  change it names is the one `openspec list --json` reports as most recently
  modified. That field is read from the payload, not re-derived: a directory's mtime
  does not move when an existing artifact is rewritten in place, and re-deriving it
  from the cwd broke whenever pi ran below the repository root.
- One `openspec status` subprocess runs per refresh, not one per active change, and
  no `stat` or `tasks.md` read happens at all: the task counts come from the same
  payload.
- The panel names the right change, and shows task counts, from any directory inside
  the repository, not only from its root.
- A panel with nothing to say renders zero rows. An empty subagent list, an absent
  git repository, and an unavailable `openspec` each produce no header.
- Pi's footer carries at most the `preset` extension's status. No extension writes
  the model, the turn count, or the change name there.
- `ctrl+b` in a WezTerm or tmux pane opens a split running the neovim CodeDiff view
  against the session's repository. `/review` does the same.
- With no WezTerm and no tmux, the chord opens nothing. It reports the command to
  run instead, because pi's own terminal belongs to its TUI.
- The chord and the sidebar answer "what changed" the same way: tracked
  modifications against HEAD, or staged content when HEAD is unborn. An untracked
  file alone is not a change, so the chord does not open an empty diff and then spend
  a turn annotating it.
- Outside a repository the chord says so, rather than reporting a clean working tree,
  which would assert something untrue.
- Control bytes are rejected in a note's path and stripped from its text. A path
  cannot be sanitized in place, because it must match a buffer verbatim, so a path
  carrying one is refused. This closes `diffnote list` as an injection sink: an
  escape sequence there could clear the terminal, and a carriage return could forge a
  whole listing row.
- One malformed note cannot suppress a valid one. A row renders as a single extmark,
  so every field the renderer reads is validated before it is used.
- One row's rendering is bounded in lines as well as in notes, so a single long
  rationale cannot push the code off screen either.
- The visible notes on a row are the first ones written, in the order written. The
  cap selects, so the ordering is load-bearing rather than incidental.
- `add` and `apply` accept and reject the same inputs. Neither stores a note the
  other would refuse.
- After the split opens, pi leaves notes on the diff without being asked.
- `left` still moves the cursor in pi's editor after `ctrl+b` is bound.
- No Nix file declares, imports, or invokes hunk; `flake.lock` records no hunk
  input; the overlay entry and the five allowlist entries are gone; and nothing in
  this repository or in the skills tree invokes the `hunk` CLI. The STRING still
  appears in comments, because D11 deliberately keeps hunk's payload shape, so the
  criterion is absence of a declaration or an invocation, not absence of the word.
- `~/.config/nvim` resolves to `sysinit.neovim.configPath`, which defaults to
  `modules/home/programs/neovim/config` inside the conventional checkout of this
  repository and is not derived from which flake defines the host. Editing a file
  there changes the next nvim start with no switch, and `lazy-lock.json` is a
  tracked file in this repository.
- Activation fails loudly when that path does not exist, rather than leaving a
  dangling `~/.config/nvim`.
- Activation refuses, rather than deletes, when `~/.config/nvim` is a real
  directory. The old clone may hold commits that never reached a remote.
- `diffnote` derives the same note-file path as the editor does. Both compute it
  from the sha256 of the repository root, and a check asserts the two agree.
- `diffnote apply --stdin` accepts hunk's payload shape (`filePath`, `newLine`) and
  this tool's own (`file`, `line`).
- A batch with any invalid item leaves the store byte-identical. Validation
  precedes the write, so half a batch never lands.
- A path outside the repository is rejected, and a path given relative to a
  subdirectory resolves against the repository root.
- The editor draws one extmark per anchored row in the modified window, keyed by
  repo-relative path, and a note whose line is past the end of the buffer clamps to
  the last line rather than disappearing.
- One row renders at most three notes and collapses the rest to a count. Nothing
  prunes the store, so repeated reviews of the same hunk would otherwise stack until
  the code under them is off screen.
- Closing the view clears the notes from every buffer the renderer drew into, not
  only the one that happens to be current.
- A note's line must be an integer of one or more, in both halves, and an
  `oldLine`-only comment is refused rather than anchored on the modified side where
  its number names unrelated code.
- Control bytes never reach either renderer. A summary carrying an escape sequence
  cannot clear the terminal from `diffnote list` or hide its own text with a
  carriage return.
- Attribution is rendered by the editor, at the head of the note, and no note body
  can produce a line that reads as a signature. The author string is self-declared
  by whatever wrote the note; this makes the claim unambiguous, not authentic.
- A failed write publishes nothing. The store is replaced only by content that
  parses, and a zero-byte store is repaired rather than treated as valid, so a write
  can never report success and store nothing.
- A corrupt non-empty store is refused, not overwritten. The notes in it are the
  owner's.
- Two writers cannot interleave. Each mutation takes a lock beside the store.
- A relative `--file` resolves against the physical working directory, so a
  repository reached through a symlinked path behaves like any other. On macOS
  `/tmp` is such a path.
- The two halves derive the same note path with `XDG_STATE_HOME` set, unset, and
  carrying a trailing slash.
- A note written while the CodeDiff view is open appears without a reload, because
  the editor watches the note file.
- `diffnote` works with no editor running. It is a writer, not a client.
- The reading forms of `diffnote` sit in the allowlist's read-only tier and the
  writing forms in its reversible-write tier, matching that file's own definitions.
  Note that pi reads neither: its gate is `@gotgenes/pi-permission-system`.
- Pi's `packages` list holds 23 store paths, and none matches `mcp-adapter`,
  `claude-code-use`, `pi-dcp`, or `pi-interview`.
- `nix flake check` exits 0, and the four pi checks build.

## Impact

Affected code:
- Modified: `modules/home/programs/llm/harnesses/pi/extensions/openspec-sidebar/index.ts`.
- New: `modules/home/programs/llm/harnesses/pi/extensions/diff-review.ts`.
- Deleted: `modules/home/programs/llm/harnesses/pi/extensions/openspec-status.ts`.
- Modified: `modules/home/programs/llm/harnesses/pi/vendored-extensions.nix`, two
  entries removed.
- Modified: `modules/home/programs/llm/harnesses/pi/default.nix`: the install
  entry, four package definitions, the load-order list, and `keybindings.json`.
- Deleted: three lock files under `modules/home/programs/llm/harnesses/pi/locks/`.
- Deleted: `modules/home/programs/hunk.nix`. Modified: `flake.nix`, `flake.lock`,
  `overlays/inputs.nix`, `modules/home/programs/default.nix`,
  `modules/home/programs/git/default.nix`, and
  `modules/home/programs/llm/lib/allowlist.nix`.
- New: `modules/home/programs/neovim/config/`, all 176 non-installer files carried
  over from the `sysinit.nvim` checkout. Three of them (`.luarc.json`,
  `.neoconf.json`, `.gitattributes`) needed `git add -f`: this repository's own
  ignore rules and the machine's global ignore file both matched them, so they landed
  on disk and stayed untracked, which a spot-check on this machine could not see. Rewritten: `modules/home/programs/neovim/sysinit-nvim.nix`,
  from a clone to a symlink.
- New: `modules/home/programs/llm/runtime/diffnote.sh`, built and installed through
  `runtime/default.nix` and `llm/default.nix`.
- New: `modules/home/programs/neovim/config/lua/harness/diffnote.lua`. Modified:
  `config/lua/plugins/codediff.lua`, three lifecycle hooks.
- New: `checks/diffnote-roundtrip.nix`, registered in `checks/default.nix`.
- Modified: `modules/home/programs/llm/lib/allowlist.nix`, reading forms in tierA and
  writing forms in tierB.
- New: `modules/home/programs/neovim/options.nix`, the `sysinit.neovim.configPath`
  option.

Reuse:
- The sidebar's own `truncate` and `visibleWidth` helpers already measure a styled
  string. The fix adds `pad` beside them rather than a second width notion.
- `summaryHeader` generalizes the existing `panelHeader`, so the `Changes` and
  OpenSpec headers share one layout.
- The neovim path calls `:CodeDiff`, from `codediff.nvim` in sysinit.nvim. That
  view already exists and is bound to a key there.

- `diff-review.ts` follows the extension shape the sidebar already uses:
  `registerCommand`, `pi.exec`, and a cast to a local runtime-context interface.
- The symlink target is its own option rather than a reuse of `programs.nh.flake`.
  Reusing that option was the first attempt and it was rejected; D9 records why.
- `diffnote` follows `runtime/agent-review.sh`: a `writeShellApplication` with
  explicit `runtimeInputs`, its body in a separate `.sh` file, exit code meaningful.
- `lua/harness/diffnote.lua` follows `lua/harness/spec_watch.lua`, which already
  watches the filesystem for agent writes with `vim.uv.new_fs_event`. That is why
  the CLI needs no RPC socket.
- `checks/diffnote-roundtrip.nix` follows `checks/agent-sessions-rollup.nix`:
  fixture-driven, asserting behavior by content rather than by exit code.
- The annotation command surface is hunk's `session comment` surface, kept
  deliberately so the harness skills that already emit that payload still work.

Progressive rollout: the change lands in three independently verifiable phases.
The sidebar fix stands alone. The footer retirement and the package removals are
config-only. The new extension adds a surface and removes none.

Impactful and irreversible actions:
- `nh darwin switch` replaces pi's installed extension set and rewrites
  `settings.json`. Removing four packages from `packages` is what makes their
  absence real.
- Moving `~/.config/nvim` aside. Activation refuses while a real directory is
  there, so the owner performs that move, and it is the one step that touches a
  checkout this repository does not own.
- Removing the hunk flake input changes `flake.lock`. Reversible, and no other
  input depended on it.
- Deleting three lock files, one module, and one extension is a tracked git change,
  so it is reversible.
- No network write, no vendored-content update, and no schema change.

Gating signal:
- `nix flake check`, then `nh darwin build`, then the owner reads the sidebar in a
  live pi session, then `nh darwin switch`. The kill switch for the sidebar is
  `/openspec-sidebar off`, which it already carries, and which disposes the
  compositor and restores the terminal's own column count. The kill switch for the
  neovim move is the old clone: it is moved aside, not deleted, so restoring it and
  reverting one module returns the previous arrangement.
