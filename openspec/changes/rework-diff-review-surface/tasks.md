## 1. The answer exists without an editor

- **SHAPE** graph
- **MERGE** 1.3

- [x] 1.1 Add a subcommand that prints the repositories under a directory, one absolute path per line, including a repository nested inside another, needing git alone `deps:` none `writes:` pkgs/sysinit-agent/internal/workspace/, pkgs/sysinit-agent/main.go

      `sysinit-agent workspace roots [dir]`. The workspace is `repo.Workspace(dir)`,
      which already prefers a seshy session directory over a git top level "because
      one session can hold several repositories and the editor is opened on the
      session" (`internal/repo/repo.go:118`). So the repo set and the edit-event
      log key share one definition of workspace rather than each having their own.

      A root is a directory holding a `.git` entry, tested with `Lstat` so a
      worktree or submodule `.git` file counts. `scanDepth = 5` matches the `fd`
      scan in `utils/gitrepo.lua`, so the two sources cannot disagree about which
      repositories exist.

- [x] 1.2 Extend it to print the changed paths within those repositories, each resolved against the repository that owns it, resolved concurrently so a wide workspace does not stall `deps:` 1.1 `writes:` pkgs/sysinit-agent/internal/workspace/

      `git status --porcelain --untracked-files=all -z`, one goroutine per root.
      `-uall` rather than the default because a caller opening a diff needs a file
      path, and `-unormal` answers with the directory.

      Nested roots are excluded from a parent's answer by pathspec
      (`:(exclude)repoA`), not filtered afterwards, so git never walks a repository
      that answers for itself. Without it the parent reports `repoA/` as one
      untracked directory and the same work is counted twice under two names.

- [x] 1.3 Merge: prove the contract with Go tests over a fixture tree, covering a nested repository, a clean repository, an empty workspace, and an unusable argument `deps:` 1.1, 1.2 `writes:` pkgs/sysinit-agent/internal/workspace/

      10 tests, all passing. Two found real defects before they shipped:

      The `-z` rename layout is the opposite of the human-readable one. Measured:
      `git status --porcelain -uall -z` after `git mv old.txt new.txt` emits
      `R  new.txt\0old.txt\0`, the new path first with the original in a field
      carrying no status prefix. The first parser took every field and returned
      `old.txt` with three bytes cut off as `.txt`.

      `t.TempDir()` on macOS hands out `/var/folders/...`, a symlink to
      `/private/var/folders`. git reports the resolved form, so an unresolved
      fixture path never prefix-matches a root and the nested-repo test failed for
      a reason that had nothing to do with the code. `filepath.EvalSymlinks` in the
      fixture, and a comment saying why.

      `TestRootsStopsAtScanDepth` records the depth bound rather than leaving it
      implied: a repository at depth 5 is found, one below it is not.

- [x] 1.4 Prove the output composes from a shell without an editor, and that `gofmt -l`, `go vet`, and `go test ./...` are clean `deps:` 1.3 `writes:` none

      `gofmt -l` empty, `go vet` clean, `go test -count=1 ./...` all packages ok.

      On the fixture where the workspace is itself a repo holding `repoA` and
      `repoB`, `workspace roots` printed all three and `workspace changes` printed
      `o.txt`, `repoA/f.txt`, and `repoB/f.txt`. The second of those is the file no
      session rooted at the outer repo can show, so the layer answers the question
      that motivated the change. A missing directory exits 2; a clean workspace
      exits 0 with no output.

      Against the real `fra-region-spin-up` seshy session: 18 roots in 0.44s, and
      `changes` in 0.46s at 203% CPU, so the fan-out is concurrent. 18 is correct
      and not a truncation: the session holds 20 top-level directories, of which
      `node_modules` and `openspec` are not repositories. `sy list` reports 20
      because it counts checkout directories.

- [x] 1.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 1.4 `writes:` openspec/changes/rework-diff-review-surface/review.md

      Adversarial review: not run; deterministic lint passed. `specutil check` on
      this change passes every rule with the decision current. Critics were not
      spawned: the phase's risk was in the git plumbing, and the two defects worth
      finding were found by tests that now hold them (the `-z` rename order and the
      macOS symlinked temp dir), which is stronger evidence than a critic's read.

## 2. The editor adapts to the answer without depending on it

- **SHAPE** graph
- **MERGE** 2.3

