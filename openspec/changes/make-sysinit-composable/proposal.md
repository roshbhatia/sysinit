## Why

This repository builds exactly one thing: a whole host, from `hosts/`, through
`darwinConfigurations` or `nixosConfigurations`. Every other way an owner might
want to consume it is unreachable. Underneath that, three separate defects hold
it in place.

### The smallest orderable unit is one complete machine

`flake.nix:125-236` exports no `homeModules`, `darwinModules`, or
`nixosModules`. `flake.nix:188-193` is the whole `lib` output, and it carries only `builders`
and `hostConfigs`.
`templates/discrete/flake.nix:34-77` confirms the consequence: the one reuse
path re-imports `sysinit + /lib`, calls `builders.buildConfiguration`, and gets
a complete system back.

`modules/home/programs/default.nix:6-41` imports 34 modules unconditionally and
none has an `enable` option. `modules/home/packages.nix` is one 162-entry
list mixing Go, Rust, Kubernetes, Terraform, and twelve agent CLIs, with one
conditional in it. There is no subset, so installing a shell installs
`opentofu`.

The injection point that was supposed to solve this is dead. `utils` is
threaded through nine sites (`lib/builders/pkgs.nix:29`, `lib/builders.nix:36`
and `:51`, `lib/builders/darwin.nix:24`, `:33`, `:56`, `:64`,
`lib/builders/nixos.nix:14` and `:50`) and dereferenced nowhere: no `.nix` file
in the repository contains `utils.`. Four more sites forward it by name into
`home-manager.extraSpecialArgs` (`lib/builders/darwin.nix:15`,
`modules/darwin/home-manager.nix:3` and `:14`, `modules/nixos/home-manager.nix:4`
and `:15`), so the removal reaches thirteen places, and
`templates/discrete/flake.nix:53` reads `mkUtils` from a published flake output. The `sysinit = ../..` specialArg
(`lib/builders/darwin.nix:28`) has zero consumers. Real modules bypass both and
reach out by relative path at three different depths, so
`modules/home/programs/wezterm/default.nix:9` imports `../../../lib/paths.nix`.
Any module lifted out of the tree carries a `../../../` that resolves to
nothing.

### Agents cannot record a fact without moving something on screen

Fourteen mechanisms reach out of an agent's process onto the owner's screen. Six
steal focus, four block the agent's turn, and six have no off switch. The three
properties overlap, so the counts do not sum to fourteen. The next paragraph is
one mechanism that carries all three.

The worst is `modules/home/programs/llm/runtime/agent-prompt.sh:136`. On a
Claude `Notification` hook it raises a desktop notification with Accept and Deny
buttons, waits up to 300 seconds (`:120`), and then types the answer into
`$WEZTERM_PANE` with `wezterm cli send-text`: a carriage return to approve, an
ESC to reject (`:52-53`). That is the agent's own pane, and the keystroke lands
minutes later into whatever the pane is doing by then. There is no toggle.

There are two independent editor-drive paths, not one.
`pkgs/sysinit-agent/internal/nvimlink/nvimlink.go` dials every neovim socket it
can glob and calls `require("harness.diffnote").refresh()`, adding up to 750ms
to every note write. Separately, `neovim/config/lua/harness/control.lua` exposes
thirteen RPC ops an agent drives through `config/bin/nvim-ctl`: `open`,
`goto_line`, `highlight`, `annotate`, `split_open`, `preview`, and more. Each is
synchronous, each moves the cursor or the window layout, and none requires
confirmation.

An agent writing a file is enough on its own.
`neovim/config/lua/harness/spec_watch.lua:123` starts a watcher unconditionally.
It registers at `:71-89` and opens a preview at `:35`, so editing any `.md` under
`openspec/` opens a split with no user action. The `:HarnessSpecWatch` command
and its toggle already exist at `:106-122`, so the auto-start is the only defect.

Three more subsystems own two jobs each. `wtrun` produces command output and
splits the caller's pane. `diffnote` produces review notes and drives neovim.
`agent-state` produces session state and forks `wezterm cli list` on every
single tool call, at `agentstate.go:329`, to learn its pane's workspace. Its OSC
user-var write is not in this list: it sets a value that moves nothing and dies
with the pane, and the archived change that chose it did so to avoid a class of
stale state this proposal does not answer.

