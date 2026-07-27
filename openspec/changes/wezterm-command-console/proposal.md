## Why

Agent panes show that an agent is working, but not what its commands are doing.
`modules/home/programs/llm/config/agent-state.sh` publishes status, reason, and
elapsed time, so a chip can say `working: Bash: nix flake check`. It cannot show the
build output. The owner reads command output inline in the agent transcript, after
the fact.

This change mirrors every agent Bash command into a dedicated WezTerm pane, live,
while the agent still receives the exact output and exit code.

An execution-site design was specified first, where a runner process owned a console
pane and the agent submitted jobs to it. An adversarial review raised 52 objections
against it, of which 50 were upheld. The failures were not incidental. They came
from moving execution out of the agent's own shell: a second process needs identity,
liveness, exclusive job claiming, environment transport, and pty ownership, and each
of those introduced its own defect. That design is rejected. See `design.md`.

The mirror design keeps execution exactly where it is today. The pane is a copy.

## What Changes

- Add `agent-mirror-begin`: a best-effort helper that ensures a mirror pane exists
  for the calling agent pane and writes a header line for the command about to run.
- Extend the existing Bash `PreToolUse` guard so one script owns the Bash decision.
  It keeps the current deny set unchanged. When it does not deny, it returns
  `updatedInput` that wraps the command so its combined output is copied to a
  per-pane log while still reaching the agent.
- Add a mirror pane that tails that log, created as a bottom split so both panes
  keep the window's full width.
- Add a kill switch file that the guard and the helper read fresh on every command,
  so it takes effect in an already-running session.

Reused patterns:

- `modules/home/programs/llm/config/agent-state.sh` sets the helper contract:
  agent-agnostic, keyed on `$WEZTERM_PANE`, best-effort, always exit 0. It also
  already encodes payloads with `base64 | tr -d '\n'`, which this change reuses.
- `modules/home/programs/llm/config/notify.nix` already packages the `agent-*`
  scripts into `home.packages`. The new script joins it.
- `modules/home/programs/llm/config/claude-bash-guard.sh` already parses the
  `PreToolUse` event and emits `hookSpecificOutput`. The rewrite extends it.
- `~/.local/state/agents/` is the established state root.

### Non-goals

- Interrupting a command from the mirror pane. The command runs in the agent's own
  shell, so the pane is a copy and Ctrl+C in it does nothing to the command.
- Answering a command that prompts. Same reason.
- Running commands in the pane. That was the rejected execution-site design.
- Consoling tools other than Bash.
- Consoling Bash calls that set `run_in_background`. A long-lived background process
  would interleave with foreground commands in one shared log.
- Wiring harnesses other than Claude. The helper is agent-agnostic by construction,
  but only Claude is wired here.
- Changing the deny set in `lib/allowlist.nix`.

## Capabilities

### New Capabilities

- `agent-command-mirror`: a per-pane WezTerm pane that shows every agent Bash
  command and its output live, without changing where or how the command runs.

### Modified Capabilities

- `claude-destructive-command-guard`: the Bash `PreToolUse` script becomes the single
  decision point for the Bash tool. It keeps every existing deny. It gains a second
  responsibility: when it does not deny, it returns `updatedInput` that wraps the
  command for mirroring.

## Impact

Modified code:

- `modules/home/programs/llm/config/notify.nix`
- `modules/home/programs/llm/config/claude-bash-guard.sh`
- `modules/home/programs/llm/config/claude.nix`
- `modules/home/programs/llm/default.nix`

New code:

- `modules/home/programs/llm/config/agent-mirror-begin.sh`

Dependencies: none new. `wezterm` provides `wezterm cli`. `tee`, `base64`, and
`tail` are already present.

Impactful and irreversible actions:

- `nh darwin switch` applies the hook change to the live system. Every subsequent
  agent Bash call is wrapped. This needs owner confirmation.
- Editing `claude-bash-guard.sh` touches the destructive-command deny path. The deny
  set must be re-verified after the edit.
- The rewrite changes the text of every Bash command. A defect in the wrap corrupts
  commands rather than merely failing to mirror them. Measured: a same-line wrap of
  a command with a trailing `#` comment is a parse error, so the wrap must be
  newline-delimited.

Progressive rollout: three independently verifiable slices. Slice one lands
`agent-mirror-begin` with no hook wiring, exercised by hand. Slice two adds the
guard rewrite behind a stage flag defaulting off. Slice three flips the default on.

Gating signal: two separate controls, deliberately not the same mechanism.

- `SYSINIT_AGENT_MIRROR` is the staged-rollout flag written by `claude.nix`, read at
  session start.
- The kill switch is the file
  `${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror.disabled`. The owner creates
  it. Nix never manages it, so it cannot collide with a managed path and block a
  later activation. The guard and the helper read it fresh on every command.
