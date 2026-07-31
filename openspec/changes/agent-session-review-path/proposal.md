## Why

A seshy session is easy to create and easy to lose track of. `sy new` scaffolds
it and `sy delete` removes it, with nothing in between that answers the question
the owner actually has: is this session finished?

Conductor frames a finished agent as a diff to review, not as a stopped process,
and ends a workspace deliberately: review, merge, archive. This repository has
every input for that already. The per-pane state bus knows which agents are
still working. Git knows which repositories are dirty or unpushed. Nothing joins
them, so `sy delete` can drop a session that still holds uncommitted work.

## What Changes

- Add `agent-review`, a command that reports one session's readiness: per
  repository, the uncommitted file count, the unpushed commit count, and the
  branch; plus any pane still holding a non-idle agent state.
- Gate `sy delete` on it with a shell wrapper, so a session that is not ready is
  refused and what is unfinished is named. `sy delete --force` still deletes.
  Not seshy's `preDelete` hook: that hook is advisory and cannot veto.
- Surface the same readiness in the notification body's review path, so a done
  toast and the archive gate agree on what "finished" means.

### Non-goals

- Merging, opening a pull request, or any write to a remote. The gate reports
  and refuses; the owner decides.
- Changing `sy new`, `sy add`, or the branch format.
- A graphical workspace list. The surfaces stay the statusline, the notification,
  and the terminal.
- Running tests or a build. Readiness here is git state and agent state, both of
  which are free to read. A check that costs minutes does not belong on a hook.
- Modifying the seshy binary. Everything here is its Nix-managed config plus one
  script in this repository.

## Capabilities

### New Capabilities

- `agent-session-review-path`: the readiness report and the archive gate.

### Modified Capabilities

- `agent-state-emission`: readers currently intersect state files with live pane
  ids. The report needs the same liveness rule stated once, so a stale file
  cannot make a finished session look busy.

## Impact

Modified code:
- `modules/home/programs/zsh/integrations/seshy-wezterm.zsh`
- `modules/home/programs/seshy/config.yaml`

New code:
- `modules/home/programs/llm/config/agent-review.sh`

Dependencies:
- `seshy` becomes a flake input, so `pkgs.seshy` provides the binary the gate
  wraps. It stays out of `home.packages`, because the gate owns the name `sy`.
- Reads the per-pane state bus that `harden-agent-shell-terminal` is versioning.
  The report MUST tolerate a file with no version field, because that change has
  not landed.
- No new package. `git`, `jq`, and `wezterm` are already runtime inputs of the
  notifier scripts.

Impactful and irreversible actions:
- `sy delete` removes a session directory and its worktrees. This change makes
  that path stricter, never looser.
- `nh darwin switch` installs the hook, so the next `sy delete` behaves
  differently.

Gating signal:
- `nix flake check`, then `nh darwin build`, then a dry run of `agent-review`
  against a real session, then `nh darwin switch`. The kill switch is removing
  the `preDelete` entry from `config.yaml`, which restores today's behavior
  without touching the report command.
