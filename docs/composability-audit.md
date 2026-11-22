# Sysinit workstation audit

## Building-block follow-up

Start from the command that owns the operation. Add a picker, viewer, or
execution wrapper when the workflow needs it.

| Job | Default entry point | Compose it with |
| --- | --- | --- |
| Start or resume an agent | `agents`, `agents <harness>`, or `agents threads` | `agents list --details` for JSON discovery. Run from the selected directory. |
| Inspect what changed | Native last-turn review or `review-checkpoint diff` for a marked worktree | Pipe the patch to `hunk patch`, or use `agent-diff` for a worktree view in a WezTerm split. |
| Find a session or pane | `sy` for working directories and `ty panes` for live pane IDs | Pass an explicit ID to `ty pane spawn` or `ty pane focus`. |
| Preview a remote connection | `tsh --dry-run HOST` | For an explicit native WezTerm attach, preview with `tether attach --dry-run HOST`. |
| Track and run work | `taskwarrior` for work and `tq submit --task UUID -- COMMAND` for a separate attempt | Use `tq status` for JSON inspection or `task-board` for the overview. |

Two command-discovery probes found defects. `agents --help` tried to launch a
harness named `--help`. `tq submit --help` queried Pueue and rewrote attempt
state before printing usage. Both now print usage before accessing their
runtime dependencies. `tq` also rejects unknown commands, a missing command,
and conflicting directory selectors before touching queue state. Native harness
arguments still pass through the launcher unchanged.

The cached plan for `arrakis` selected SSH from a shell outside WezTerm.
The explicit attach preview selected its native mux. The cached probe was
stale, so this confirms the routing distinction only. The Taskwarrior board
reported three tasks whose older queue attempts it could not order. The queue
also showed five missing Pueue jobs. Both are visible for diagnosis without
guessing which attempt succeeded.

Keep runtime state with its existing owners. The useful shared boundaries are
the harness catalog, Git patches, explicit pane IDs, and Taskwarrior and
attempt UUIDs. Each works from a shell and can feed another tool directly.

## Earlier workstation inventory

The audit covers the Darwin workstation, the shared Nix profiles, and the
shell, editor, terminal, queue, agent, GitHub, and desktop interfaces those
profiles enable. Live observations are from the workstation. NixOS and
remote behavior are based on source and existing checks. Production access,
remote login, visual fit on other displays, and historical usage frequency
are outside this pass.

The active generation matched Laurel `39fcc08` and Sysinit `1910b67c9`.
The live registry listed 13 harnesses and the published skill catalog had
44 names across four roots. The shared source contained 28 skill entry
points. The flake had 44 direct inputs and 117 lock nodes. These are
maintenance surfaces. Frequency of use requires separate evidence.

## What to take from Mitchell Hashimoto

