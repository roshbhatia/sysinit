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
complaint; lua's `json_parse` yields a number or a string, so a reader comparing
it to a pane id must convert first.

### `reason` never contains `|`

`tidy` folds `|` to a space. The pipe is the OSC payload's own field separator,
so one inside a reason forges a field. Newlines fold for the same reason on the
file bus.

The rule applies to both encodings even though only the OSC form needs it,
because the two are rendered from one value and a reason that differed between
them would be a second fact.

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
exists to show, while a long `working` build kept refreshing.

Two holes, both real:

- A reader outside wezterm cannot answer the question. There is no such reader
  today.
- A reused pane id inherits the previous occupant's record, and pane existence
  cannot tell the difference. Reached by restarting the terminal, not by an edge
  case: the state directory outlives the mux and nothing clears it at mux start.

## Readers

| Reader | Reads | Authority |
|---|---|---|
| `wezterm/lua/sysinit/pkg/ui.lua` `pane_agent_state` | the user variable, falling back to the agent-deck plugin | the variable, because it is live and pane-scoped |
| `wezterm/lua/sysinit/pkg/ui.lua` `read_pane_git` | the JSON file, `branch` and `dirty` only | the file, because the variable does not carry them |
| `llm/runtime/agent-sessions.sh` | the JSON file | the file, because it runs outside the pane |
| `llm/runtime/agent-busy-panes.sh` | the JSON file | the file |
| `llm/runtime/agent-review-suffix.sh` | the JSON file | the file |

`ui.lua` is both a variable reader and a file reader. Describing it as one is
describing half the file.
