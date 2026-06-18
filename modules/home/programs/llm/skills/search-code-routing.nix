''
  # Code Search

  Three ways to search code on this machine, and they are **not** interchangeable.
  Picking the right one per query is the whole skill. The default reflex of
  reaching for `grep` is often wrong: prefer `ast-grep` for anything structural and
  `gh search` for anything spanning repos you have not cloned.

  ## Decision routing

  ```
  Literal string, exact identifier, file path, or "every occurrence"?  -> builtin: rg / grep / Glob / Read
  A code SHAPE — call pattern, signature, construct, refactor-grade?    -> ast-grep (sg) or the ast-grep MCP
  Across repos — org-wide, not cloned locally, prior art on GitHub?     -> gh search (code / repos / issues / prs / commits)
  ```

  ## 1. Builtin — `rg` / `grep` / `Glob` / `Read`

  The right tool when the query is **lexical**, not structural: a literal string, a
  known symbol to locate, an exact or glob path (`Glob` for `**/*.test.ts`), or when
  you need *every* hit exhaustively (grep enumerates; ast-grep and gh search rank).

  ```bash
  # good — literal text, known symbol, exhaustive enumeration
  rg "error: connection refused"
  rg -n "func ResolveTrust"

  # bad — using grep to match a code shape across line breaks
  rg "foo\(.*,.*\)"        # misses wrapped args, false-hits on strings and comments
  ```

  ## 2. ast-grep (`sg`) — structural / AST search

  Parses to an AST and matches by tree shape, so it is immune to whitespace, line
  breaks, and incidental formatting that defeat regex. Language-aware via
  `~/.config/ast-grep/sgconfig.yml`. Reach for it for call shapes, constructs
  (empty `catch`, a return type, a JSX prop), refactor-grade finds, and
  metavariable capture (`$VAR`, `$$$ARGS`).

  ```bash
  # good — match a call shape regardless of how args wrap
  sg run -p 'foo($A, $$$REST)' -l ts
  sg scan                       # run the configured rule set

  # bad — ast-grep for literal text in comments/configs/markdown
  sg run -p 'TODO' -l ts        # slower and clumsier than `rg TODO` — that is grep's job
  ```

  Two surfaces, same engine: the **CLI** (`sg run` / `sg scan`; `sg` aliases
  `ast-grep`) for ad-hoc text output, and the **ast-grep MCP server** when you want
  structured tool output instead of parsing CLI text.

  ## 3. gh search — repo-wide / org-wide / not-cloned

  When the answer is not in the working tree. Searches GitHub's index, so it reaches
  code you have not cloned.

  ```bash
  # good — find prior art / usages across an org you have not cloned
  gh search code '<query>' --owner <org>
  gh search prs '<query>' --owner <org>

  # bad — gh search for something in the repo you already have checked out
  gh search code 'ResolveTrust' --owner me   # misses uncommitted work + non-default branches
  ```

  Caveats: GitHub code search only indexes default branches and has its own syntax
  and rate limits. For the current repo, stay with builtin / ast-grep — faster,
  complete, and they see uncommitted work.

  ## Typical flow

  1. Classify the query against the routing table before searching.
  2. Run the matching tool; for structural questions, write the ast-grep pattern
     rather than approximating it with a regex.
  3. `Read` the top hits in full file context before concluding — ranked tools
     return slices.
  4. Cite `file:line` for every source you used.

  ## Guardrails — and what to do instead

  - Match the tool to the query shape, not to habit. Plain `grep` for a structural
    pattern is the most common mistake; ast-grep for a literal string is the second.
  - `gh search` is for what is not in the working tree -> stay local for the current
    repo; gh search misses uncommitted changes and non-default branches.
  - ast-grep mutations are off-limits from an agent session: read-only `sg run` /
    `sg scan` only. `sg --rewrite` / `--update-all` change files and are user-driven.
  - Need *all* occurrences of a token -> use grep; the ranking tools may cap results.
''
