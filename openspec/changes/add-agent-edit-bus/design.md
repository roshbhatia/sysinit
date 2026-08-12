## Context

Three mechanisms this change extends already exist, and none of them is
harness-specific.

`pkgs/sysinit-agent/` is the Go binary behind every hook command. `main.go`
dispatches eight subcommands, including `agent-state` (`internal/agentstate`) and
`note` (`internal/note`). Each has a `_test.go` beside it.
`internal/agentstate/agentstate.go:338` holds `identify(dir)`, which resolves a
directory to a session and a repo by checking the seshy sessions root, then the
zmx session, then git. `internal/repo/repo.go:68` holds `noteBase(root)`, which
keys a per-directory state file as `<basename>-<sha256(root)[:16]>` under a path
from the manifest.

`modules/shared/options/paths.nix` reads `paths-layout.json`, substitutes
`$HOME`, and installs the result as a JSON manifest at a fixed home-relative
path. A runtime consumer reads that one file to learn every other path, which is
why a new state path costs one line and no coupling.

`modules/home/programs/llm/harnesses/registry.nix` records per-harness
capability. `notify = "hook"` on six entries (atomic, claude, codex, opencode,
pi, prime-agent) means the harness has a hook surface that calls `agent-state`;
`notify = "scrape"` on the other eight means it has none. claude and codex reach
it through declared hook entries, the other four through a `sysinit-notify.ts`
bridge of 50 to 71 lines.

On the editor side, `harness/api.lua:158-178` already sends review annotations to
whichever adapter is active, and `plugins/review.lua` declares `review.nvim`
(`8e4bc16c`) and `codediff.nvim` (`31510a9b`) to produce them.
`harness/file_refresh.lua` is the only thing that tells Neovim a file changed, and
it does so by running `silent! checktime` every 1000 ms.

No new pattern is introduced. The writer is a ninth `sysinit-agent` subcommand
alongside the eight that exist, and the reader is one more module under
`harness/` beside the fifteen that are there.

## Goals / Non-Goals

Goals:

- One append-only event log, at a path declared in `paths-layout.json`, that any
  hook-capable harness writes and Neovim optionally reads.
- Neither end names the other. The harness writes whether or not an editor
  exists; Neovim reads whether or not a harness is running.
- A buffer Neovim has open reloads on the event, not on the next poll tick.
- The set of files an agent touched this session becomes known to Neovim, so a
  review can be scoped to it.

Non-Goals, beyond those in `proposal.md`:

- No change to `harness.api.send_review`, the selection sends, or `adapter.send`.
  The editor-to-agent direction is finished work.
- No removal of `file_refresh.lua`. Eight harnesses still need it.
- No ordering guarantee across harnesses. Two agents editing the same file
  concurrently is out of scope; the log records both events and the last reload
  wins, which is what a poll does today.

## Decisions

### The writer is a `sysinit-agent` subcommand, not a shell script

`sysinit-agent edit-event --harness <name> --file <path> --kind <kind>`, with the
harness label and file path passed as arguments and the harness's JSON hook
payload accepted on stdin where the surface provides one, mirroring how
`agent-state` reads stdin at `agentstate.go:124`.

The three hard parts are all easier in Go and all testable: encoding a JSON line,
appending it atomically under concurrent writers, and enforcing the size bound.
Every existing subcommand has a `_test.go`, so a new one inherits a test harness
rather than needing one.

- Alternative rejected: a shell script under
  `modules/home/programs/llm/runtime/`, beside `agent-notify.sh`. Two harnesses
  can write in the same millisecond, and a `printf >>` from a shell offers no
  single-`write(2)` guarantee for a line built by command substitution, so
  interleaved half-lines are possible. There is also no test runner for the
  runtime shell scripts, and the negative scenarios in `proposal.md` require
  tested failure behavior.

### One log per workspace, keyed by the existing identity resolution

The log path SHALL be derived the way `repo.noteBase` derives a diff-note path:
`<basename>-<sha256(root)[:16]>.jsonl` under a new `agentEdits` entry in
`paths-layout.json`. The root SHALL come from the same resolution
`agentstate.identify` performs, so a seshy session directory keys one log even
when it contains several git repositories.