`modules/home/programs/llm/skills/wtrun/wtrun.sh:126` drives the worker shell by
sending `\025` (Ctrl-U) followed by the command text as simulated keystrokes.
That is connascence of timing and position between two processes: the sender and
the receiving shell must agree on the input line's state and on the shell being
ready. The `\025` prefix exists because that agreement already failed once.
`:102` splits the caller's own pane and `:106` sleeps one second before
restoring focus, with nothing synchronizing the race.

`pkgs/sysinit-agent/internal/nvimlink/nvimlink.go` dials a neovim socket and
calls `require("harness.diffnote").refresh()`. A Go package names a lua module
inside another process.

### The same fact is derived in five languages

`~/.local/state` is re-derived in Go (`internal/statusline/statusline.go:104`,
`internal/agentstate/agentstate.go:47-65`, `internal/repo/repo.go:60-67`), in
shell (`runtime/agent-identity.sh:18`, `sy-gate.sh:43`,
`agent-sessions.sh:1`), in lua (`wezterm/lua/sysinit/pkg/ui.lua:187`, `:296`,
`:312`, `:564`, `:1735`), in python
(`harnesses/claude/worklog-hook.py:253`, `:327`), and in YAML
(`seshy/config.yaml:5`).

Those copies have already diverged. `agentstate.go:65` honours `XDG_STATE_HOME`
when it writes the pane record; `ui.lua:296` hardcodes
`home .. "/.local/state"` when it reads it. Three more lines hardcode the same
prefix for other files, `:312` and `:564` for seshy sessions and `:1735` for
wezterm workspace state, so they are the same defect and not the same pair. On a box that sets the
variable, the writer and the reader use different paths. `ui.lua:187` honours it
too, but writes a different file in the same process, so it is not the other
half of the divergence.

Git-root discovery is implemented at least eleven times: `internal/repo/repo.go:30`,
`internal/agentstate/agentstate.go:300`,
`neovim/config/lua/harness/context.lua:56-70`, `runtime/agent-identity.sh:34`,
`runtime/spec-preflight.sh:10`, `runtime/agent-review.sh:25`,
`harnesses/claude/worklog-hook.py:41` and `:76`,
`harnesses/pi/extensions/diff-review.ts:78`,
`harnesses/pi/extensions/openspec-sidebar/index.ts:150`, and
`neovim/config/lua/harness/diffnote.lua:12`, with a twelfth method at
`neovim/config/after/lsp/up.lua:14`.

Adding one agent harness touches fourteen hand-kept lists. That number is an
estimate and not a derivation: a grep for harness-name literals finds 24 sites
across nine files, and the difference is the sites that branch on one name
rather than enumerate them all. No command separates those two, so task 4.3
enumerates the lists by hand as its first step and 4.4 tests the result rather
than the count. Two of the lists already disagree:
`neovim/config/lua/harness/registry.lua` names harnesses the Nix side does not.
Seven `throw` assertions exist only to police the drift
(`llm/default.nix:190` and `:192`, `runtime/default.nix:64`, `:73`, `:75`,
`lib/instructions.nix:145`, `harnesses/pi/default.nix:75`), which catches it
without removing the surgery.

### What already works, and should be built on

The neovim config is 164 plain lua files with a `lazy-lock.json`, and it is
partly portable. No lua file contains a `/nix/` path. No lua file execs
`diffnote`, `agent-state`, `seshy`, `sy`, `wtrun`, or `sysinit-agent`.

It is not standalone, and an earlier draft of this proposal said it was. That
claim rested on a probe count that does not hold: `vim.fn.executable` appears
14 times across 12 files, against roughly forty binaries the config expects, so
most are not probed at all. More importantly the config drives wezterm
directly, in files no task touched. `harness/preview.lua:61` splits a pane,
`:74` activates one, `:211` and `:237` kill one. `utils/wezterm_terminal.lua:165`
runs `wezterm cli send-text`, and `:31`, `:35`, and `:104` activate, kill, and
split. `harness/adapters/claudecode.lua:170` kills a pane. `harness/lifecycle.lua`
selects a wezterm backend and sends text into agent panes.

That is the same defect as `agent-prompt.sh`, living in the editor instead of
in a hook, and `config/doc/agent-ide-integration.md:35` documents it as the
intended path: "Every adapter's `send()` ends here." So this is not a portability
footnote. It is the largest instance of the thing this change exists to remove,
and phase 2 now covers it.

