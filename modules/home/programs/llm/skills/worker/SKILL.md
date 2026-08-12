---
description: Owner documentation for `worker`. This is NOT a rendered skill; skills/default.nix excludes this directory from the registry.
---

> `worker` is an owner command, not an agent skill. It is on the owner's PATH
> through `skill-tools.nix`, which wraps `sysinit-agent worker`. Nothing renders
> this file into a harness skill directory, and there is no `allowed-tools`
> grant, so an agent that types `worker` gets whatever its allowlist default is
> rather than a pre-approval. The defect this removes was never the pane. It was
> an agent opening one.

`worker` sends a command to ONE reusable WezTerm pane and reports the result. It
exists for two reasons: a long or noisy command belongs somewhere other than the
conversation pane, and creating a pane per command leaves a trail of them.

It was called `wtrun` and was a bash script. The name and the implementation
changed together, and there is no `wtrun` alias: two names for one thing is what
the rename removes.

## When to use

- A build, a `nh darwin switch`, a test suite, a long `nix` evaluation: anything
  whose output is long enough to bury the conversation.
- A command that should keep running while you do something else. Start it without
  `-w`, then read its `.rc` file later.
- Anything the owner may want to watch happen, rather than read a summary of.

Do NOT use it for a short command. The pane costs a round trip and the output is
easier to act on inline.

```bash
# good — a long build, blocked on, so the status comes back directly
worker -w 600 'nh darwin build .'

# bad — a one-second command paying a pane round trip
worker -w 60 'git status'
```

## Usage

```bash
worker -w 300 'nix flake check'        # block up to 300s, print the tail, exit with
                                       # the command's own status
worker -w 0  'nh darwin build .'       # block with no timeout
worker 'long-running-thing'            # fire and forget; poll the rc file
worker -n build 'nix build .#foo'      # name the log `build` instead of `runN`
worker -t 40 -w 600 'cargo test'       # 40 lines of tail instead of 20
worker --status                        # which pane, and what is running in it
worker --release build                 # free a name a killed pane left in flight
worker --close                         # close the worker pane
```

`-w` is the common case: one call instead of run, sleep, then read.

The command runs in the directory you called from, checked twice: once here and
once in the pane. A directory that disappears while the run waits in the pane's
input buffer stops the run with exit 78 rather than running it somewhere else.

## Reading the result

- The exit status of `worker -w` IS the command's status, so branch on it directly.
- Exit 75 means the wait timed out and the command is still running. The message
  names the `.rc` file to poll. It is not a failure of the command.
- Artifacts live one directory down, under a key derived from the workspace:
  `$XDG_STATE_HOME/agents/worker/<key>/` holds `<name>.log`, `<name>.rc`, and
  `last.log` / `last.rc` for the most recent run. `watch worker` finds them from a
  directory, so you rarely type the key.
- Every pane in one workspace shares one worker and one namespace of run names, so
  a name is claimed by creating its log exclusively rather than by a counter. Two
  runs still never share a log: a name whose run has recorded no exit code is
  refused, and the refusal names the `.rc` file to wait for.
- `last` cannot name a run. It is the alias for the most recent one.

## Freeing a name

A run ends by writing its exit code from a trap, so an interrupted command frees
its own name. `--release NAME` is for what the trap cannot reach, such as a killed
pane.

- A finished or never-started name is released without argument.
- A name the worker is running now is refused. Wait for it, or `--close`.
- A name with no exit code, no running marker, and a live worker pane is
  undecidable: it is queued behind another run, or it was abandoned. That is
  refused by default and released by `--release NAME --force`, which breaks the run
  if it was merely queued.

## What it guarantees

- One pane per workspace. It reuses the recorded pane while `wezterm cli list`
  still reports it AND the record was written by this mux generation. A record from
  an earlier generation is replaced, because pane ids restart at 0 when the mux
  restarts, so an old id can match an unrelated new pane. So the pane is recreated
  when the owner closed it, when WezTerm restarted, and when the record cannot be
  vouched for.
- It never adopts the caller's own pane, which would race the caller's shell.
- Focus returns to the calling pane after a split, so the owner is not yanked out
  of the conversation.
- The command goes to a script file rather than into the sent keystrokes, so a
  quote, a newline, or a glob cannot change meaning in transit.
- The pane's input line is cleared before typing. Without that, one stray
  keystroke sitting in the buffer prefixes the command and it silently does not
  run.

## Notes

- Requires a GUI WezTerm pane: it refuses outside one rather than guessing. A mux
  server or a unix domain has no `gui-sock-<n>` socket, so no record there can be
  written or matched, and the refusal quotes the socket it found.
- A second call while the pane is busy is queued by the pane's shell, and the
  output says what it is queued behind.
- The pane runs your interactive shell, so a command that calls `exit` cannot kill
  the worker: each run is a subshell.
- `--status` names the run that is executing, claimed by that run rather than by
  the sender, so a queued run cannot make the pane read as idle.
- `SYSINIT_WORKER_SESSION=<name>` gives one caller a worker of its own, keyed on
  that name instead of on the workspace. `watch worker` honours it too.
- The first run after the rename may say that a worker from the superseded script
  still holds a pane. That pane is left running and is neither adopted nor killed,
  because its record carries no mux generation to confirm it. Close it yourself
  when you are done watching it.
