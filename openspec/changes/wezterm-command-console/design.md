## Context

Agent panes already publish lifecycle state. `modules/home/programs/llm/config/agent-state.sh`
emits an OSC 1337 `SetUserVar` and writes `~/.local/state/agents/panes/<pane>.json`.
`modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` reads both and renders session
chips. The owner can see that an agent is working. The owner cannot see its output.

`wezterm cli` already provides `split-pane`, `activate-pane`, `list`, and
`kill-pane`. Nothing new is needed at the terminal layer.

Patterns this change extends:

- `modules/home/programs/llm/config/agent-state.sh` sets the helper contract:
  agent-agnostic, keyed on `$WEZTERM_PANE`, best-effort, always exit 0. Its
  `base64 | tr -d '\n'` idiom is reused directly.
- `modules/home/programs/llm/config/notify.nix` and
  `modules/home/programs/llm/default.nix` already package and install the `agent-*`
  scripts.
- `modules/home/programs/llm/config/claude-bash-guard.sh` already reads the
  `PreToolUse` event and emits `hookSpecificOutput`.

Constraints, all verified rather than assumed:

- No hook event observes a tool mid-execution. `PreToolUse`, `PostToolUse`, and
  `PostToolUseFailure` all fire after their phase completes. Live output therefore
  requires rewriting the command; there is no hook-only path to it.
- Claude Code applies `updatedInput` only from a synchronous `PreToolUse` hook.
- Claude Code documents no precedence rule when two matching hooks return
  conflicting `permissionDecision` values.
- The Bash tool's shell is zsh on this host, not bash.
- The Bash tool already does not persist environment variables between calls.
  Working directory does persist.

## Goals / Non-Goals

Goals:

- Show every agent Bash command and its output live in a dedicated pane.
- Leave execution exactly where it is today, in the agent's own shell.
- Return the exact exit code to the agent.
- Never let a mirror failure change what a command does or whether it runs.

Non-Goals:

- Interrupting or answering a command from the mirror pane.
- Running commands anywhere other than the agent's own shell.
- Consoling non-Bash tools, background Bash calls, or harnesses other than Claude.

## Decisions

- Decision: The pane mirrors a command that runs in the agent's own shell. It is not
  an execution site.
  - Alternative rejected: a runner process owning a console pane, with the agent
    submitting jobs to a spool. This was specified in full and then reviewed
    adversarially: 52 objections, 50 upheld, including duplicate execution of
    `nh darwin switch` from a false staleness reading, an argv round trip that turned
    `rg 'foo && rm -rf build' .` into an executed `rm -rf`, and a base64 wrap that
    corrupted every command over 57 bytes. The failures traced to one root cause:
    moving execution out of the agent's shell forces a second process to reproduce
    identity, liveness, exclusive claiming, environment, and pty ownership. The
    mirror needs none of those. It costs the ability to Ctrl+C or answer a prompt
    from the pane.

- Decision: The command runs under `script(1)`, which gives it a real pty, and its
  text reaches `script` as a single argument via a base64 decode into a shell
  variable:

  ```
  agent-mirror-begin '<b64>' || true
  __mc=$(printf %s '<b64>' | base64 -d)
  if [ -n "$__mc" ]; then
  script -q -e -F '<log>' '<shell>' -c "$__mc" | agent-mirror-strip
  (exit ${pipestatus[1]})
  else
  <original>
  fi
  ```

  Verified end to end: exit 7 propagated, `[ -t 1 ]` reported a tty, `\033[32m`
  survived, stderr was captured, a trailing `# comment` did not break the wrap, and
  there was no prompt noise.
  - Alternative rejected: `{ <original> ; } 2>&1 | tee -a '<log>'`. Simpler and it
    keeps the text fully verbatim, but a pipe is not a tty so colour is lost, and
    that loss is not recoverable. Measured with ripgrep: unforced through a pipe
    gave 0 escape bytes; with `CLICOLOR_FORCE=1 FORCE_COLOR=1` still 0; under a pty
    via `script`, 14. Since the mirror exists to watch build output, losing colour
    defeats the purpose, and the wrapper cannot add `--color=always` to the owner's
    command.
  - Alternative rejected: reconstruct the command from argv, as the rejected
    execution-site design did. That is the round trip that turned
    `rg 'foo && rm -rf build' .` into an executed `rm -rf`. Decoding into a shell
    variable and passing `"$__mc"` as one argument never splits the text.
  - Alternative rejected: feed the command to `script` over a heredoc, so no
    encoding is needed. Verified broken: `script` then runs an interactive shell,
    which echoes the input, writes its full prompt and OSC user-vars into the
    capture, and loses the exit code entirely, reporting 0 for a command that
    exited 7. This is the prompt-noise failure of the rejected design.
  - Alternative rejected: single-line wrapping of any form. Verified a parse error:
    `{ echo hi # note ; }` comments out the closing brace. All emitted lines are
    newline-delimited.