Removing `harness/diffnote.lua` takes four things out of the editor, and the
proposal should say so plainly rather than call it free. The CodeDiff view
loses inline virtual text (`diffnote.lua:121-156`), the quickfix list on
`<leader>dn`, the float on `<leader>dN`, and the filesystem watcher that
refreshed them. Notes are not shown in neovim after this change.

That is the trade, not a side effect. Review moves out of the editor and into
`hunk`, which is the point: an editor that renders review notes is an editor
that agents have a reason to reach into.

`sysinit-agent` is a Go module, so `go install` puts the agent runtime on any
box with Go. `programs.mise` is enabled in `modules/home/programs/mise.nix`
carrying zero tools, so the obvious non-Nix installer is present and unused.

And `hunk` solves the presentation half outright. It was removed on 2026-08-05
in `878f78300`, whose proposal states the reason: "Diff review consolidates on
neovim, so hunk goes and the annotated diff becomes ours to build." That
decision is what forced a CLI to learn to drive neovim.

What `hunk` replaces is the presenter, not the record. Its documented
`session comment add` carries a file, one line selector, and a summary. It has
no second body field, no author, and no upsert, so it cannot hold what we store
today. The note file stays ours and `hunk` reads it. That deletes the neovim
drive (`internal/nvimlink`, 174 source lines) and the neovim renderer
(`harness/diffnote.lua`), and shrinks `internal/diffnote` (714 source lines) to
an append-and-print writer. `internal/store` is untouched: it holds six
durability properties that have a test here and no owner anywhere else.

## What Changes

- Agents stop initiating. The rule is who starts it and into which stream: an
  agent may write to an output stream about itself, may not write to an input
  stream, and may not move a surface the owner did not ask it to move.
  `agent-prompt`'s keystroke injection is deleted outright; the notification
  stays and answers nothing on the owner's behalf. `wtrun` is unchanged and
  leaves the agent skill set, because the defect was an agent opening a pane and
  not the pane. `agent-state` keeps both the file bus and the OSC user-var
  write, which sets a value that dies with its pane and moves nothing.
  `spec_watch` stops auto-opening. The `nvim-ctl` drive ops are deleted:
  `harness/control.lua` is 348 lines exposing thirteen unconfirmed editor
  operations, including one that runs arbitrary `vim.cmd`, reachable only
  through a hand-placed skill that no file in this repository generates. The
  owner's `<leader>j` keymaps stay, because pressing a key is asking.
- The note file stays ours and `hunk` reads it. `internal/store` and
  `internal/repo` are untouched, `internal/diffnote` becomes `internal/note` and
  keeps `add`, `apply`, `list`, `clear`, and `path`, and the neovim drive and
  renderer are deleted. A `review` command supplies
  `hunk diff --agent-context` over an export the writer republishes on every
  write, so a note survives with no viewer running. `review` is a separate verb,
  not a wrapper named `hunk`. The skill from `hunk skill path` mounts through
  the existing `skills/render.nix` path, so it reaches every harness.
- A `sysinit-agent watch` viewer renders any state file, launched by hand or by
  a wezterm chord.
- Agent output reaches a file for claude only, which is the one harness whose
  hook payload carries `transcript_path`. None of
  the eleven harnesses has a transcript or output-file setting, configured or
  available, so "tee stdout to a file" is not reachable by configuration. A
  Claude hook mirrors `transcript_path` into
  `$XDG_STATE_HOME/agents/transcripts/<harness>/<session>.jsonl`. The other ten
  are recorded as uncovered: five fire no hooks at all, and codex, pi,
  opencode, devin, and gemini fire hooks whose payloads carry no transcript
  reference. An earlier draft said seven fire none, which counted `scrapeBridged`
  (`runtime/default.nix:25-33`), a list of harnesses not bridged to the notifier
  and a different property: `devin.nix:20` and `gemini/default.nix:20` both
  render a `PreToolUse` hook. None is
  scraped, because reading a pane's rendered text is the coupling this change
  removes.
- One `sysinit.paths` module owns every state path, and the Go, shell, lua, and
  python copies read from it instead of re-deriving it.
