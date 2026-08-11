---
description: Uses specutil (on PATH) to decide what to work on next in an OpenSpec change, and to visualize, gate, and render changes. Run `specutil next` before starting or resuming work on a change: it reads the declared phase shape and dependency edges and reports which subtasks are runnable now. Also use when the user asks about openspec change status, wants a dependency graph, explores spec-driven work, or renders a change as an RFC, a design doc, or a ticket list.
allowed-tools: Bash(specutil:*) Bash(mermaid-ascii:*)
---

specutil is a Go CLI that reads the repo's `openspec/changes/` tree and produces
dependency graphs, rendered documents, and review records without any network
I/O.

## When to use

- Before starting or resuming work on a change: run `specutil next`. It names the
  active phase, its shape, and the subtasks whose dependencies are complete. Do
  that set, mark it done, run it again. Do not read `tasks.md` top to bottom and
  pick by eye: the file declares a dependency graph, and reading in file order
  ignores it.

  ```bash
  # good — the tool resolves the graph and names what is runnable now
  specutil next <change>

  # bad — file order is not dependency order, so this picks a blocked subtask
  rg '^- \[ \]' openspec/changes/<change>/tasks.md | head -1
  ```
- Before planning multi-change work: run `specutil graph --as mermaid` to see the cross-change DAG and discover blockers.
- During an explore session: run `specutil web` to open the work graph (levels, readiness, critical path) in a browser.
- Before marking a phase done: run `specutil check <change-dir>` as the deterministic rubric gate.
- To render a change as an RFC, design doc, or ticket list: `specutil render --as rfc|design|tickets --change <name>`. `--as tickets` is also what to hand a tracker: it carries no phase numbers or task identifiers, so a reader outside the repository can act on it.

## Key commands

```bash
specutil next                             # runnable subtasks in the active phase
specutil next <change>                    # one change
specutil next --as json                   # machine-readable ready set

specutil graph                            # DAG as JSON (default)
specutil graph --as mermaid               # Mermaid source — pipe to diagram-mermaid-render
specutil graph --as dot                   # Graphviz DOT
specutil graph --as detail                # verbose per-node breakdown
specutil graph --suggest                  # surface recommended next changes

specutil web                              # HTML work graph, auto-opens browser
specutil web -o -                         # HTML to stdout (pipe/redirect)

specutil check                            # rubric-lint every change (exit 1 on violation)
specutil check <change-dir>               # rubric-lint one change
specutil check --as json                  # machine-readable findings
specutil check --list-rules               # the built-in rule set

specutil render --as rfc     --change NAME
specutil render --as design  --change NAME
specutil render --as tickets --change NAME
```

## Pairing with diagram-mermaid-render

When you run `specutil graph --as mermaid`, pipe the output through the
`diagram-mermaid-render` skill to display it inline in the terminal:

```bash
specutil graph --as mermaid | mermaid-ascii
```

## Reading `specutil next`

- `ready` is what to do now. Every dependency of every listed subtask is done.
- `runnable concurrently` appears only for a `graph` phase with more than one
  ready subtask that is neither an owner gate nor an adversarial review. That is
  the signal to fan out to parallel subagents. A `loop` phase never says it,
  because its next iteration reads what the current one wrote.
- `blocked` names the unmet dependency per subtask, so a stall has a reason.
- `stop` is printed verbatim for a loop phase and is NOT turned into a
  `loop-gate arm` command. A stop condition often names a file path in backticks,
  and a command guessed from prose looks right and proves nothing. Read it, then
  arm the gate yourself.
- Exit code 2 means work remains but nothing is runnable, so the dependencies
  form a cycle. Stop and fix `tasks.md`; do not retry.

## Notes

- `--change NAME` is optional when only one change exists under `openspec/changes/`; required otherwise.
- `-C <path>` points specutil at a different repo root (default: `.`).
- specutil performs no network I/O, and a test in `internal/guard` fails the build if a non-test file imports a network package. To file work in a tracker, run `specutil render --as tickets` and write it with the tracker's own MCP tools.
