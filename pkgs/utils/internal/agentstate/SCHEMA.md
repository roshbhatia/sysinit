# The pane record

One record per wezterm pane, describing what an agent is doing in it.
`agentstate.go` is the only writer. Every reader is listed below and cites this
file.

Version 1.

## Two encodings, one value

The same fact is published twice, because the two surfaces that read it cannot
read the same thing.

| | OSC user variable | JSON file |
|---|---|---|
| Where | `agent_state`, set on the pane with OSC 1337 | `<agentPanes>/<pane>.json` |
| Carries | `status`, `reason`, `since`, `agent` | all of those plus identity |
| Encoding | base64 of `status\|reason\|since\|agent` | one JSON object |
| Lifetime | dies with the pane | outlives the pane |
| Liveness rule | none needed | pane existence, see below |

Both are rendered from one `state` value in `Run`. `userVar` takes that value
rather than the variables it was built from, so the four shared fields cannot
disagree. A test asserts it.

The user variable is written first, and before the identity lookup, because
that lookup forks git and the variable is the half the owner sees.

## Fields

| Field | Type | Notes |
|---|---|---|
| `version` | number | this schema's version, currently 1 |
| `mux` | number | the wezterm mux's pid, 0 when unknown. See Liveness |
| `pane` | number OR string | see below |
| `session` | string | seshy session name, empty outside one |
| `repo` | string | repository basename |
| `branch` | string | current branch |
| `dirty` | bool | working tree has changes |
| `worktree` | string | absolute path |
| `agent` | string | harness name, a key of the harness registry |
| `status` | string | `working`, `waiting`, or `done` |
| `reason` | string | at most 60 characters, see below |
| `since` | number | unix seconds |

### `pane` is a number when numeric and a string otherwise

`paneValue` parses the id and emits a JSON number when it parses, a string when
it does not. A reader must accept both. `jq`'s `.pane` yields either without
complaint. lua's `json_parse` yields a number or a string, so a reader
comparing it to a pane id must convert first.

### `reason` never contains `|`

`tidy` folds `|` to a space. The pipe is the OSC payload's own field separator,
so one inside a reason forges a field. Newlines fold for the same reason on the
file bus.

The rule applies to both encodings even though only the OSC form needs it. The
two are rendered from one value, and a reason that differed between them would
be a second fact.

`reason` is truncated to 60 characters at write time rather than at read time,
so every surface renders the same string.

### `status` has no fourth value

`exit` is an argument to the writer, not a status. It deletes the record.

## Liveness

A record outlives the process that wrote it. `claude` and `pi` wire
`agent-state ... exit`; `codex` and `opencode` do not, so a crashed or exited
one leaves its last record behind.

The rule is pane existence, not an age bound. `since` is republished on every
tool call, so it is a heartbeat only while tool calls happen, and `waiting` and
`done` are turn-terminal. An age bound would expire the two states the deck
exists to show, while a long `working` build kept refreshing. It is not the
writer's pid either: `agent-state` is a one-shot and its pid is dead
microseconds after it publishes.

Every reader already answers pane existence, and each read site says so:

- `ui.lua` walks the panes it is drawing, so a record it never asks for is a
  record it never shows.
- `agent-sessions.sh` forks `wezterm cli list` once per run and prunes against
  it.
- `agent-busy-panes.sh` takes the live pane list from its caller and skips any
  record not in it.

### `mux` is the generation marker

Pane ids restart at 0 in each mux. Confirmed by reading `WEZTERM_PANE` in a
running instance and in two freshly started ones: all three reported pane 0. So
a pane id alone cannot tell yesterday's record from today's. Pane existence
answers "is there a pane 0", never "is it the same pane 0".

`mux` is the pid of the wezterm mux the pane belongs to, parsed from the
`gui-sock-<pid>` socket path wezterm sets in every pane. It is 0 outside
wezterm, when the socket path is shaped differently, and in records written
before this field existed. A reader treats 0 as "no marker", never as a
mismatch.

The marker is enforced by deletion rather than at read time. `agent-state`
removes the records of any mux that is no longer running, once per mux. A
`.mux-<pid>` marker file gates it, so the check costs one stat on the hot path.
This is the routine trigger, not an edge case. The state directory outlives the
mux and nothing else clears it. The first pane of a restarted terminal takes
the id the last one had.

Doing it by deletion rather than in each reader is what lets `ui.lua` benefit.
The wezterm GUI process carries neither `WEZTERM_UNIX_SOCKET` nor
`WEZTERM_PANE`, confirmed with `ps -Eww` on a running GUI. So `ui.lua` cannot
work out which mux it is, and cannot evaluate the marker itself.

Three holes remain, all real:

- A reader outside wezterm cannot answer pane existence. There is no such reader
  today. A Go reader would have to fork `wezterm cli list`, which is the fork
  removed in 2.9.
- Two muxes running at once both hand out low pane ids, so a record from the
  other live mux is neither stale nor ours. Both muxes are alive, so neither the
  reap nor pane existence rejects it.
- The reap runs on the first agent tool call in a new mux. A pane opened in that
  mux before any agent runs can be drawn once against the previous occupant's
  record.

## Readers

| Reader | Reads | Authority |
|---|---|---|
| `wezterm/lua/sysinit/pkg/ui.lua` `pane_agent_state` | the user variable, falling back to the agent-deck plugin | the variable, because it is live and pane-scoped |
| `wezterm/lua/sysinit/pkg/ui.lua` `read_pane_record` | the JSON file, `session`, `branch`, and `dirty` only | the file, because the variable does not carry them |
| `llm/runtime/agent-sessions.sh` | the JSON file | the file, because it runs outside the pane |
| `llm/runtime/agent-busy-panes.sh` | the JSON file | the file |
| `llm/runtime/agent-review-suffix.sh` | the JSON file | the file |

`ui.lua` is both a variable reader and a file reader. Describing it as one is
describing half the file.
