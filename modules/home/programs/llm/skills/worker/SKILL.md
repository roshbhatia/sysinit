---
description: Owner documentation for `worker`. This is NOT a rendered skill; skills/default.nix excludes this directory from the registry.
---

> `worker` is an owner command, not an agent skill. It is on the owner's PATH
> through `skill-tools.nix`, which wraps `utils worker`. Nothing renders this
> file into a harness skill directory, and there is no `allowed-tools` grant.
> An agent that types `worker` gets its allowlist default, not a pre-approval.
> The defect this removes was never the pane. It was an agent opening one.

`worker` sends a command to ONE reusable WezTerm pane and reports the result.
It exists for two reasons. A long or noisy command belongs somewhere other
than the conversation pane, and creating a pane per command leaves a trail of
them.

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
worker -b 600 'claude -p "..."'        # like -w, and returns 76 if the run asks
                                       # for input instead of finishing
worker --status                        # which pane, and what is running in it
worker --release build                 # free a name a killed pane left in flight
worker --close                         # close the worker pane
```

`-w` is the common case: one call instead of run, sleep, then read.

`-b` is for running a harness in the pane. It is `-w` plus a third outcome,
which is why it is a separate flag. `-w` returns the command's own status or
75, and a caller branching on `$?` must never read a blocked run as a build
result.

The command runs in the directory you called from, checked twice: once here and
once in the pane. A directory that disappears while the run waits in the pane's
input buffer stops the run with exit 78. It never runs somewhere else.

## Reading the result

- The exit status of `worker -w` IS the command's status, so branch on it directly.
- Exit 75 means the wait timed out and the command is still running. The message
  names the `.rc` file to poll. It is not a failure of the command.
- Exit 76 comes back from `-b` alone, and means your run asked for input. The line
  names the run, the reason, and the tail it is waiting at. An exit always wins
  over a block, so a run that asked for input and then finished returns its own
  status.
- Artifacts live one directory down, under a key derived from the workspace.
  `$XDG_STATE_HOME/agents/worker/<key>/` holds `<name>.log`, `<name>.rc`, and
  `last.log` / `last.rc` for the most recent run. `watch worker` finds them from a
  directory, so you rarely type the key.
- Every pane in one workspace shares one worker and one namespace of run names.
  A name is claimed by creating its log exclusively, not by a counter. Two runs
  still never share a log. A name whose run has recorded no exit code is
  refused, and the refusal names the `.rc` file to wait for.
- `last` cannot name a run. It is the alias for the most recent one.

## Freeing a name

A run ends by writing its exit code from a trap, so an interrupted command frees
its own name. `--release NAME` is for what the trap cannot reach, such as a killed
pane.

- A finished or never-started name is released without argument.
- A name the worker is running now is refused. Wait for it, or `--close`.
- A name with no exit code, no running marker, and a live worker pane is
  undecidable. It is queued behind another run, or it was abandoned. That is
  refused by default and released by `--release NAME --force`, which breaks the run
  if it was merely queued.

## What it guarantees

- One pane per workspace. It reuses the recorded pane while `wezterm cli list`
  still reports it AND the record was written by this mux generation. A record
  from an earlier generation is replaced. Pane ids restart at 0 when the mux
  restarts, so an old id can match an unrelated new pane. So the pane is recreated
  when the owner closed it, when WezTerm restarted, and when the record cannot be
  vouched for.
- It never adopts the caller's own pane, which would race the caller's shell.
- Focus returns to the calling pane after a split, so the owner is not yanked out
  of the conversation.
- The command goes to a script file, not into the sent keystrokes. A quote, a
  newline, or a glob cannot change meaning in transit.
- The pane's input line is cleared before typing. Without that, one stray
  keystroke sitting in the buffer prefixes the command and it silently does not
  run.

## Blocked runs

A run says it is blocked; nothing infers it. The only thing that says so is a
harness running inside the pane, whose hooks call `agent-state` already. A
build, a switch, or a test suite declares nothing. The ordinary case reads as
running, and `-b` holds until its timeout, exactly as before.

- `--status` reports `waiting` only while the running marker names the run. A
  harness you started in the pane by hand is never reported as a run of this
  command.
- The same word reaches the pane record and the WezTerm user var. So the status
  line, the tab title, the switcher, the session tree, and `agent-sessions.sh`
  all agree with `--status` about that pane. A pane carrying a state var is also
  exempt from notification, so publishing is what silences it.
- The run's trap clears it by writing `idle`, on an ordinary exit and on Ctrl-C
  alike. It writes only when a record exists. Writing one where there was none
  would put a row for the worker pane on all five surfaces.
- `--close` removes the record itself. The var goes with the pane.

One blocked harness holds the workspace's only worker for as long as it waits, and
every other run there is then refused by name. Give it a worker of its own with
`SYSINIT_WORKER_SESSION` when that matters.

## State that does not accumulate

Each run removes its own body once its exit code is recorded, and a `start` prunes
records whose worker pane is gone. What it never touches:

- A record whose worker pane is alive, whatever the key says. Liveness is read from
  the recorded pane, not from the key, so a worker outlives the pane that made it.
- A record whose allocation lock is held, and a record `--close` has already
  forgotten: its logs are what the close message pointed you at.
- A worker keyed by `SYSINIT_WORKER_SESSION`, and anything at the root that is not
  a current-shape record. Both are reported as a count rather than deleted.
- Anything at all, when `wezterm cli` cannot answer. The report line says so
  instead.

Logs are not rotated. Roughly 163 KB and 8 files a day per record, measured over
five days of one owner's use.

## Notes

- Requires a GUI WezTerm pane: it refuses outside one rather than guessing. A
  mux server or a unix domain has no `gui-sock-<n>` socket, so no record there
  can be written or matched. The refusal quotes the socket it found.
- A second call while the pane is busy is queued by the pane's shell, and the
  output says what it is queued behind.
- The pane runs your interactive shell, so a command that calls `exit` cannot kill
  the worker: each run is a subshell.
- `--status` names the run that is executing, claimed by that run and not by
  the sender. A queued run cannot make the pane read as idle.
- `SYSINIT_WORKER_SESSION=<name>` gives one caller a worker of its own, keyed on
  that name instead of on the workspace. `watch worker` honours it too.
- The first run after the rename may say that a worker from the superseded script
  still holds a pane. That pane is left running and is neither adopted nor killed,
  because its record carries no mux generation to confirm it. Close it yourself
  when you are done watching it. The superseded root is then removed whole by the
  next prune, so the message fires at most until you deal with the pane.