- Decision: A failed or empty decode falls back to running the original command
  verbatim, inline, in the `else` branch.
  - Alternative rejected: run `"$__mc"` unconditionally. An empty variable means
    `<shell> -c ""`, which runs nothing and exits 0, so a command would be silently
    skipped and reported as successful. That is the worst available failure shape.

- Decision: The mirror pane receives the raw pty stream, and the agent receives a
  stripped copy through `agent-mirror-strip`.
  - Alternative rejected: give the agent the raw pty stream too. `script` writes a
    leading EOT and backspaces plus carriage returns and every colour sequence;
    handing that to the agent wastes context and breaks output matching.
  - Alternative rejected: send `script` output only to the log and have the agent
    read it back. With concurrent subagent calls appending to one log there is no
    safe offset to read from.

- Decision: The asciicast route is rejected.
  - Alternative rejected: record with `wezterm record` and show the mirror with
    `wezterm replay`. Verified twice broken. `wezterm record` needs a controlling
    tty and fails in a hook subprocess with `Device not configured (os error 6)`;
    the Bash tool's `tty` reports `not a tty`. And `wezterm replay` is not
    live-following: with timing a six-minute build takes six minutes to replay, and
    `--cat` dumps everything only once the command has finished. `script` gives the
    same pty fidelity while streaming.

- Decision: Exit code is restored with `(exit ${pipestatus[1]})` in a subshell.
  - Alternative rejected: a bare `exit`, which would terminate the agent's
    persistent shell. Verified that the subshell form yields `rc=7` for a command
    that exited 7 without killing the shell.
  - Alternative rejected: process substitution, `> >(tee ...)`. Verified broken in
    zsh: it swallowed the following statement entirely and double-wrote the log.

- Decision: The guard emits the `pipestatus` form matching the agent's shell, and
  emits no rewrite when it cannot determine that shell.
  - Alternative rejected: hardcode one form. zsh uses `pipestatus`, 1-indexed;
    bash uses `PIPESTATUS`, 0-indexed. A mismatch silently reports the wrong exit
    code, which is worse than not mirroring.

- Decision: A `tee` failure is tolerated and not guarded against.
  - Alternative rejected: pre-checking that the log path is writable. Verified
    unnecessary: with an unwritable path, `tee` printed an error, the command still
    ran, its output still reached stdout, and the command's own status was still
    `0`. The failure mode is already soft.

- Decision: The mirror pane is a bottom split at 35 percent. `agent-mirror-begin`
  runs `wezterm cli activate-pane` on the agent pane immediately after creating it.
  - Alternative rejected: a right split. Measured on a 100 column window: bottom
    gives 100x56 and 100x30, so both keep full width; right at 40 percent would cut
    the agent pane to 60 columns.
  - Alternative rejected: `wezterm cli spawn --new-window`. It leaves the agent
    pane's geometry untouched, but lands in workspace `default`, so it is not on
    screen with an agent running in a seshy session workspace. Passing `--workspace`
    is worse: measured that it creates a workspace, which `ui.lua` renders as a
    seshy session chip, so every mirror would appear as a fake session.

- Decision: The pane id returned by `wezterm cli` is parsed as the last line,
  digits only.
  - Alternative rejected: taking the whole stdout. Measured contamination: a spawn
    returned `18:16:08.199 INFO logging > lua: [agent-deck] Plugin applied to
    config` followed by `36`. A naive capture feeds that string to the next
    `wezterm cli` call, which then fails silently.

