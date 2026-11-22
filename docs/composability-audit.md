# Sysinit composability audit

This audit covers the managed workstation stack, the shared macOS and NixOS
configuration, and the companion tools used for tasks, terminal work, agent
execution, review, and deployment. Live checks ran on the Darwin workstation.
Linux findings come from the shared source and flake configuration. The audit
does not include a production access or remote host configuration review.

## Keep the ownership boundaries

| Layer | Owner and interface |
| --- | --- |
| Machine and user configuration | Nix and Home Manager own packages, configuration, services, and deployment revisions. Laurel owns its private policy and downstream pin. |
| Directory and worktree lifecycle | Git owns worktree registration and dirty state. Seshy groups directories and produces launch plans. |
| Visible processes | WezTerm owns panes and domains. `ty` exposes pane operations and `nuwez` exposes the same data in Nushell. `worker` serves visible command execution. |
| Remote transport | OpenSSH owns credentials and known hosts. Tether owns route selection, capability probing, and transport negotiation. WezTerm and the foreground session provider execute their respective attachment paths. |
| Durable work and execution | Taskwarrior owns task state. Pueue owns queue execution. `tq` links attempts to task UUIDs and retains review evidence. |
| Agent conversations and review | Each agent owns conversation history. The published registry supplies launch metadata. `agent-workspace` links a pane and directory to optional task and agent IDs. Neovim and Changes own review and notes. Atuin records prior command and conversation context. |
| GitHub and Linear | GitHub and Linear own their remote records. Local helpers read native structured output. Taskwarrior imports Linear metadata and retains local annotations and start/stop state. |
| Desktop, editor and mail | SketchyBar, Hammerspoon, WezTerm, Neovim, and Emacs own their native presentation. Their configuration stays declarative. Cross-tool capabilities belong behind shell commands or typed provider plans. |

The published lens on the running system found thirteen managed agents. The
upstream shared skill tree has twenty-eight skill entry points and six checked-in
role files. Use that catalog to remove duplicate entry points while preserving
harness-specific native configuration and Laurel-specific scope.

## Findings and priorities

1. **Separate observation from reconciliation.** `tq status`, `snapshot`,
   and the initial queue browser read the live projection without rewriting
   attempts. Use `tq reconcile` when results need to survive queue cleanup.
   Tether's dry-run commands use cached remote inventory. Use `tether probe`
   or `tether plan --resolve` for live remote discovery.
2. **Share pane identity and launch plans.** `agent-workspace` and
   `agent-diff` read live panes and clients via `ty`. Each caller still checks
   its owning tab and chooses its own action. `tq` targets its configured
   persistent mux even with no attached GUI client, so its queue execution
   retains that explicit endpoint. SSH attachment remains a provider action.
3. **Use an identifier join, with each tool owning its own state.** Taskwarrior
   UUID, Pueue job ID, queue attempt UUID, workspace UUID, and agent conversation
   ID identify different things. The board joins task, attempt, and workspace
   records without adding a database. Carry those identities through new
   commands and report missing or stale links as data. Imported issue titles,
   status, and dates remain owned by Linear.
4. **Reduce duplicated completion and refresh paths.** Codex completion
   events and the generic filesystem observer use one review refresh runner.
   Manual refresh remains available. Prefer a native completion event when a
   provider exposes one. Measure event volume and repaint cost on a large
   worktree before enabling another watcher.
5. **Keep PR watching resumable.** `gh-pr-state` already checks structured
   PR data and supports bounded watch runs. Installed GitHub CLI 2.104.0
   rejects the top-level `gh event` command. The
   [2.105.0 release](https://github.com/cli/cli/releases/tag/v2.105.0) adds it
   as an account-gated preview. A read-only subscription listing with that
   release returned HTTP 403 because the tested account lacked access. Once
   available, use it to wake a fresh state read and retain polling to cover
   gaps in event delivery.
6. **Keep policy small and dependency direction clear.** The harness registry,
   managed skills, and MCP routing already have distinct ownership. Put launch
   capabilities in the registry, stable rules in generated instructions, and
   repeatable procedures in skills. Keep hooks at the native event boundary.
   Review overlapping skills and wrappers against their actual callers before
   retiring them. Generated shell and editor files remain build output.

## Checks that make these boundaries durable

- Require one machine-readable result on stdout for noninteractive reads.
  Send diagnostics to stderr and use a stable exit status for unavailable inputs.
- Exercise the provider contract through its consumer. The remote picker tests
  cover address fallback and native attachment plans. The board tests verify
  projection and exact identifier joins.
- Verify both the pinned source and the active generation after Darwin switches.
  Record the affected user flow separately from successful Nix evaluation.
- Prefer tests around the command contract, legacy records, and cancellation.
  Keep Go, Lua, and shell fixtures where they exercise those runtimes directly.

See [review tools](review-tools.md), [agent workspaces](agent-workspaces.md),
[Taskwarrior board](task-board.md),
[terminal and execution workflows](../modules/home/programs/llm/skills/local-workflows/references/execution-and-terminals.md),
and [the repository reference](repository-reference.md).