- Alternative rejected: one global log for all workspaces. Every Neovim would
  read and filter every other workspace's events, and the size bound would be
  shared, so a busy repo could evict a quiet one's events.
- Alternative rejected: keying on the git toplevel, as `repo.Root()` does. The
  live claude lock file on this machine records `workspaceFolders` as
  `/Users/roshan/.local/state/seshy/sessions/poc-eks-controlplane-azure-compute`,
  a seshy session directory. Keying on git root would split one session's events
  across several logs while Neovim watched the session directory and saw none of
  them.

### The bound is size-triggered truncation to the last K lines

The writer SHALL check the log's size before appending and, past the bound,
rewrite it containing only its last K lines. This makes eviction the same event
the reader must already survive, rather than a second mechanism.

- Alternative rejected: unbounded growth with cleanup at SessionEnd. claude has a
  SessionEnd hook, but a harness killed with SIGKILL never fires one, and four of
  the six harnesses reach the bus through a plugin whose teardown event is not yet
  established. An unbounded log with a cleanup that may not run fails the
  "no editor is running" negative scenario in `proposal.md`.
- Alternative rejected: a fixed line cap enforced by the reader. The reader is
  optional by design, so a bound only it enforces does not exist when no Neovim
  is running.

### The reader watches the directory and tracks a byte offset

Neovim SHALL start one `vim.uv.fs_event` on the log's parent directory, record
the log's size at startup as its initial offset, and on each event read from the
offset forward. If the file is shorter than the offset, the reader resets to 0
and reads the whole file.

Watching the directory rather than the file is what survives truncation and
replacement: a file watch holds an inode and goes silent when the path is
rewritten. Starting at the current size rather than 0 satisfies the
"Neovim starts after the harness" scenario without a timestamp comparison.

- Alternative rejected: `vim.uv.fs_poll` on the log. That is the poll this change
  exists to remove, and it would reintroduce a fixed interval on the path that
  matters most.
- Alternative rejected: `vim.uv.fs_event` on the log file itself. Simpler, and it
  fails the rotation scenario: after the writer replaces the file, the watcher is
  attached to an unlinked inode and no further event arrives.

### Bus capability is a new registry field, not derived from `notify`

`registry.nix` SHALL carry a separate field recording whether a harness writes
edit events. It MUST NOT be inferred from `notify == "hook"`.

A notification hook and a post-edit hook are different surfaces. A harness can
fire on session idle and expose nothing after a file write, so deriving one from
the other would claim a capability that does not exist and produce a harness that
silently emits nothing.

- Alternative rejected: reusing `notify == "hook"`. It saves a field and asserts
  something unverified for five of the six harnesses, since only claude's
  post-edit surface is confirmed today.

### A harness whose surface cannot do this is recorded as false

If a harness's hook surface exposes no post-edit event carrying a file path, its
registry field SHALL be false and no bridge SHALL approximate it, for example by
diffing the working tree on a timer.

- Alternative rejected: a per-harness fallback that polls `git status` from the
  bridge. It reintroduces polling, attributes changes the agent did not make to
  the agent, and would report the owner's own edits as agent events.

## Rollout & Gating

The default gate sequence applies at every phase: edit, then `nix flake check`,
then `nix build .#darwinConfigurations.lv426.system`, then owner spot-check, then
`nh darwin switch` from the `sysinit.laurel` checkout. One deviation: the switch
is run in a separate WezTerm pane, never in the conversation pane.

Phase 1, writer only. The `paths-layout.json` entry, the subcommand, and its Go
tests. Nothing calls it, so the switch changes no behavior. Gate: `go test`
passes and the subcommand appears in `sysinit-agent help`.

Phase 2, claude only. One `PostToolUse` hook entry on the existing
`Edit|Write|NotebookEdit` matcher. Gate: the owner runs claude, edits a file, and
confirms the log holds a line naming that file. No editor involved yet, so a
failure here cannot affect Neovim.