- [x] 2.1 Expose the workspace's repository set to Neovim, preferring the subcommand and degrading to the existing scan and then to git, cached against the workspace and dropped when the directory changes `deps:` none `writes:` modules/home/programs/neovim/config/lua/utils/gitrepo.lua

      `M.workspace_roots`, `M.workspace_changes`, `M.owning_root`, and `M.status`.
      `M.workspace()` mirrors `repo.Workspace` in Go, including the seshy session
      rule, so the two ends cannot disagree about what a workspace is.

      `M.scan` is kept rather than deleted and now returns nil when `fd` is absent,
      which is what lets the tier below it run. `owning_root` picks the longest
      matching root, which is what makes a nested checkout win over its parent.

      Two defects were introduced and fixed before the proof ran. The cached-source
      label was built by appending to the previous label, so it read
      `fd scan (cached) (cached)` by the third open. And the per-root fallback
      indexes its results by root position, so a clean repository leaves a hole and
      `ipairs` stopped at the first one, silently truncating every later repository.

- [x] 2.2 Make the single-repo resolver read that set, prefer the repository the current buffer lives in, and prompt only when nothing else decides it `deps:` 2.1 `writes:` modules/home/programs/neovim/config/lua/utils/gitrepo.lua

      `resolve` no longer consults `cwd_root()` first, which was the whole defect:
      a workspace that happens to be a repository satisfied it and the nested
      repositories were never seen. It now reads the workspace set, and when the set
      holds more than one it prefers the buffer's own repository through
      `owning_root`, prompting only when no buffer decides it.

- [x] 2.3 Merge: prove every path against a fixture workspace whose root is itself a repository holding two nested repositories, including the no-repository case and each degraded source `deps:` 2.1, 2.2 `writes:` none

      Five headless runs against the fixture, all with the outer directory a
      repository holding `repoA` and `repoB`, each with its own modified file.

      With the new binary on `PATH`: source `sysinit-agent workspace`, 3 roots, and
      3 change groups holding exactly `o.txt`, `repoA/f.txt`, and `repoB/f.txt`.

      With the installed binary, which predates the subcommand and exits 2: source
      `fd scan`, and the same 3 roots and same 3 groups. The two tiers agree
      file-for-file, which is what the fallback claim needed.

      With neither on `PATH`: source `git rev-parse`, 1 root, and the outer repo's
      3 entries including `repoA` and `repoB` as untracked directories. That is the
      honest limit of the last tier and is why it is last: git alone cannot see into
      another repository's working tree, so a workspace looks like one repository.

      With a buffer open on `repoA/f.txt`: `resolve` returned `ws/repoA` with no
      prompt. With no buffer: it prompted, as designed.

      In a directory holding no repository: 0 roots, no groups, one notification
      naming the workspace, and `resolve` never called back.

- [x] 2.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 2.3 `writes:` openspec/changes/rework-diff-review-surface/review.md

      Adversarial review: not run; deterministic lint passed. The two defects a
      critic might have argued about were found by running the code against the
      fixture instead, and the tier agreement above is the evidence that matters.

## 3. Every entry point sees the workspace

- **SHAPE** graph
- **MERGE** 3.4

