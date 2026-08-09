# zmx, probed rather than read about

Task 10.1. Every claim here came from running the binary, in the shape task 3.1
set for hunk. zmx is the only other third-party dependency this change adds.

Probed at `zmx 0.6.0`, the version in this repository's pinned nixpkgs, built
with `nix build nixpkgs#zmx`. `zmx --version` also reports the vendored terminal
emulator it links, `ghostty-1.3.2-dev`.

## The environment variables it names

From `zmx --help`, which lists them explicitly:

| Variable | What zmx does with it |
|---|---|
| `SHELL` | the shell a new session spawns |
| `ZMX_DIR` | socket directory, priority 1 |
| `XDG_RUNTIME_DIR` | socket directory, priority 2 |
| `TMPDIR` | socket directory, priority 3 |
| `ZMX_SESSION` | session name, injected by zmx into the session |
| `ZMX_SESSION_PREFIX` | prefix added to all session names |
| `ZMX_DIR_MODE` | mode for the socket and log directories, default 0750 |
| `ZMX_LOG_MODE` | mode for log files, default 0640 |

The same five `ZMX_*` names appear in the binary's string table, so the help is
complete rather than a subset.

## Does a child inherit `ZMX_SESSION`?

YES, and so does a grandchild. This is the fact the dependency rests on: reading
the current session takes an environment lookup, with no fork and no terminal.

The probe ran a command inside a session that dumped its own `ZMX_*` variables
and then dumped them again from a nested `sh -c`:

```
zmx run probe1 -d sh -c 'env | grep ^ZMX_ > /tmp/out; sh -c "env | grep ^ZMX_SESSION" >> /tmp/out'
```

Both levels reported `ZMX_SESSION=sysinit-probe1`.

## Does `ZMX_SESSION` carry the prefix?

YES. With `ZMX_SESSION_PREFIX=sysinit-` set and the session created as `probe1`:

- `zmx run probe1` printed `session "sysinit-probe1" created`
- `ZMX_SESSION` read `sysinit-probe1` inside the session
- `zmx list --short` printed `sysinit-probe1`
- `zmx list` printed `name=sysinit-probe1`

So zmx is consistent with itself: the variable and both list forms all carry the
prefix.

This is what task 10.8 needs, and it means the two sides of
`agent-sessions.sh:98` still differ. `sy list` names come from the seshy
namespace and carry no zmx prefix, so a comparison against `ZMX_SESSION` has to
strip `ZMX_SESSION_PREFIX` first. Task 10.5's scoped comparison rests on the
same fact.

## Can mise install it?

YES, which decides task 10.2's package group.

`mise registry` lists it:

```
zmx    github:neurosnap/zmx
```

and the upstream project ships release assets for every platform this
repository targets, checked against the GitHub releases API at `v0.7.0`:
`linux-aarch64`, `linux-x86_64`, `macos-aarch64`, `macos-x86_64`, each with a
`.sha256`.

Task 10.2 says that if zmx is mise-installable then `minimal` is the better
group, because decision 6 makes `minimal` and the non-Nix manifest the same
list. It is, so zmx goes in `minimal` and into `bootstrap/tools.toml`, and the
taxonomy question 10.2 spends most of its text on does not arise: it was about
`dev` being a poor category fit for a session manager, and `dev` is no longer
the answer.

## What this probe did NOT establish

- Behavior under SSH, which `zmx write` claims to support.
- Whether the socket directory precedence holds when more than one of the three
  variables is set. Only `ZMX_DIR` was exercised.
- Anything about 0.7.0. The probe ran 0.6.0, which is what nixpkgs pins; the
  release assets above were read from the API for the mise question alone.