- One harness registry replaces the hand-kept lists.
- `zmx` becomes the session substrate under zsh. A named shell session that
  survives a detach, with no windows, panes, or splits, because that is the
  window manager's job. seshy attaches one per session, and `ZMX_SESSION` becomes
  the session key the agent state writer reads with no terminal fork. What the
  wezterm agent deck groups by is decided in phase 10 rather than assumed: it
  groups by workspace today and does not read the session field at all.
- A profile layer. `sysinit.profiles.<minimal|dev|workstation>` gates the 34
  imports and the 162 packages. Hosts select `workstation` and are unchanged.
- `homeModules` and `homeConfigurations` outputs, so
  `home-manager switch --flake github:roshbhatia/sysinit#dev` works on any box
  with Nix.
- Theming becomes optional behind `sysinit.theme.enable`.
- A generated non-Nix bootstrap: one tool manifest, from which both the Nix
  package list and a `mise.toml` are derived.

### Non-goals

- No change to what the current hosts install. `lv426` and `arrakis`, which are
  the two hosts `hosts/default.nix` defines, select `workstation` and resolve to
  the same closure. This change
  adds ways to take less, never less by default.
- No reimplementation of `wtrun` as a child process. It keeps its pane and all
  five of its documented guarantees; only its agent skill entry goes.
- No `diffnote` shim over `hunk`. Two names for one concept is the "one word,
  one meaning" rule broken in code.
- No move of the neovim config into the store. The out-of-store symlink is why
  lua is editable without a rebuild.
- No rewrite of `ui.lua`. It is 1,799 lines in one function and it is the worst
  file here, but it is terminal chrome, not composability, and mixing the two
  makes both unreviewable.
- No second copy of the tool list. The generated `mise.toml` has one writer.
- No attempt to reproduce the full closure without Nix.

## Behavior

Must do:
- no agent drives a terminal, decided by the four clauses of task 2.9 plus
  `rg -n 'wezterm' pkgs/sysinit-agent` returning nothing. An earlier form of this
  criterion named two greps and called `rg 'wezterm cli' modules/home/programs/llm
  pkgs` the one that matters. That command returns no hit today, so it cannot
  detect the coupling the same sentence calls decisive: the per-tool-call fork at
  `agentstate.go:329` is `exec.Command("wezterm", "cli", "list", ...)`, which no
  `wezterm cli` string grep sees. Task 2.2 deletes that fork and the fifth clause
  is what proves it
- reporting its own status to its own terminal is not driving it, so the OSC
  user-var write stays. An earlier draft removed it, which would have traded a
  channel that dies with its pane for a file that outlives it
- no agent answers a permission prompt on the owner's behalf, decided by the
  absence of any `send-text` carrying `\r` or `\033`
- no agent opens a pane, decided by `wtrun` no longer appearing in the rendered
  skill set. `wtrun` itself is unchanged and keeps all five of its guarantees
- no agent process opens a connection to a running editor, decided by the
  absence of `internal/nvimlink` and no msgpack or nvim socket reference in
  `pkgs/`
- an agent writing a file opens no window, decided by editing an `openspec`
  markdown file with an editor open and observing no new split
- review notes survive with no viewer running, decided by writing notes with no
  `hunk` process, then running `review` and seeing them. `review` is a separate
  verb that supplies the context flag and passes the rest through, so no flag is
  left to the owner to remember and `review --watch` is covered too
- a note written while the viewer is already running reaches it, or the design
  states plainly that it does not and names re-running `review` as the way to
  see it. This is the property the no-push decision rests on, so it is checked
  rather than asserted
- a note keeps its rationale and author, decided by writing one with both and
  reading them back from the file named by `sysinit-agent note path`
- the note store keeps its durability, decided by all ten of the writer's
  store-discipline tests still passing. Gating on `internal/store`'s own tests
  proves nothing: that package is kept byte for byte, so its tests cannot fail,
  and they assert the property exists rather than that the writer still uses it
- a profile smaller than `workstation` produces a smaller closure, decided by
  `nix path-info -S` on `minimal` and on `workstation`