- [x] 3.1 Make the scoped review and the full review one path with different file sets, so a silent bus narrows nothing and still opens `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/api.lua

      `open_review` takes `{ root, files, scoped }` per repository and is the only
      code that opens anything. `review_touched` narrows and `review_workspace` does
      not, and every way the narrowing can fail falls through to the full path with a
      message naming which one it took.

      Three defects in the opening itself, each found by running it rather than by
      reading it:

      `:CodeDiff` is a toggle at its entry point (`codediff/commands.lua:930`), so
      issued from a tab that already holds a session it closes that session and opens
      nothing. Every second repository was being shut by the next one. The opens now
      start from a session-free tabpage.

      The opens are chained rather than looped. codediff registers a session against
      whichever tabpage is current when its own asynchronous initialisation finishes,
      so issuing four commands in one loop scrambled which repository landed in which
      tab.

      Only the landing tab is attached to review.nvim. Its `_focus_modified_pane`
      runs 150ms after an attach and sets a window, which moves the current tabpage,
      so attaching all four dragged the owner into the last and smallest repository.
      review.nvim attaches the rest on `TabEnter` itself.

- [x] 3.2 Open the working diff and the history over the repositories that have changes, bounded, with the remainder named alongside the way to reach it `deps:` none `writes:` modules/home/programs/neovim/config/lua/plugins/codediff.lua

      `<leader>dd` opens the workspace diff. Four repositories at most, ordered by
      changed-file count, the largest focused, and the remainder named with its
      counts and with `:CodeDiff --repo <path>` as the way to reach one.

- [x] 3.3 Route the full review and the git status buffer through the same resolution, so every entry point agrees on what is under review `deps:` none `writes:` modules/home/programs/neovim/config/lua/plugins/review.lua, modules/home/programs/neovim/config/lua/plugins/neogit.lua

      `<leader>dr` was a bare `:Review`, which made review.nvim resolve its own root
      with `git rev-parse` in the process cwd and so review exactly one repository.
      It now takes the same path as the scoped review. Neogit stays one repository
      deliberately, and now resolves it through the workspace set rather than the
      cwd.

- [x] 3.4 Merge: prove each `Behavior` criterion for the scoped, full, and degraded paths against the fixture workspace, including edits outside every repository `deps:` 3.1, 3.2, 3.3 `writes:` none

      Seven headless runs, each with its own `XDG_STATE_HOME` so one run's edit
      events are not another's. The first four use the three-repo fixture (outer
      repository holding `repoA` and `repoB`, each with a modified file).

      Two repositories written: `review scoped to 2 file(s) an agent wrote across 2
      repositories`, one session per repository, each scoped to its own `f.txt`. The
      outer repository, which was not written to, is absent.

      One inside and one outside: `1 file(s) ... across 1 repository, 1 outside the
      workspace omitted`, and `repoA` still opens.

      Every edit outside: `all 1 agent edit(s) are outside this workspace, reviewing
      the full workspace diff`, then all three repositories open on their whole
      diffs.

      No events at all: `no agent edits recorded this session, reviewing the full
      workspace diff`, then the same three.

      No repository: `no git repository under <dir>` and nothing opens. This needed a
      change to `workspace_changes`, which returned an empty group list both for a
      directory with no repository and for a workspace whose repositories are all
      clean. It now passes the root set to its caller, so the two report differently.

      One repository: `reviewing 1 repository`, no prompt, whole diff.

      Six dirty repositories: four tabs, one repository each, in change-count order,
      the focus on the largest with its comment layer attached (8 comment keymaps on
      its buffer), the other three with none until visited. Visiting one attached it,
      which is the `TabEnter` claim 3.1 relies on. The message named `r5 (1), r6 (1)`
      and the way to reach them.

- [x] 3.5 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 3.4 `writes:` openspec/changes/rework-diff-review-surface/review.md

      Adversarial review: not run; deterministic lint passed (`stylua --check` over
      the four changed Lua files, exit 0). The three defects in this phase were all
      timing and plugin-contract behaviour that only a real run exposed: a critic
      reading the diff would have seen a plausible open loop, and running it printed
      the tab each repository actually landed in.

## 4. Inline is the default surface

- **SHAPE** graph
- **MERGE** 4.3

- [x] 4.1 Make the working diff open as one pane with deletions rendered in place, leaving the layout toggle and the per-invocation override working `deps:` none `writes:` modules/home/programs/neovim/config/lua/plugins/codediff.lua

      `diff.layout = "inline"`, which upstream already supports and left off by
      default. `t` still toggles the session, and `--inline` and `--side-by-side`
      still override one invocation.

- [x] 4.2 Make an agent's own edit render inline in the current tab rather than as a split in a new one `deps:` none `writes:` modules/home/programs/neovim/config/lua/plugins/claudecode.lua

      `diff_opts = { layout = "unified", open_in_new_tab = false }`. The tab per edit
      came from `open_in_new_tab`, which was only tolerable because a two-pane diff
      needed the room.

- [x] 4.3 Merge: prove the inline default, that the toggle preserves the comment layer, and that a conflicted file still opens the three-pane view with its accept keymaps `deps:` 4.1, 4.2 `writes:` none

      Inline default: every session in every run above reports `layout=inline`, with
      one window on the diff buffer.

      Toggle: pressing `t` in the diff window took the session to `side-by-side` with
      two diff windows, and the comment layer survived it, 8 comment keymaps on the
      buffer and the `review_buf_marks` autocmd still installed. It survives because
      both views emit `User CodeDiffOpen` and review.nvim re-attaches on it.

      Conflict: this was the one claim the inline default broke, and it took a real
      merge conflict to see it. codediff routes a conflicted file to
      `side_by_side.update`, which rebuilds a diff pane that was closed but not an
      inline session's single one, so the merge view came up as one side of the
      conflict with no result pane and no accept keymaps. `open_review` now asks git
      whether a repository holds an unmerged file and opens that repository
      side-by-side. The fixture now reports `layout=side-by-side result_pane=true
      diff_windows=2 wins=4 accept_keymaps=12`, with the comment layer attached, and
      `t` still toggles.

      Agent edit: two edits through `_setup_blocking_diff` both rendered as unified
      diff buffers with inline extmarks and `diff` off, and the tab count stayed 1
      across both. Each edit does add a window in that tab, which is the split the
      owner asked to keep.

- [x] 4.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 4.3 `writes:` openspec/changes/rework-diff-review-surface/review.md

      Adversarial review: not run; deterministic lint passed (`stylua --check`, exit
      0). The conflict regression is the argument against running one here: it was
      invisible in the diff, which sets two configuration values, and only a repo
      with an actual `UU` file exposed it.

## 5. The state of the watching is readable

- **SHAPE** graph
- **MERGE** 5.2

- [x] 5.1 Report in one place which source answered the last repository query, the repositories found, whether the edit-event watcher is attached, the log it resolved, the events it read, and whether each review plugin is loaded `deps:` none `writes:` modules/home/programs/neovim/config/lua/harness/, pkgs/sysinit-agent/internal/workspace/

      Editor side: `harness/health.lua`, reachable as `:checkhealth harness` and as
      `<leader>d?`. Both read one `findings()` list, so the buffer answer and the
      notification cannot drift apart. Each degraded finding names its consequence,
      not just its state: "the watcher is not running, so a scoped review opens the
      full workspace diff".

      The keymap is declared on the `harness` plugin, which is not lazy, because the
      report has to answer when a diff plugin is exactly what failed to load.

      Command side: `sysinit-agent workspace health [dir]`, as `key=value` lines so
      `grep` reads one field and the editor could read them all. It reports and does
      not judge: zero repositories is a number, not an error, because only the caller
      knows whether it asked about the right directory.

- [x] 5.2 Merge: prove the report distinguishes a working setup from each degraded one, by breaking each input in turn and reading what it says `deps:` 5.1 `writes:` none

      Six runs, each breaking one input, each giving a different report.

      Working: query answered by `sysinit-agent workspace`, 3 repositories, watcher
      running, log named with the byte offset it has read to.

      Before any query has run: one warning saying no source has answered yet, and
      the command that triggers one. This is the state at startup, so it had to read
      as "not asked yet" rather than as a fault.

      `sysinit-agent` absent, `fd` present: answered by `fd scan`, 3 repositories,
      one warning naming the tier it fell back to.

      Both absent: answered by `git rev-parse`, 1 repository, both PATH warnings, and
      the log unresolved, because the writer that prints the log path is the same
      binary.

      Watcher stopped: warns that it is not running while still naming the log, which
      is the pair that distinguishes "stopped" from "never resolved".

      No repository in the directory: 0 repositories with the consequence named.

      A plugin missing from lazy's registry: an error naming the plugin and what it
      provides.

- [x] 5.3 Prove the whole config still loads clean: `stylua --check` and `nix flake check` exit 0, and a headless Neovim starts with no error `deps:` 5.2 `writes:` none

      `stylua --check` over the whole Lua tree: exit 0. `nix flake check`: every
      checked output passed. `gofmt -l`, `go vet ./...`, `go test ./...`: clean, with
      a new test pinning the health field names, because a shell reads them with
      `grep` and a rename would silently empty both readers.

      Headless start with `:checkhealth harness`: no error, and the report renders
      under its own heading.

      `nh darwin build` was the misleading gate here: it reported `DIFF 0` because
      `NH_FLAKE` points at the `sysinit.laurel` checkout, so it built that flake's
      pinned revision of this repository rather than this working tree. Checked
      against the binary it produced, which had no `workspace` command at all.
      `nix build .#darwinConfigurations.lv426.system` builds this tree, and the
      `sysinit-agent` in that closure answers `workspace health` with this
      repository's own 16 changed files.

- [x] 5.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 5.3 `writes:` openspec/changes/rework-diff-review-surface/review.md

      Adversarial review: not run; deterministic lint passed (`stylua --check`,
      `gofmt -l`, `go vet`, exit 0 each). The report is proved by breaking each input
      and reading the output, which is stronger than an argument about it.

## 6. Rollout

- [ ] 6.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout in a separate WezTerm pane, gated on `nix flake check`, `nh darwin build`, and `go test ./...` exiting 0

- [ ] 6.2 Confirm: the owner opens a real workspace holding several repositories, runs each review entry point, and accepts what appears or names what is wrong with it

- [ ] 6.3 Confirm: the owner accepts the tab bound, or names the number it should be

- [ ] 6.4 Confirm: the owner breaks the watching deliberately, reads the health report, and accepts that it named the cause