- Decision: Pane resolution is extracted into a sourceable `agent-pane.sh` that
  both `agent-run.sh` and the session worker share. It resolves or creates a pane,
  records its id, confirms liveness against `wezterm cli list`, parses the id as
  digits on the last line, and recreates the pane when the owner has closed it.
  Nothing else moves: the spool, the heartbeat, the instance stamp, the circuit
  breaker, and job claiming are `agent-run`'s, because only it routes every
  command and must fail open.
  - Alternative rejected: folding the session worker into `agent-run`. They give
    different guarantees. `agent-run` is a per-command router that must preserve
    ordering, block re-entrancy, and fall through to direct execution on any
    failure. The worker is a deliberate dispatcher for one long command, where
    blocking is the point and there is nothing to fail open to. One mechanism
    serving both would carry the router's spool and breaker for a case that wants
    neither.
  - Alternative rejected: leaving two independent pane creators. Both parse the id
    out of contaminated `wezterm cli` stdout, both keep a pane id across restarts,
    and both must decide what "still alive" means. That is the same 20 lines twice,
    and the second copy is where a plugin log line silently poisons the id.

- Decision: The rewrite lives inside `claude-bash-guard.sh`, not in a second
  `PreToolUse` Bash matcher.
  - Alternative rejected: a separate hook script. Claude Code runs matching hooks in
    parallel and documents no conflict-resolution rule, so a rewrite hook returning
    `allow` could race the guard's `deny`.

- Decision: A bare `cd` is exempt from the rewrite.
  - Alternative rejected: wrapping it like everything else. Verified that `cd` does
    not survive the pipeline subshell: after `{ cd /; } | tee`, the shell's cwd was
    unchanged. The Bash tool tracks cwd in its own shell, so a wrapped `cd` would
    silently do nothing. Compound forms such as `cd x && make` are still wrapped,
    because subshell scoping is already their correct behavior.

- Decision: The command's header is passed to `agent-mirror-begin` base64-encoded
  with newlines stripped.
  - Alternative rejected: unwrapped `base64`. Measured: GNU `base64` from the nix
    profile wraps at 76 columns, so a 66-byte command encoded to two lines. The
    header is the only place an encoding is needed, and `agent-state.sh` already
    uses `base64 | tr -d '\n'`.

- Decision: The kill switch and the rollout stage are separate mechanisms. The kill
  switch is a file the owner creates and nix never manages. The stage is the
  `SYSINIT_AGENT_MIRROR` default in `claude.nix`.
  - Alternative rejected: one environment variable for both. An environment variable
    cannot be changed in a running process, so it cannot stop a misbehaving mirror
    mid-session.
  - Alternative rejected: one file for both. A nix-shipped file either survives its
    own removal, making the stage flip a silent no-op, or collides with the owner's
    `touch` and aborts the next activation.

## Rollout & Gating

Two controls. The kill switch is
`${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror.disabled`, created by the owner
from any pane, read fresh on every command:

```
touch "${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror.disabled"
```

The rollout stage is the `SYSINIT_AGENT_MIRROR` default in `claude.nix`.

Three slices, each running edit, `nix flake check`, `nh darwin build`, owner
spot-check, `nh darwin switch`.

1. Helper only. Add `agent-mirror-begin`, package it, no hook wiring. Gate: the
   owner runs it by hand and confirms the mirror pane appears, focus returns, and a
   piped command's output shows up in it.
2. Rewrite behind the stage flag, defaulting off. Gate: the owner confirms the deny
   set still denies, then runs a session with the flag set and confirms commands
   mirror and exit codes are correct.
3. Stage on. Gate: a full working session, then the kill-switch test LAST, including
   removing the file afterwards.

Rollback: create the kill-switch file for immediate effect, then revert and
`nh darwin switch`, then remove the kill-switch file. The last step is mandatory and
easy to skip, because by then the mirror is already gone. The file is not
nix-managed, so the revert does not remove it, and a latched file silently
pre-disables any future re-land.

## Risks / Trade-offs

- [A wrap defect corrupts commands rather than merely failing to mirror] -> The wrap
  is newline-delimited, verified against a trailing `#` and a trailing `&`. Slice 2's
  gate feeds the guard a set of adversarial command shapes and diffs the decoded
  result against the original. This is a human-verification checkpoint.

