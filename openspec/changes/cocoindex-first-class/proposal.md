## Why

Every harness in this repo currently falls back to `grep`/`rg` for code search,
which misses intent-based queries ("where do we rate-limit external calls?")
and forces the agent to fan out across many `Read` calls to gather context.
A `cocoindex-query` skill exists at
`modules/home/programs/llm/skills/cocoindex-query.nix` but is purely
advisory — no package, no MCP wiring, no guarantee the index actually exists.
Promoting cocoindex-code to a first-class, deterministic search layer with
local embeddings gives every harness a shared semantic memory of the project
without forcing per-harness configuration drift.

## What Changes

- Package `cocoindex-code[full]` (local embeddings via
  `snowflake-arctic-embed-xs`) on every host via `home.activation` pipx
  install, mirroring the existing pattern used for pi extensions in
  `modules/home/programs/llm/config/pi.nix`.
- Add a `cocoindex` MCP server entry to
  `modules/home/programs/llm/config/mcp-servers.nix` so the existing
  harness-kit (`modules/home/programs/llm/lib/harness-kit.nix`)
  auto-distributes the `search` tool to every harness (claude, codex, cursor,
  goose, gemini, amp, crush, opencode).
- Rewrite `modules/home/programs/llm/skills/cocoindex-query.nix` from
  passive fallback instructions to active routing: agents PREFER cocoindex
  for semantic/intent queries; fall back to `rg`/`grep` only for literal
  string matches or when the index is absent.
- Add `ccc` read-only commands (`ccc search *`, `ccc status`) to Tier A in
  `modules/home/programs/llm/lib/allowlist.nix`. `ccc index` (writes) stays
  off-allowlist.
- Add `.cocoindex_code/` to the global gitignore in
  `modules/home/programs/git/default.nix` alongside the existing AI
  assistant entries.

### Non-goals

- No daemon, watcher, or always-on background indexer. Indexing is on-demand
  via `refresh_index=True` on the first MCP search call per project, or by
  the user running `ccc index` manually.
- No cloud embeddings (LiteLLM/OpenAI/etc.). Local-only embeddings remove
  the need for API key management and keep the index reproducible.
- No replacement of `cocoindex-query` with anything other than its rewritten
  active-routing form. The skill name stays.
- No changes to other search tools (ast-grep MCP, ripgrep) — those keep
  their existing role for structural and literal-string queries.
- No project-level overrides. Embeddings, storage path, and MCP wiring are
  uniform across all hosts.
- No Claude Code plugin or marketplace management. Plugin install is
  user-driven via the TUI (`/plugin`) and out of scope here.

## Capabilities

### New Capabilities

- `cocoindex-mcp-server`: declares the contract that an `cocoindex` MCP
  server entry exists in the canonical `mcp-servers.nix`, that it is
  distributed to every harness via harness-kit, and that its `search` tool
  is allowlisted for read-only invocation.

### Modified Capabilities

- `agent-skill-library`: the `cocoindex-query` skill changes from passive
  fallback ("use cocoindex if available, else rg") to active primary
  ("prefer cocoindex for semantic queries, fall back to rg for literals").
  This is a behavior change at the skill spec level, not just an
  implementation detail.
- `harness-allowlist`: Tier A grows to include `ccc search *` and
  `ccc status`. Tier B is unchanged — `ccc index` is not auto-allowed
  because it performs a write (re-embedding).

## Impact

- **Code**:
  - `modules/home/programs/llm/config/mcp-servers.nix` (additive)
  - `modules/home/programs/llm/skills/cocoindex-query.nix` (rewrite)
  - `modules/home/programs/llm/lib/allowlist.nix` (additive)
  - `modules/home/programs/git/default.nix` (additive)
  - New activation script under `modules/home/programs/llm/` for the pipx
    install (additive)
- **Dependencies**: `pipx` (already in the closure via Python tooling) and
  Python 3.11+. The pipx-managed environment is the only place where the
  `cocoindex-code` Python package lives; the nix store never gains PyTorch.
- **Disk**: ~5 GB per host for the local-embeddings model + dependencies,
  amortized across all projects. Per-project indexes (`.cocoindex_code/`)
  are tens to hundreds of MB depending on repo size.
- **Impactful actions requiring human verification**:
  - First `nh os switch` after this change triggers the pipx install on
    activation. Verify install succeeds on at least one host before
    rolling to all hosts.
  - The cocoindex MCP server gets auto-wired into every harness. Verify
    each harness sees `cocoindex:search` in its tool list before declaring
    the change complete.
- **Gating signal**: standard `nh os build` → `nh os switch` flow. The
  activation script is idempotent (pipx skips already-installed packages),
  so re-running activation is safe. A per-host opt-out can be added later
  if needed but is not part of this change.
- **Progressive rollout**: the four code touchpoints (gitignore, allowlist,
  MCP server entry, skill rewrite) plus the activation script are
  independently reviewable. The activation script lands first (so the
  package exists), then the MCP server entry, then the skill rewrite
  references it.
