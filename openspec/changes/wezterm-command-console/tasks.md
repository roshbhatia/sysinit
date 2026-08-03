## 1. Console runner and wrapper

- **SHAPE** graph

- [ ] 1.1 Write `modules/home/programs/llm/config/agent-console.sh`. Follow the
      helper contract in `modules/home/programs/llm/config/agent-state.sh`: keyed on
      the agent pane id, best-effort, never fails the caller. It polls the spool for
      published job directories, runs each job under `script -q -e -F` with the
      agent's own interpreter, passed in by the guard rather than read from
      `$SHELL` in the console pane, and writes `<job>/rc` atomically. It uses no
      named pipes and does not use `sh -c`. The fail-open path in `agent-run` must
      use the same interpreter, or the same command returns different results
      depending on console health. `deps:` none
- [ ] 1.2 Write `modules/home/programs/llm/config/agent-run.sh`. Follow the same
      contract as `agent-state.sh`. It resolves or creates the console pane, stages
      the job directory under `.staging/`, writes the command and `cwd`, publishes by
      atomic rename into a name carrying a monotonic counter, polls for `<job>/rc`,
      sanitizes the log, and exits with the job's code. Allocate the counter
      atomically, by `O_EXCL` create or `mkdir` of the target name, with retry:
      rename makes publication atomic, not allocation exclusive, and two subagents
      that both read-then-increment nest one job inside the other. `deps:` none
- [ ] 1.3 Keep a detached job on the console pane, and make `agent-run` fall open to
      direct execution while the console is held. Do not run two jobs concurrently on
      one pane: a pty has one foreground process group, so the second job either
      steals Ctrl+C or takes `SIGTTIN` and stops. Signal the hold with a `held`
      marker carrying the holding runner's identity, and add it to the unavailable
      list. A fresh `agent-run` has no memory of the detach and every other signal
      reads healthy. A stale marker must neither trip the breaker nor hold forever.
      `deps:` 1.1
- [ ] 1.4 Claim each job exclusively before running it, by atomic rename into a
      per-runner in-progress directory. A stale heartbeat is evidence, not proof, so
      a stalled runner and its replacement can both poll one spool and run the same
      `nh darwin switch` twice. `deps:` 1.1
- [ ] 1.5 Add the fail-open path to `agent-run.sh`: `exec` the command when
      `WEZTERM_PANE` is unset, `wezterm cli` is unreachable, the split fails, the
      spool write fails, the heartbeat is stale, the instance stamp mismatches, the
      depth marker is set, a live `held` marker exists, or the interpreter is unset
      or unusable. Every wait must be bounded. `deps:` 1.2
- [ ] 1.6 Add the heartbeat to `agent-console.sh` and the staleness check to
      `agent-run.sh`. The heartbeat must keep ticking while a job runs, from a
      background ticker. Pin the interval and the staleness threshold as stated
      values. Liveness is the heartbeat, not `wezterm cli list`. `deps:` 1.1, 1.2
- [ ] 1.7 Run each job in its own process group in `agent-console.sh`, using shell
      job control, and trap `SIGINT` in the runner. Measured: without job control
      the job shares the runner's pgid, so Ctrl+C kills the runner. `deps:` 1.1
- [ ] 1.8 Export the depth marker from `agent-console.sh` into each job's
      environment, and honor it in `agent-run.sh` as an immediate direct execution.
      This is the load-bearing half of the re-entrancy block. `deps:` 1.1, 1.2
- [ ] 1.9 Stamp the `.console` record with the WezTerm instance identity, and
      discard a record whose stamp does not match. WezTerm reuses pane ids after a
      restart. `deps:` 1.2
- [ ] 1.10 Namespace job ids per pane. Validate a `--reap` id against
      `[A-Za-z0-9._-]+`, then resolve the path and confirm containment under the
      calling pane's spool. Directory namespacing alone does not stop `../12/<job>`
      or an absolute path. Include the job id in the detach message. `deps:` 1.2
- [ ] 1.11 Add the `script(1)` capability probe to `agent-console.sh`. Fall back to
      direct execution when the BSD `-q -e -F` flag set is absent, per the
      macOS-versus-Linux risk in `design.md`. `deps:` 1.1
