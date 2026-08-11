> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

Neovim is already the diff reviewer, and it already talks back to every harness.
What it cannot do is notice.

The review side exists. `georgeguimaraes/review.nvim` (pinned `8e4bc16c`) plus
`esmuellert/codediff.nvim` (`31510a9b`) are declared in
`modules/home/programs/neovim/config/lua/plugins/review.lua`. `<leader>dr` opens
the working diff and annotates it. `<leader>jR` runs
`harness.api.send_review()`, which reads `review.store`, renders
`review.export.generate_markdown()`, and hands it to the active adapter
(`modules/home/programs/neovim/config/lua/harness/api.lua:158-178`). Selection
context works the same way, through `placeholders.apply("+selection")` and
`adapter.send`.

That direction is harness-agnostic already, because `adapter.send` types into the
harness's own pane. It needs no protocol and it covers all fourteen harnesses.

The direction that is missing is the agent telling Neovim an edit landed. Today
Neovim polls: `harness/file_refresh.lua:3` sets `INTERVAL_MS = 1000` and runs
`silent! checktime` on a timer. A poll reloads a buffer, and that is all it can
do. It cannot say which files this turn touched, so `:Review` opens the whole
working diff and the owner has to remember what the agent was working on.

One harness does better, by speaking a protocol. `coder/claudecode.nvim`
(`2390c6e4`) runs a WebSocket server and writes `~/.claude/ide/<port>.lock`, so
claude pushes diffs to Neovim directly. Two other harnesses have such a protocol:
copilot validates a lock file requiring `socketPath`, `scheme`, `headers`, `pid`,
`timestamp`, `workspaceFolders`, and `ideName`, and amp takes `--ide`. Getting
those two would mean reverse-engineering each protocol out of a shipped bundle
and re-verifying on every upgrade, and the remaining eleven harnesses would still
have nothing.

The cheaper seam is already built here, three times over.

`modules/home/programs/llm/harnesses/registry.nix` carries a `notify` field.
Six harnesses are `notify = "hook"`: atomic, claude, codex, opencode, pi, and
prime-agent. Each calls a shared, harness-agnostic command,
`agent-state <harness> <state> <detail>`, from its own hook surface: declared
hook entries for claude and codex, a 50-to-71-line TypeScript bridge for the
other four. The eight `notify = "scrape"` harnesses have no hook surface.

`sysinit-agent` (`pkgs/sysinit-agent/`) is the Go binary behind those commands,
with `internal/agentstate`, `internal/repo`, `internal/note`, and
`internal/watch`. `watch` already renders and tails the agent-state bus, keyed by
directory.

`modules/shared/options/paths.nix` reads `paths-layout.json`, resolves every
state path, and installs the result as a JSON manifest at a fixed home-relative
location, so a runtime consumer reads one file to learn every other.

So the gap is narrow: no writer emits a file-edit event onto that bus, and
Neovim reads nothing from it.

## What Changes

A harness hook appends one line per edited file to a log. Neovim watches the log
and reacts. Neither end names the other.

The harness end is one more entry beside the `agent-state` call already in each
hook config, backed by a new `sysinit-agent` subcommand. The agent loop is
unchanged: the write is fire-and-forget and cannot fail a tool call. The harness
does not learn that Neovim exists.

The Neovim end reads the paths manifest, resolves the log, starts one
`vim.uv.fs_event`, and on each new line reloads the buffer if it is open and
clean, and adds the file to a per-session set of what the agent touched. Neovim
learns only an opaque harness label, which it displays.

That set is the point. It turns `:Review` from "the whole working diff" into
"what this turn changed", and it makes the review triggerable by the edit instead
of by the owner remembering to look.

An append-only JSONL file, not a unix socket. A hook is a short-lived process
that must not block and must not fail when nothing is listening, and a socket
requires a live peer on every write. A file write needs no peer, and the log
stays readable afterward, which is the difference between debugging a hook and
guessing at one. Latency does not decide this, because the reader is a human
reading a diff.

`file_refresh.lua` stays, because the eight `notify = "scrape"` harnesses have no
hook to write from. What changes is that the six hook-capable harnesses stop
depending on a 1-second poll to find out.

### Non-goals

The Neovim-to-agent direction is out of scope because it already works.
`send_review`, the selection sends, and `adapter.send` cover it for all fourteen
harnesses, and nothing here replaces them. This change adds no second path for
context to reach an agent.

No harness-specific IDE protocol. Copilot's lock file and amp's `--ide` are out
of scope, and this change makes them unnecessary rather than pending.
`claudecode.nvim` is untouched at its pinned commit: claude keeps its WebSocket
integration and additionally emits bus events like every other hook harness.