Phase 3, the reader. The watcher and the touched set. Gate: the owner opens a file
in Neovim, has claude edit it, and observes the buffer reload faster than the
1-second tick, then confirms `file_refresh.lua` still refreshes for a scrape
harness.

Phase 4, the remaining five hook harnesses, one commit each. Each is gated on the
same manual confirmation as phase 2 and each may end in a registry field of false
if the surface does not exist.

Phase 5, review scoping. `:Review` restricted to the touched set.

Kill switches, in order of blast radius. Per harness: set the registry field to
false. For the reader: the watcher starts only if the manifest resolves the
`agentEdits` path, so it never runs on a machine whose manifest predates the
change. For everything: reverting the `paths-layout.json` entry leaves the writer
with nowhere to write and the reader with nothing to resolve.

## Risks / Trade-offs

Risk: five of six hook surfaces are unverified. Only claude's post-edit surface is
confirmed. Mitigation: phase 4 verifies each independently, and the recorded
outcome for a harness that cannot do it is a registry field of false, not a
workaround. This maps to the per-harness human-verification checkpoint in
`tasks.md`.

Risk: a hook that fails loudly breaks the agent loop. Mitigation: the subcommand
exits 0 on every failure path and writes nothing to stdout, and a Go test asserts
this for an unwritable log directory. Verified deterministically.

Risk: the reader reloads a buffer the owner is editing and discards work.
Mitigation: the reader checks `modified` before reloading and surfaces a conflict
instead. This is the one behavior that can lose the owner's data, so it maps to a
human-verification checkpoint: the owner makes an unsaved edit, has an agent write
the same file, and confirms nothing is lost.

Risk: the touched set makes a review look complete when it is not, because a
scrape harness or the owner changed files that never produced an event.
Mitigation: the full working diff stays reachable, and the scoped review states
that it is scoped. Judged by the owner, not by a test.

Trade-off: events are post-hoc. Neovim learns an edit happened after it is on
disk, so it cannot gate it. This is deliberate, since the owner runs accept-all,
and it is what makes the harness able to stay ignorant of the editor.

Trade-off: truncation can drop events a slow reader has not read. A Neovim
suspended past K lines of edits loses the earliest ones from its touched set. The
files are still in the working diff, so nothing is unreviewable; the set is
incomplete, not wrong.

## Migration Plan

There is no existing state to migrate: the log does not exist yet, and no
consumer reads it.

The one step that mutates shared state is the switch itself, which rewrites the
paths manifest in the home directory. Before it: `nix build` must exit 0, which
proves the manifest evaluates. After it: read the installed manifest and confirm
the `agentEdits` entry resolves to an absolute path under
`$HOME/.local/state/agents`, before any harness is wired to write there.

Rollback per phase is `git revert` of that phase's commit followed by a switch, in
that order, because the reader must stop resolving the path before the path is
removed. No step needs elevated permissions and nothing outside the home
directory is written.

## Open Questions

Whether `review.nvim` accepts a file list to scope a review, or whether phase 5
must drive `codediff.nvim` directly against the touched set. This decides phase 5
only and blocks nothing before it.

Which post-edit event each of the five non-claude hook harnesses exposes, and
whether the event carries an absolute file path. Phase 4 answers this per harness
by reading the installed harness rather than by assuming.

The exact size bound and last-K-lines value. They should be picked from an
observed turn's event count rather than guessed, which phase 2 makes measurable.
Answered in 6.1 from this workspace's own log: 512 KiB and 200 lines, measured
from 52 events over 90 minutes at 233 bytes a line.

Whether review.nvim can attach to a codediff session at all on the pinned pair.
Answered in 5.5, and the answer was no: codediff `31510a9` returns
`{ absolute, relative }` where review.nvim `8e4bc16` expects a path string, so
`on_session_created` throws before it installs its comment layer. `<leader>dr`
was broken the same way and by the same line, which is why the guard lives in
`plugins/review.lua` rather than beside the scoped open.

Whether the reader should also consume the events claude already delivers over
its WebSocket connection, or ignore them and rely on the bus. Deferred: claude
works today either way, and the answer only matters if the two paths produce
duplicate reloads, which phase 3 will show.
