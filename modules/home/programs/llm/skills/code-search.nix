''
  # Code Search

  There are three ways to search code on this machine, and they are **not**
  interchangeable. Picking the right one per query is the whole skill. The
  default reflex of reaching for `grep` is often wrong: prefer `ast-grep` for
  anything structural, and `gh search` for anything that spans repos you have
  not cloned.

  ## Decision Tree

  ```
  What are you looking for?
  |
  +- A literal string, exact identifier, file path, or "every occurrence"?
  |     -> builtin: rg / grep / Glob / Read
  |
  +- A code SHAPE -- a call pattern, a function signature, a syntactic
  |  construct, refactor-grade matches that span lines and ignore formatting?
  |     -> ast-grep (`sg`) or the `ast-grep` MCP server
  |
  +- Something ACROSS repos -- org-wide, in a repo not cloned locally,
     "who else uses this", prior art on GitHub?
        -> gh search (code / repos / issues / prs / commits)
  ```

  ## 1. Builtin — `rg` / `grep` / `Glob` / `Read`

  The right tool when the query is **lexical**, not structural.

  - A literal string: `error: connection refused`, an import line, a TODO.
  - A known symbol you just want to locate or find callers of.
  - An exact or glob file path (`Glob` for `**/*.test.ts`).
  - You need **every** hit, exhaustively — grep enumerates; the others rank.

  `rg` is fast and already everywhere. This is the floor, not the ceiling:
  if the thing you want is defined by its *syntax* rather than its *text*,
  drop down to ast-grep instead.

  ## 2. ast-grep (`sg`) — structural / AST search

  **Prefer this over plain `grep` whenever the target is a code pattern.**
  ast-grep parses to an AST and matches by tree shape, so it is immune to
  whitespace, line breaks, and incidental formatting that defeat regex. It is
  language-aware via the repo config at `~/.config/ast-grep/sgconfig.yml`.

  Reach for it when:

  - Matching a call shape: every `foo(bar, $$$REST)` regardless of how the
    args wrap across lines.
  - Matching a construct: all `try/catch` with an empty catch; all functions
    returning a specific type; all JSX elements with a given prop.
  - Refactor-grade finds where a regex would produce false positives on
    strings, comments, or similarly-named tokens.
  - Metavariables (`$VAR`, `$$$ARGS`) to capture and reason about sub-nodes.

  Two surfaces, same engine:

  - **CLI** — `sg run -p '<pattern>' -l <lang>` for ad-hoc; `sg scan` to run
    the configured rule set. (`sg` is the alias for `ast-grep`.)
  - **MCP** — the `ast-grep` MCP server exposes structural search/rule tools
    to the harness; use it when you want results as structured tool output
    rather than parsing CLI text.

  Do **not** use ast-grep for literal text in comments, configs, markdown, or
  log strings — that is grep's job, and ast-grep will be slower and clumsier.

  ## 3. gh search — repo-wide / org-wide / not-cloned

  When the answer is not in the working tree. Searches GitHub's index, so it
  reaches code you have not cloned.

  - `gh search code '<query>' --owner <org>` — find usages/prior art across an
    org or the wider ecosystem.
  - `gh search repos`, `gh search issues`, `gh search prs`, `gh search commits`
    — locate the repo, the bug report, the PR that introduced a change.

  Caveats: GitHub code search only indexes default branches and has its own
  query syntax and rate limits; it is not a substitute for local search on a
  repo you already have checked out. For the current repo, stay with builtin /
  ast-grep — they are faster, complete, and see uncommitted work.

  ## Typical Flow

  1. Classify the query against the decision tree above before searching.
  2. Run the matching tool. For structural questions, write the ast-grep
     pattern rather than approximating it with a regex.
  3. `Read` the top hits in full file context before drawing conclusions —
     ranked tools return slices.
  4. Cite `file:line` for every source you used.

  ## Guardrails

  - **Match the tool to the query shape, not to habit.** Plain `grep` for a
    structural pattern is the most common mistake; ast-grep for a literal
    string is the second.
  - **Stay local for the current repo.** `gh search` is for what is not in the
    working tree; it misses uncommitted changes and non-default branches.
  - **ast-grep mutations are off-limits from an agent session.** Read-only
    `sg run` / `sg scan` only; `sg --rewrite` / `--update-all` change files and
    are a user-driven action.
  - **grep enumerates; ast-grep and gh search rank.** When you need *all*
    occurrences of a token, use grep — the others may cap results.
''