- [ ] 1.12 Add the circuit breaker to `agent-run.sh`. Two consecutive infrastructure
      failures write the breaker flag. Enforce a hard cap of five console-pane
      creations per session, so an alternating success-and-failure sequence cannot
      accumulate orphan panes. `deps:` 1.5
- [ ] 1.13 Add stale-console recovery to `agent-run.sh`. On a stale heartbeat,
      discard the pane id and create a replacement. Never block waiting on a dead
      console. `deps:` 1.6
- [ ] 1.14 Add output sanitization to `agent-run.sh`. Strip ANSI sequences,
      carriage returns, and the leading EOT and backspace bytes that `script(1)`
      writes into its typescript. `deps:` 1.2
- [ ] 1.15 Honor the `${XDG_STATE_HOME:-$HOME/.local/state}/agents/console.disabled` file in
      `agent-run.sh` as an immediate pass-through, read fresh on every invocation.
      `deps:` 1.5
- [ ] 1.16 Add the `SessionEnd` cleanup that removes only this pane's failure
      counter and breaker flag. It must not touch the spool directory or the
      `.console` record: `SessionEnd` fires on `/clear`, and removing them would
      destroy a detached job's log and orphan its console pane. Extend the existing
      `SessionEnd` wiring in `modules/home/programs/llm/config/claude.nix`.
      `deps:` 1.12
- [ ] 1.17 Give `agent-console` its own lifetime. It exits and prunes its spool only
      when its agent pane is confirmed absent from `wezterm cli list`. A query error,
      timeout, or empty result is unknown, not absence, and must not prune: every
      other path fails open on an unreachable `wezterm cli`, and `nh darwin switch`
      replaces that binary mid-rollout. Prune a completed job only after it is reaped
      or a stated minimum retention elapses. `deps:` 1.1
- [ ] 1.18 Stamp every published job with the RUNNER instance identity, and have a
      starting `agent-console` discard jobs that are not its own. Do not scope the
      stamp to the WezTerm instance: closing the console pane forces a replacement
      runner inside the same instance, where a terminal-scoped stamp still matches
      and the stale `git push origin main` still runs. `deps:` 1.9
- [ ] 1.19 Carry the agent's `PATH`, `XDG_STATE_HOME`, and interpreter in the job
      file, and apply them in `agent-console`. The runner is spawned by the WezTerm
      mux and inherits its environment, so a Dock-launched WezTerm gives every nix
      command exit 127 while the console reports itself healthy. Create the spool
      root, pane spools, and job directories `0700` under `umask 077`. `deps:` 1.1, 1.2
- [ ] 1.20 Surface a set kill switch in the statusline, beside the existing
      agent-state chips. The file is global and nothing removes it, so without a
      signal an owner who sets it during an incident disables the console everywhere,
      forever, silently. `deps:` 1.15
- [ ] 1.21 Package both scripts in `modules/home/programs/llm/config/notify.nix` and
      add them to `home.packages` in `modules/home/programs/llm/default.nix`. This
      follows the existing `agent-state` and `agent-notify` packaging, not a new
      pattern. `deps:` 1.1, 1.2
- [ ] 1.22 Format both scripts with `nix fmt`, then confirm with
      `nix fmt -- --check`. `deps:` 1.21
- [ ] 1.23 Adversarial review (`adversarial-review` skill): critics attempt to break
      this slice against its spec scenarios, the design decisions, and the rollout
      gates. Press hardest on whether any `agent-run` failure mode can block a
      command instead of falling through to direct execution. `deps:` 1.22

## 2. Rollout of slice 1

- [ ] 2.1 Verify: `nix flake check` and `nh darwin build` are green. Review
      `git diff`.
- [ ] 2.2 Apply: `nh darwin switch`.
- [ ] 2.3 Confirm: in a WezTerm pane, run `agent-run` on a command that needs the
      nix profile, such as `nh --version` or `rg --version`, not `sleep` or `echo`.
      The console pane appears, focus returns to the original pane, output streams
      live, and the exit code is `0`. A `/bin`-only command passes even when the
      runner has the mux's `PATH`, so it cannot detect the missing-environment bug.
- [ ] 2.4 Confirm: relaunch WezTerm from the Dock, not from a shell, and repeat
      2.3. This is the launchd-`PATH` case, which a terminal-launched WezTerm hides.