- the reorganizing phases change nothing the hosts install, decided by
  `nix eval .#darwinConfigurations.lv426.system.drvPath` AND
  `nix eval .#nixosConfigurations.arrakis.config.system.build.toplevel.drvPath`
  matching the baseline as re-recorded after phase 3. Both hosts, because
  `hosts/default.nix` defines two and they take different attribute paths. An
  earlier draft named `lv426` alone while saying "the hosts", so this criterion
  could be met in full while a module was silently dropped from the NixOS host.
  The `arrakis` half evaluates only on `x86_64-linux` and so runs in CI rather
  than on the owner's machine, per task 1.1. No local builder is a precondition.
  Phases 2 and 3 move it on purpose by deleting
  and renaming packaged code, so every difference they cause must be named by a
  task, and no difference may appear after them
- a standalone home configuration evaluates without nix-darwin or NixOS,
  decided by `nix build .#homeConfigurations.dev-x86_64-linux.activationPackage`
- one place owns each state path, decided by a check that fails when
  `.local/state` appears outside the paths module
- the generated `mise.toml` and the Nix package list name the same tools,
  decided by a generator that fails when they disagree

Must still hold:
- `sysinit.theme.enable = true` produces the styling the hosts have today,
  decided by comparing the generated theme files before and after
- the agent runtime installs without Nix, decided by
  `go install ./pkgs/sysinit-agent` on a box with only Go
- `wtrun` still reports a command's own exit status, decided by its existing
  contract that `wtrun -w` exits with the command's status

Owner decisions, recorded 2026-08-08:
- the third-party dependency on `hunk` is accepted. Its loopback daemon is
  accepted as a notifier only, because the note file stays ours
- the notification surface stays. The form is the author's call, and a hook
  raising a system notification satisfies it. The agent deck stays as well.
  What phase 2 removes is the keystroke injection that answered the prompt, not
  the signal that a prompt is waiting

Delegated and decided, recorded in `design.md` sections 6 through 9: `minimal`
is defined and is the same list as the non-Nix set; the neovim config stays in
this repository and `bootstrap.sh` uses a sparse checkout; `ui.lua` becomes the
follow-on change `decompose-wezterm-ui`; and the `nvim-ctl` drive ops are
deleted rather than made opt-in.

## Impact

Modified code:
- deleted: `pkgs/sysinit-agent/internal/nvimlink`, the diffnote skill,
  `neovim/config/lua/harness/diffnote.lua`, its six call sites in
  `codediff.lua`, `harness/control.lua`, `config/bin/nvim-ctl`,
  `harness/instance.lua`, and `utils/remote_editor.lua`
- the two ways an agent reaches the editor's socket: the registry
  `harness/instance.lua` publishes, whose only reader is the deleted `nvim-ctl`,
  and the `EDITOR_WRAPPER` shim `utils/wezterm_terminal.lua:46-58` exports into
  every pane it spawns. The wezterm control surface itself stays: an earlier
  draft deleted it, and ten of the owner's `<leader>j` keymaps reach it
- kept unchanged: `pkgs/sysinit-agent/internal/store`, `internal/repo`, and
  `skills/wtrun/wtrun.sh`, which keeps all five of its guarantees and only stops
  being exposed to agents
- renamed and shrunk: `internal/diffnote` becomes `internal/note`, keeping
  `add`, `apply`, `list`, `clear`, and `path`, losing every neovim call
- added: `review`, and a derived hunk-shaped export the writer republishes under
  the store lock
- `templates/discrete/flake.nix` and `lib/builders/`: the `utils` and `mkUtils`
  removal reaches the published template, which is a flake output
- `openspec/specs/`: this change carries spec deltas, since it alters behavior
  that `agent-state-emission` and the diffnote specs mandate
- `modules/home/programs/default.nix` and `packages.nix`: profile-gated
- `modules/shared/options/`: new `profiles.nix` and `paths.nix`
- `flake.nix`: new `homeModules` and `homeConfigurations`
- `modules/home/programs/llm/`: one harness registry replacing the hand-kept lists
- the 20 modules referencing `stylix`
- new `modules/home/programs/zmx/`, and `zmx` in the package set. It is in
  nixpkgs at 0.6.0, so no flake input and no overlay entry
- new `bootstrap/`: the tool manifest, the generator, and `bootstrap.sh`

Dependencies: adds the `hunk` flake input back, pinned to its own nixpkgs
because its build enumerates `perSystem.x86_64-darwin` which our
nixpkgs-unstable dropped. Removes the `neovim/go-client` Go dependency. `mise`
is already installed.
