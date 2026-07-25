''
  specutil is a Go CLI that reads the repo's `openspec/changes/` tree and produces
  dependency graphs, rendered documents, and sync plans without any network I/O.

  ## When to use

  - Before planning multi-change work: run `specutil graph --as mermaid` to see the cross-change DAG and discover blockers.
  - During an explore session: run `specutil web` to open the work graph (levels, readiness, critical path) in a browser.
  - Before marking a slice done: run `specutil check <change-dir>` as the deterministic rubric gate.
  - Before syncing to Linear or Notion: run `specutil plan --target <linear|notion>` to preview creates/updates/orphans; then run `specutil lock set` after each sync to record the mapping.
  - To render a change as an RFC, design doc, or ticket list: `specutil render --as rfc|design|tickets --change <name>`.

  ## Key commands

  ```bash
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

  specutil plan --target linear  --change NAME   # preview Linear create/update/orphan ops
  specutil plan --target notion  --change NAME

  specutil diff --target linear  --change NAME   # diff IR vs lockfile
  specutil lock set <identity> <external-id> --target <linear|notion> --change NAME
  ```

  ## Pairing with diagram-mermaid-render

  When you run `specutil graph --as mermaid`, pipe the output through the
  `diagram-mermaid-render` skill to display it inline in the terminal:

  ```bash
  specutil graph --as mermaid | mermaid-ascii
  ```

  ## Notes

  - `--change NAME` is optional when only one change exists under `openspec/changes/`; required otherwise.
  - `-C <path>` points specutil at a different repo root (default: `.`).
  - specutil performs no network I/O. All external writes (Linear, Notion) are done by the caller using MCP tools after reviewing `specutil plan` output.
''