- [ ] 2.5 Confirm: the owner spot-checks the bottom split at 35 percent and the
      focus flicker. Measurement in `design.md` predicts both panes keep full width.
- [ ] 2.6 Confirm: run `agent-run` with `WEZTERM_PANE` unset. The command executes
      directly and the exit code is unchanged.
- [ ] 2.7 Confirm: kill the console pane, then run `agent-run` again. It must fall
      back within its bounded wait, not hang. This is the failure the FIFO design
      could not detect.
- [ ] 2.8 Confirm: press Ctrl+C during a job. The job dies, `agent-console`
      survives, and the next job still runs.

## 3. Guard rewrite

- **SHAPE** loop
- **STOP** `nix build .#checks.aarch64-darwin.destructive-guard-fixtures` exits
  0, and the guard fixture run in 3.8 exits 0 with every deny form denied and
  every allowed form carrying an `updatedInput`. Removing any one deny pattern
  must make it fail
- **MAX-ITERS** 3

- [ ] 3.1 Gather: re-read `modules/home/programs/llm/config/claude-bash-guard.sh`
      and the deny patterns it encodes. Confirm the deny set matches
      `openspec/specs/cross-harness-destructive-command-guard/spec.md`.
- [ ] 3.2 Act: extend `claude-bash-guard.sh` so the deny set evaluates first and
      returns before any rewrite code runs.
- [ ] 3.3 Act: add the rewrite branch. Emit `permissionDecision: "allow"` paired
      with `hookSpecificOutput.updatedInput.command` invoking
      `agent-run --cwd-b64 <b64> --cmd-b64 <b64>`. Both values must be
      base64-encoded, and each encoding must be unwrapped with `| tr -d '\n'` as
      `agent-state.sh` already does. GNU `base64` wraps at 76 columns, which is 57
      input bytes, so an unwrapped encoding corrupts most real commands. A trailing
      `-- <original>` form is destructive: Claude's shell re-parses it, and rebuilding
      the string from argv turns a quoted `&&` into a shell operator.
- [ ] 3.4 Act: exempt a bare `cd` from the rewrite. Compound commands containing
      `cd` stay rewritten.
- [ ] 3.5 Act: skip the rewrite when `${XDG_STATE_HOME:-$HOME/.local/state}/agents/console.disabled`
      exists, and emit no `updatedInput` when the rewrite cannot be built.
- [ ] 3.6 Act: skip the rewrite when the command's first word is `agent-run`. This
      prevents an `agent-run --reap` call from nesting and deadlocking the queue.
- [ ] 3.7 Act: skip the rewrite when `tool_input.run_in_background` is true. A
      background process would hold the ordered queue for its lifetime.
- [ ] 3.8 Act: in `modules/home/programs/llm/config/claude.nix`, confirm the Bash
      `PreToolUse` guard entry is synchronous, and set the `SYSINIT_AGENT_CONSOLE`
      stage flag default to `0`. Do not ship the kill-switch file from nix: a
      nix-managed `console.disabled` either survives its own removal or collides
      with the owner's `touch` and blocks activation.
- [ ] 3.9 Verify: test whether `updatedInput` is applied without an accompanying
      `permissionDecision`. If it is, drop the `allow`. Pairing them spends the
      `allow`-tier fallback that `claude.nix` documents as load-bearing if
      `dangerouslySkipPermissions` is ever set to `false`.
- [ ] 3.10 Verify: feed the guard each deny-set form on stdin. Every form still
      returns a deny with no `updatedInput`. Feed it `nh darwin build` and confirm
      the `updatedInput` invokes `agent-run` with base64 arguments. Feed it
      `cd modules/home`, `agent-run --reap <job>`, and a payload with
      `run_in_background` true, and confirm none produces an `updatedInput`. Feed it
      `rg 'foo && rm -rf build' .` and confirm the decoded command is byte-identical
      to the original. Feed it a command longer than 57 bytes and confirm the emitted
      `updatedInput.command` is a single line: GNU `base64` wraps at 76 columns, and
      a wrapped encoding is parsed as two commands. Iterate 3.2 through 3.8 if any
      check fails.
