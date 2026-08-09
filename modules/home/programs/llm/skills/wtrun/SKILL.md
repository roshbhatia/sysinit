---
description: Owner documentation for `wtrun`. This is NOT a rendered skill; skills/default.nix excludes this directory from the registry.
---

> `wtrun` is an owner command, not an agent skill. It is on the owner's PATH
> through `skill-tools.nix`, which reads `wtrun.sh` directly. Nothing renders
> this file into a harness skill directory, and there is no `allowed-tools`
> grant, so an agent that types `wtrun` gets whatever its allowlist default is
> rather than a pre-approval. The defect this removes was never the pane. It was
> an agent opening one.

`wtrun` sends a command to ONE reusable WezTerm pane and reports the result. It
exists for two reasons: a long or noisy command belongs somewhere other than the
conversation pane, and creating a pane per command leaves a trail of them.

## When to use

- A build, a `nh darwin switch`, a test suite, a long `nix` evaluation: anything
  whose output is long enough to bury the conversation.
- A command that should keep running while you do something else. Start it without
  `-w`, then read its `.rc` file later.
- Anything the owner may want to watch happen, rather than read a summary of.

Do NOT use it for a short command. The pane costs a round trip and the output is
easier to act on inline.

## Usage

```bash
wtrun -w 300 'nix flake check'        # block up to 300s, print the tail, exit with
                                      # the command's own status
wtrun -w 0  'nh darwin build .'       # block with no timeout
wtrun 'long-running-thing'            # fire and forget; poll the rc file
wtrun -n build 'nix build .#foo'      # name the log `build` instead of `runN`
wtrun -t 40 -w 600 'cargo test'       # 40 lines of tail instead of 20
wtrun --status                        # which pane, and what is running in it
wtrun --close                         # close the worker pane
```

`-w` is the common case: one call instead of run, sleep, then read.

## Reading the result

- The exit status of `wtrun -w` IS the command's status, so branch on it directly.
- Exit 75 means the wait timed out and the command is still running. The message
  names the `.rc` file to poll. It is not a failure of the command.
- Artifacts live in `$XDG_STATE_HOME/agents/wtrun/`: `<name>.log`, `<name>.rc`,
  and `last.log` / `last.rc` for the most recent run.
- Run ids are monotonic, so two runs never share a log.

## What it guarantees

- One pane. It reuses the recorded pane while `wezterm cli list` still reports it,
  and recreates it only if the owner closed it.
- It never adopts the caller's own pane, which would race the caller's shell.
- Focus returns to the calling pane after a split, so the owner is not yanked out
  of the conversation.
- The command goes to a script file rather than into the sent keystrokes, so a
  quote, a newline, or a glob cannot change meaning in transit.
- The pane's input line is cleared before typing. Without that, one stray
  keystroke sitting in the buffer prefixes the command and it silently does not
  run.

## Notes

- Requires a WezTerm pane: it refuses outside one rather than guessing.
- A second call while the pane is busy is queued by the pane's shell, and the
  output says what it is queued behind.
- The pane runs your interactive shell, so a command that calls `exit` cannot kill
  the worker: each run is a subshell.
- `--status` names the run that is executing, claimed by that run rather than by
  the sender, so a queued run cannot make the pane read as idle.
