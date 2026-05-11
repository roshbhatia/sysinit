''
  # Cocoindex Query

  Query an incrementally-maintained semantic index of the current project's source code via the cocoindex MCP server.

  ## When to Use

  Use the cocoindex MCP endpoint when:

  - The user asks for "code that does X" where the answer requires semantic understanding rather than exact-string `grep`
  - The user references behavior or intent without naming a function/file (e.g., "where do we rate-limit external calls?")
  - The agent needs to gather context across many files before authoring a design or proposal
  - The user is exploring an unfamiliar repo and asks "how is X done in this codebase?"

  Prefer `grep`/`rg` when the user names a literal identifier, file path, or exact string. Cocoindex is for *meaning*, not *exact match*.

  ## Service Availability

  The cocoindex service is configured per project and **may not be running**. Before invoking the MCP tools, verify the endpoint responds:

  1. Inspect the agent's available MCP tools list — confirm `cocoindex:*` tools are present.
  2. If absent, fall back to `rg` / `grep` and inform the user the semantic index is not active for this project.
  3. Do not block the user's request waiting for the service to come up; degrade gracefully.

  ## MCP Tools

  The cocoindex MCP server exposes (assumed contract; verify on first use of each project):

  | Tool                          | Purpose                                                                  |
  |-------------------------------|--------------------------------------------------------------------------|
  | `cocoindex:semantic_search`   | Take a natural-language query, return top-K chunks with file path + score |
  | `cocoindex:read_chunk`        | Read a specific chunk by id for fuller context around a hit              |
  | `cocoindex:index_status`      | Report freshness of the index (timestamp of last update)                 |

  ## Typical Agent Flow

  1. User asks an open-ended question about the codebase.
  2. Agent calls `cocoindex:semantic_search` with a concise natural-language query.
  3. Agent reads the top 2–5 hits with `cocoindex:read_chunk` (and the surrounding lines via `Read`).
  4. Agent synthesizes an answer that cites the source files (`path:line`).
  5. If hits are stale (per `cocoindex:index_status`), the agent flags that the index may be out of date and suggests `cocoindex update` (run by the user — the agent does not manage the daemon).

  ## Guardrails

  - Do not assume the index covers files outside the project root.
  - Do not assume the index is up to date. If results disagree with `Read` output, trust the file system.
  - Do not run `cocoindex update` from an agent session — it can be long-running and locks resources. Surface the staleness to the user instead.
  - Do not store query results across turns; re-query when the underlying files have likely changed.
  - For literal-string lookups, use `rg` / `grep`. Cocoindex is meant for semantic queries.
''