- [ ] 3.11 Adversarial review (`adversarial-review` skill): critics attempt to break
      this slice against its spec scenarios, the design decisions, and the rollout
      gates. Press hardest on whether the deny path can be bypassed by the rewrite
      path under any input.

## 4. Rollout of slice 2

- [ ] 4.1 Verify: `nix flake check` and `nh darwin build` are green. Review
      `git diff`. Re-run the deny-set checks from 3.7 against the built config.
- [ ] 4.2 Apply: `nh darwin switch`.
- [ ] 4.3 Confirm: the owner starts a session with the shipped `SYSINIT_AGENT_CONSOLE`
      default and observes no console pane and no behavior change.
- [ ] 4.4 Confirm: the owner starts a session with `SYSINIT_AGENT_CONSOLE=1`.
      Ordinary commands route to the console. Every deny-set form is still denied.
- [ ] 4.5 Confirm: mid-turn, the owner creates the disable file from a second pane.
      The session's next Bash command runs directly, with no restart. This is the
      only rollback case a real incident produces.
- [ ] 4.6 Confirm: the owner removes the disable file and confirms the next command
      routes to the console again. The kill switch is global and nothing removes it
      automatically, so leaving it set here would silently disable every later gate
      in slices 5 and 6 and make them pass for the wrong reason.

## 5. Detach, reap, and default on

- **SHAPE** graph
- Not a loop: the exit is the owner pressing Ctrl+C in a live pane and watching a
  long build detach and reap. No command observes that, so the phase ends at its
  `Confirm:` tasks instead.
- [ ] 5.1 Gather: measure the real per-command overhead of the console on a trivial
      command, and confirm it is acceptable at every-command scale.
- [ ] 5.2 Act: add the `agent-run` timeout, set below the Bash tool's 120 second
      default. On expiry, return partial output and the console pane id, and leave
      the job running.
- [ ] 5.3 Act: add the `agent-run --reap <job>` invocation that returns a detached
      job's final output and exit code.
- [ ] 5.4 Verify: run a job longer than the timeout. `agent-run` returns partial
      output and names the pane. A later reap returns the final result. Iterate 5.2
      and 5.3 if not.
- [ ] 5.5 Verify: press Ctrl+C in the console during a job. `agent-run` exits
      non-zero and the returned text states that the owner interrupted the command.
- [ ] 5.6 Adversarial review (`adversarial-review` skill): critics attempt to break
      this slice against its spec scenarios, the design decisions, and the rollout
      gates.

## 6. Rollout of slice 3

- [ ] 6.1 Verify: `nix flake check` and `nh darwin build` are green. Review
      `git diff`. Confirm slices 1 and 2 are still working.
- [ ] 6.2 Apply: flip the `SYSINIT_AGENT_CONSOLE` stage flag default to `1` in
      `claude.nix`, then run `nh darwin switch`.
- [ ] 6.3 Confirm: the owner runs a full working session. A long build detaches and
      reaps. Ctrl+C returns a non-zero code. A bare `cd` still moves the agent's
      working directory.
- [ ] 6.4 Confirm: quit and relaunch WezTerm so pane ids are reassigned, then start
      a session. Confirm `agent-run` does not adopt an unrelated pane holding a
      recycled id.
- [ ] 6.5 Confirm: queue a job, kill WezTerm before it completes, relaunch so the
      pane id is reused, and start a session. Confirm the stale job is discarded and
      does not execute. Use a harmless marker command, never a `git push`.
- [ ] 6.6 Confirm: run `/clear` five times in one agent pane. Confirm exactly one
      console pane exists afterward, and that the agent pane has not been shrunk by
      repeated splits.
- [ ] 6.7 Confirm: detach a long job, then run `/clear`. Confirm the job keeps
      running, its log survives, and a later reap in that pane resolves the job id.
- [ ] 6.8 Confirm: the owner verifies the mid-session rollback path last, after
      every other gate. Create the kill-switch file from a second pane during a live
      turn, confirm the next Bash command runs with no console pane and no restart,
      then remove the file and confirm the console returns. This runs last because
      leaving it set would invalidate every gate after it.
- [ ] 6.9 Update `design.md` with the resolved values for the remaining open
      questions: whether background Bash gets its own pane, and whether the single
      ordered queue is a bottleneck under subagent-heavy turns.
