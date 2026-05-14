''
  # Cocoindex Query

  Cocoindex is the **primary, first-class code search mechanism** for this user. An MCP server named `cocoindex` is wired into every harness on this machine and exposes a single `search` tool. The server is backed by an incrementally-maintained semantic index stored at `<project>/.cocoindex_code/` with local embeddings — no API keys, no daemon, no network calls at query time.

  ## When to Use

  **Prefer cocoindex** for any question whose answer requires *meaning* rather than *exact match*:

  - "Where do we rate-limit external calls?"
  - "How is the auth middleware wired into the request pipeline?"
  - "Find code that retries on transient errors."
  - Any "how is X done in this codebase?" / "what's the intent of Y?" question.
  - Cross-file context-gathering before writing a design or a proposal.

  **Use `rg` / `grep` instead** when:

  - The user names a literal identifier (`processOrder`, `OrderService::dispatch`).
  - The user names an exact file path or string (`error: not found`, `import { foo } from "bar"`).
  - You already have a known symbol and just want to find its callers.
  - You need to enumerate every occurrence of a token (cocoindex returns top-K, not all hits).

  These two paths are complementary, not redundant. Pick the right one per query.

  ## First Call in a New Project

  The first time you call `cocoindex:search` in a project, the index at `.cocoindex_code/` may not exist yet. Pass `refresh_index=True` on that first call — the server will bootstrap the index lazily, embed the project, and then return results. This is a one-time cost per project (tens of seconds on a typical repo, longer on large ones).

  Subsequent calls do not need `refresh_index=True` unless files have changed materially since the last query. The server tracks file-level deltas; passing it again only when you suspect staleness is fine.

  ## MCP Tool

  | Tool | Signature | Returns |
  |------|-----------|---------|
  | `cocoindex:search` | `(query, limit=10, offset=0, refresh_index=False, languages=None, paths=None)` | Chunks with `file`, `language`, `content`, `line_start`, `line_end`, `score` |

  ## Typical Agent Flow

  1. User asks an intent-based question about the codebase.
  2. Call `cocoindex:search` with a concise natural-language query. On the first call in a new project, pass `refresh_index=True`.
  3. Read the top 2–5 hits with the `Read` tool to confirm the chunks in their full file context (cocoindex returns 50–100 line slices; you often want surrounding lines).
  4. Synthesize an answer that cites `file:line` for each source you used.
  5. If results disagree with what you see in the file directly, trust the file — the index may be stale (suggest the user re-run `ccc index` if it looks materially out of date).

  ## Graceful Fallback

  Treat the MCP call as opportunistic, not load-bearing. If `cocoindex:search` fails for any reason — server not started, index corrupt, bootstrap timeout, unsupported language — fall back to `rg` / `grep` with a slightly broader pattern. Mention to the user that you fell back, but do not block on the failure. Do not attempt to repair the index yourself; that is a user-driven action (`ccc index`, `ccc reset`).

  ## Guardrails

  - **Do not run `ccc index` or `ccc reset` from an agent session.** Those mutate the index directory; the user controls them. The MCP `refresh_index=True` flag is the only write-adjacent action the agent should take, and only on first-call bootstrap.
  - **Do not cache query results across turns.** Files may have changed; re-query.
  - **Do not assume the index covers files outside the project root.** Submodules, sibling repos, and external dependencies are out of scope.
  - **Do not use cocoindex for literal-string lookups.** `rg` / `grep` is strictly better for exact matches; reaching for cocoindex there wastes a call.
  - **The local embedding model is `snowflake-arctic-embed-xs`.** Performance characteristics (synonym handling, code-style tokenization) reflect that model; queries phrased close to natural code-comment language work best.
''