- [The exit code is reported wrongly] -> `(exit ${pipestatus[1]})` verified to return
  7 without killing the shell. The guard emits the form matching the detected shell
  and emits no rewrite when the shell is unknown. Slice 2's gate checks a non-zero
  exit explicitly.

- [`script` merges stderr into stdout on the pty, so the agent loses stream
  separation] -> Accepted. The merge is what makes the mirror show output in the
  order it actually happened. Verified that stderr is captured.

- [The strip filter could swallow output] -> `agent-mirror-strip` falls back to
  passing its input through unchanged on any internal failure. Losing colour codes
  is acceptable; losing output is not.

- [`base64 -d` behaviour differs between GNU and BSD] -> The encode side already
  strips newlines with `tr -d '\n'`, matching `agent-state.sh`. The decode is
  guarded by the non-empty check, and slice 2's gate diffs the decoded text against
  the original byte for byte.

- [Concurrent subagent Bash calls interleave in one log] -> Accepted at line
  granularity. Each command writes a header first, so a reader can attribute output.
  Unlike the rejected design, interleaving costs readability only; no command is
  delayed, dropped, or run twice.

- [The log grows without bound] -> `agent-mirror-begin` truncates the log when it
  exceeds a stated size, and the pane's `tail -F` follows the truncation.

- [The mirror pane steals focus on creation] -> `activate-pane` on the agent pane
  runs immediately after the split. A brief flicker remains on the first command.
  This is a human-verification checkpoint.

- [A latched kill-switch file disables the mirror silently and permanently] -> The
  slice 3 gate removes it explicitly, and a set kill switch is surfaced in the
  statusline beside the existing agent-state chips.

## Migration Plan

Slice 1, helper only:

1. Verify: `nix flake check` and `nh darwin build` pass.
2. Apply: `nh darwin switch`. Mutates the live system; needs owner confirmation.
3. Confirm: run `agent-mirror-begin` by hand, then a piped command. The mirror pane
   appears as a bottom split, focus returns to the original pane, and output arrives.

Slice 2, rewrite behind the stage flag:

1. Verify: `nix flake check` and `nh darwin build` pass.
2. Verify: the guard still denies every form in the deny set, checked against the
   built config. This must pass before the switch.
3. Apply: `nh darwin switch`. Owner confirmation required.
4. Confirm: with the stage flag set, commands mirror, exit codes are correct
   including non-zero, and a bare `cd` still moves the agent's directory.

Slice 3, stage on:

1. Verify: `nix flake check` and `nh darwin build` pass.
2. Apply: `nh darwin switch`. Owner confirmation required.
3. Confirm: a full working session, including a long build.
4. Confirm: LAST, create the kill-switch file mid-turn, confirm the next command is
   unwrapped, then REMOVE the file and confirm the mirror returns. Running this
   earlier would leave the switch latched and make every later gate pass for the
   wrong reason.

## Adversarial Review

The rubric is the spec scenarios in `specs/agent-command-mirror/spec.md` and
`specs/claude-destructive-command-guard/spec.md`, including every scenario marked
`- **POLARITY** negative`, plus the `Decisions` above, the gates in
`Rollout & Gating`, and the `Non-goals` in `proposal.md`.

`specutil check` is mandatory and runs on every slice. The LLM critic loop is
default-on and owner-gated per the `adversarial-review` skill; a waiver is recorded
as `Adversarial review: waived by owner`. Critics are in-process teammates under
Claude Code.

The rejected execution-site design already absorbed four rounds of this loop. Its
findings are the reason most of the Decisions above cite a measurement. Critics
should press hardest on the wrap: whether any command shape breaks it, and whether
any failure of `agent-mirror-begin` or `tee` can change what the command does.

## Open Questions

- Does `updatedInput` work without an accompanying `permissionDecision`? The plan
  pairs them because the documentation shows them together. That pairing spends the
  `allow`-tier fallback that `claude.nix` keeps as intent documentation. Slice 2 must
  test the unpaired form and drop the `allow` if it works.
- What log size should trigger truncation, and should the pane show a marker when it
  happens?
- Should a failed `agent-mirror-begin` be surfaced, or stay silent? It is best-effort
  by contract, so a broken mirror currently looks the same as a disabled one.