Agent Client Protocol is rejected, not deferred. In ACP the editor drives the
prompt, so Neovim becomes the surface the owner types into and the TUI
disappears. That inverts the working arrangement. Six harnesses speak ACP
(`copilot --acp`, `devin acp`, `goose acp`, `hermes acp`, `opencode acp`,
`prime-agent --mode acp`) and none will be reached this way.

`roshbhatia/hermes.nvim` is rejected: it is an ACP client, unrelated to
hermes-agent despite the name. `olimorris/codecompanion.nvim` is rejected: it
brings its own chat UI, and `review.nvim` plus `harness/` already own that
ground.

No approval gating. A hook that blocked until Neovim answered would turn the
editor into an approval prompt. The owner runs accept-all, so the edit has
already happened and the editor's job is to show what changed.

No new chat interface, prompt buffer, or model picker. The TUI remains the only
place the owner composes a message.

No event stream for the eight `notify = "scrape"` harnesses (amp, crush, cursor,
devin, gemini, goose, hermes). They keep the poll.

## Behavior

### The bus is a declared path with a documented line shape

The event log SHALL be a new entry in `modules/shared/options/paths-layout.json`,
so both ends resolve it from the generated manifest and neither hardcodes a path.

Each line SHALL be a single JSON object carrying at minimum the absolute file
path, the kind of change, a timestamp, the harness label, and the directory the
harness ran in. It MUST NOT carry file contents: the file on disk is the content,
and a log that duplicates it goes stale.

- WHEN a writer appends a line
- THEN it appends without reading the log first, and two harnesses writing
  concurrently each produce an intact line

### A hook write never affects the agent loop

- WHEN the hook runs and the log's parent directory does not exist
- THEN the hook creates it, writes, and exits 0

- WHEN the hook cannot write at all, for any reason
- THEN it exits 0, prints nothing to the agent, and the tool call succeeds
  unchanged

#### Scenario: no editor is running (negative)

- WHEN no Neovim is watching
- THEN the hook still writes, exits 0, and the log does not grow without bound,
  per the bound the design states

#### Scenario: a scrape harness edits a file (negative)

- WHEN a `notify = "scrape"` harness edits a file
- THEN no event appears, Neovim reports nothing, and `file_refresh.lua` refreshes
  the buffer as it does today

### Neovim reacts without knowing the writer

- WHEN a line names a file Neovim has open with no unsaved changes
- THEN the buffer reloads, without waiting up to 1 second for the next
  `checktime`

- WHEN a line names a file Neovim has open and the buffer IS modified
- THEN Neovim MUST NOT discard the owner's edits, and surfaces the conflict
  instead

- WHEN a line names a file Neovim does not have open
- THEN the file joins the touched set and no buffer is opened, because opening a
  buffer per agent edit would fight the owner for the window

- WHEN the owner opens a review after a turn
- THEN the diff is scoped to the files in the touched set, and the owner can
  still reach the full working diff

#### Scenario: Neovim starts after the harness (negative)

- WHEN Neovim starts with events already in the log
- THEN it does not replay history as a burst of reloads, and begins at the
  current end of the log

#### Scenario: the log is rotated or deleted under the watcher (negative)

- WHEN the log is replaced or removed while Neovim watches it
- THEN the watcher recovers onto the replacement, and Neovim reports no error to
  the owner

### The registry stays the single source

- WHEN a harness gains or loses the ability to write to the bus
- THEN that fact is expressed in `registry.nix`, and no second list of harness
  names is introduced

## Impact

Affected: `modules/shared/options/paths-layout.json` (a new path entry),
`pkgs/sysinit-agent/` (a new subcommand beside `agent-state` and `note`),
`modules/home/programs/llm/runtime/default.nix` (the wrapper that exposes it),
`modules/home/programs/llm/harnesses/registry.nix` (the field recording bus
capability), the six `notify = "hook"` harness modules and the four
`sysinit-notify.ts` bridges (one hook entry each), and
`modules/home/programs/neovim/config/lua/harness/` (the watcher, plus the touched
set that scopes a review).

Not affected: the eight `notify = "scrape"` harness modules,
`file_refresh.lua`, `claudecode.nvim`, `review.nvim`, `harness.api.send_review`,
and every existing Neovim adapter.

Risk: six harnesses means six hook surfaces, and a hook surface can change under
a version bump. A broken writer is silent by construction, per the negative
scenarios: no events means Neovim behaves as it does today rather than erroring,
so a regression degrades to the current behavior instead of breaking the editor.

Second risk: an append-only log grows. The design MUST state a bound and the
behavior at that bound, and a negative scenario above depends on it.