- His public Home Manager config keeps a small common package list and puts
  most development dependencies in project flakes loaded by direnv. It also
  enables multiple shells, Neovim, Atuin, and several terminal frontends.
  Sysinit has reasons to differ, including the managed work laptop, remote
  mux attachment, shared terminal policy, and the requirement to rebuild a
  machine from source. The useful test is whether a package belongs in every
  project or only in the project that uses it.
  [Public Home Manager configuration](https://github.com/mitchellh/nixos-config/blob/main/users/mitchellh/home-manager.nix)
- His building-block argument favors a reusable core and a polished
  application above it. Here, Git patches and native status are the
  boundaries. Codex desktop is useful because one gesture opens the right
  checkout's diff. The terminal path can use OpenCode's own Last turn view,
  or a plain patch in Hunk or Diffview. A launcher is justified when it
  routes an existing action to the right pane or checkout.
  [The Building Block Economy](https://mitchellh.com/writing/building-block-economy)
- His agent workflow emphasizes independently verifiable tasks, read-only
  triage, and choosing when to look at work. Keep our queue and verification
  fixtures. Completion banners and a separate agent inbox need to earn
  their interruption and maintenance cost.
  [My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey)
- His OSC 7501 design puts program status on the terminal stream. Sysinit's
  pinned WezTerm UI already checks native program status before custom
  signals. Prefer that path wherever the actual producer and transport
  support it. Keep a compatibility fallback where measured. Superlogical
  and libghostty show why a reusable protocol is useful even with a
  different terminal application. The current WezTerm mux and remote
  workflows justify retaining WezTerm.
  [Program Status Protocol](https://mitchellh.com/writing/program-status-osc7501) · [Superlogical](https://mitchellh.com/writing/superlogical)

## Correctness findings

| Finding | Evidence and consequence | Smallest repair and acceptance check |
| --- | --- | --- |
| Terminal queue environment outlives the launch | In an isolated run with a synthetic environment, a fake mux spawn failed and left a mode-0600 `.environment` file containing the canary. The producer copies the Pueue runner's environment after applying attempt overrides, and the child reloads it. I found zero such files at the top level of the live legacy queue state. | Make the handoff short-lived and pass only values needed by the job, including explicitly selected overrides. Use a synthetic canary to check cleanup on success, failed spawn, and cancellation. [Queue terminal implementation](../pkgs/tq/terminal.go) |
| The board can pick an older attempt when queue IDs are reused | With an older success at Pueue ID 90 and a newer attempt at ID 1, the installed board showed the old attempt in Review. Attempt records have no creation field. The Pueue ID identifies a job within its queue and currently doubles as a timestamp. | Let `tq` publish durable attempt order. Preserve legacy records and make unknown ties visible. Verify the board with reset IDs and with a new attempt before it gets a job ID. [Board projection](../pkgs/task-board/data.go) · [Attempt record](../pkgs/tq/state.go) |
| One bad workspace record hides the catalog | A malformed `workspace.json` in an isolated state directory caused the installed `agent-workspace list` to exit with empty stdout. The task board can continue with an integration error, but it loses all workspace links for that read. | Keep direct actions on an invalid record strict. If automatic discovery stays, preserve valid rows and expose the rejected record without changing the existing JSON shape by accident. Verify one valid record beside one broken record. [Workspace listing](../modules/home/programs/llm/runtime/workspace/workspace.nu) |
| Successful queue state depends on reconciliation before cleanup | Read-only `tq status` and `snapshot` are correct as projections. The stored attempt preserves a completed result once reconciled. The live sample had 86 attempts, 81 Pueue jobs, and five attempts reported as Missing. Those counts establish drift and do not identify its cause. | Keep the current explicit reconciliation contract. If losing completion becomes a repeated workflow issue, have the queue adapter persist completion at the owning event. Avoid putting writes back into dashboard reads. [Queue reconciliation](../pkgs/tq/main.go) |
| OpenCode approval defaults are broad | The installed TUI reports `autoaccept`. The managed server rules allow by default and carve out shell-deny globs. This is a local convenience policy, and the use of a deny list makes the effective write boundary harder to explain. | Test policy with harmless read, local edit, external write, and secret access cases before changing defaults. Keep a documented scope for unattended work and use native permission mechanisms for the action owner. [OpenCode renderer](../modules/home/programs/llm/harnesses/opencode/render.nix) |

## Keep, simplify, or retire

| Area | Recommendation and reason |
| --- | --- |
| Nix and machine ownership | Keep sysinit for shared packaging, the Laurel consumer for work policy, and native Neovim and WezTerm config in their owner repositories. Keep flake checks and verify the active generation after activation. Trim permanent inputs, overlays, and globally installed development toolchains one owner at a time. Start with candidates that have no configured caller. Project-specific versions and experimental CLIs belong in dev shells or on demand. [Profiles](../modules/shared/profile-tiers.nix) · [Package tiers](../modules/home/packages.nix) |
| Shells and scripts | Keep Nushell for structured command output and a POSIX login/bootstrap path. Shell compatibility is a real requirement for GUI, SSH, existing hooks, and Pueue. Keep native Lua and TypeScript at editor and harness APIs. Keep Atuin as the native command history and recovery interface. Keep the remaining Python PTY and RPC fixtures until a replacement can exercise the same behavior. [Python deferrals](python-migration.md) |
| Git, editors, and review | Keep Git as the baseline owner and `review-checkpoint diff` as ordinary patch stdout. Its scratch index preserves staging and its ref is per worktree. Use Codex desktop and the native OpenCode view for local conversational review, Hunk for a separate reader, and Atlas for GitHub review. Keep Diffview for merge/edit operations. tuicr is the next viewer to test against Hunk's line feedback. Changes still invokes diffnav, so replacing that reader comes before removing its package. [Review tools](review-tools.md) |
| Sessions, terminals, and remote access | Keep Git for worktree state, Seshy for named directory groups, WezTerm for panes and mux, and OpenSSH for authentication. Keep `ty` as the small callable terminal interface. Keep Tether where grouping aliases and selecting native attachment saves work. Its cached plan selected native attachment for `arrakis` in the live sample. Keep the current client-endpoint split for visible user work and headless queue work explicit. [Terminal workflows](../modules/home/programs/llm/skills/local-workflows/references/execution-and-terminals.md) |
| Agent workspace | Make ordinary native launches the default. `agent-workspace` combines conversation restoration, a filesystem observer, a review split, notes and feedback, and a Codex App Server proxy. Its runtime is about 1,240 lines. The live state had one record, with no Taskwarrior UUID or matching live pane. This snapshot does not establish historic usage. Retain it as optional until the exact resume or feedback workflow justifies keeping the bundle. Preserve `agent-diff` and the independent pane primitives. [Agent workspace interface](agent-workspaces.md) |
| Task and execution | Keep Taskwarrior for intent and Pueue for execution. `tq` earns its place by linking durable attempts to Taskwarrior and supporting cancellation and visible jobs. Keep `worker` for commands that require a visible workspace, without another queue on top of it. Keep the board as a derived read view. Cancel, resume, start, and complete should call the owner. [Task board](task-board.md) · [Worker](worker.md) |
| Agent registry, skills, and hooks | Keep the single registry and measured compatibility checks. Each additional installed harness adds update, config, permission, completion, and status work. Separate daily defaults from launch-on-demand in the package profile and picker, using actual usage and distinct capability to choose. Prefer one managed skill per workflow and keep work-specific policy downstream. Keep custom status notifications where they provide a signal a native protocol cannot yet supply. [Skill maintenance](skill-maintenance.md) |
| GitHub, Linear, and MCP | Keep the native CLI as an independently usable path. `gh-pr-state` provides bounded polling and rereads GitHub results. Live account access to preview event subscriptions was denied in the previous probe. Revisit when account access changes. Keep Linear authoritative for imported issue fields and completion. Keep MCP only where a client needs transport translation or a work connector, with policy at the owning boundary. [PR observation](../modules/home/programs/llm/skills/local-workflows/references/pull-requests.md) |
| Desktop and storage | Keep shared Rift and SketchyBar geometry in `desktop-layout.nix`. The live bar reported height 32, margin 16, and 8-point inner padding on each side. Reproduce notch and display movement visually before adding another layout helper. Keep Hammerspoon focused on actions macOS lacks and keep storage maintenance owner-specific. The observed workstation had about 19 GiB free. A capacity reading does not establish the cause of freezes. [Shared geometry](../modules/darwin/desktop-layout.nix) · [Retention policies](storage.md) |

## Order of work

1. Repair the terminal queue environment handoff and attempt ordering. Both
   fixes belong with the attempt owner. Re-run the independent board and
   queue fixtures against the new contracts.
2. Remove `agent-workspace` from the everyday path while keeping ordinary
   agent launches, the native review view, and `agent-diff` first-class.
   Collect examples where the optional workspace changes the outcome before
   investing in the proxy or observer.
3. Audit what stays global. Start with duplicated viewer, package-manager,
   and LSP choices and the 13-harness default. Remove one confirmed duplicate
   at a time across package, picker, and docs. Keep the native path open
   before and after each change.
4. Reduce notification noise after checking native status end-to-end in
   local and remote panes. Avoid adding a second status protocol or a new
   notification daemon.

## Validation

The focused Darwin Nix checks passed for review checkpoint, OpenCode, the
queue, PR workflow, and URL routing. Read-only live probes returned four
WezTerm panes, one client, and a Taskwarrior board without integration
errors. The three fixture failures above exercise real installed binaries
with isolated state. Live Linux behavior and comparative startup latency
remain unmeasured. This pass changed the audit document.
