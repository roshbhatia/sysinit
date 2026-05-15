## Context

The repo already has three layered patterns this change extends rather than parallels:

- **Per-host activation installs** for tools that don't nixify cleanly:
  `modules/home/programs/llm/config/pi.nix` runs `bun install` against the pi
  agent's plugin manifest via `home.activation.updatePiSettings`. cocoindex-code
  has the same constraint — PyTorch + sentence-transformers are infeasible to
  build through `buildPythonPackage`, but `pipx install` is idempotent and the
  resulting venv lives outside the nix store.
- **Centralized MCP server registry** at
  `modules/home/programs/llm/config/mcp-servers.nix` feeding the harness-kit
  in `lib/harness-kit.nix`. Adding one entry there means every harness that
  consumes `kit.mcpServers.servers` picks up the new server automatically. The
  existing `ast-grep` and `playwright` entries are the template.
- **Canonical allowlist** at `lib/allowlist.nix` with `tierA` (read-only) and
  `tierB` (reversible local writes). The `ccc search` command is read-only by
  intent and belongs in Tier A; `ccc index` (a write) does not.

The current `cocoindex-query` skill at
`modules/home/programs/llm/skills/cocoindex-query.nix` is the artifact this
change rewrites. Its current shape — passive "use cocoindex if available,
else rg" — assumes the MCP wiring may or may not exist. Once this change
lands, the assumption flips: cocoindex IS available on every host because
activation installed it, and the MCP server IS wired in every harness because
mcp-servers.nix declared it.

## Goals / Non-Goals

**Goals:**

- Every harness sees a `cocoindex:search` tool with zero per-harness config.
- The on-disk index at `<project>/.cocoindex_code/` is the shared memory
  across all harnesses; no daemon, no broker, no per-harness state.
- Local embeddings only — zero API keys, deterministic across machines (modulo
  the embedding model version, which is pinned by the `cocoindex-code[full]`
  release).
- The skill instructs agents to prefer semantic search for intent queries and
  fall back to `rg`/`grep` for literal matches. Both paths remain valid.
- Activation is idempotent and safe to re-run on every `nh os switch`.

**Non-Goals:**

- Daemonized indexer or filesystem watchers.
- Cross-project shared index (each project keeps its own `.cocoindex_code/`).
- Custom embedding models or LiteLLM providers.
- Per-project opt-out of the MCP server (uniform exposure; agents themselves
  decide whether to call it).

## Decisions

**1. pipx activation install over Nix derivation.**

Rationale: `cocoindex-code[full]` transitively depends on PyTorch and
sentence-transformers. Building those through `buildPythonPackage` would
require nixifying a large slice of the PyTorch ecosystem — a multi-day
project orthogonal to the actual goal here. pipx gives a self-contained
venv that's idempotent under repeated activation runs.

*Alternatives considered:*

- **Docker container (`cocoindex/cocoindex-code:full`)**: rejected because
  it adds Docker as a runtime dependency for every harness session and makes
  the MCP server invocation `docker run` instead of `ccc mcp`, which
  complicates stdio handshake, file path translation, and lifecycle.
- **Full `buildPythonPackage` derivation**: rejected because PyTorch
  packaging through nixpkgs is heavy, drifts across nixpkgs revisions, and
  the user explicitly asked us to keep this pragmatic. The existing pi.nix
  pattern is the project's accepted escape hatch for non-nixifiable tools.
- **`uv tool install` instead of pipx**: rejected because pipx is already
  in this repo's closure (used elsewhere for Python tooling) and the user
  is familiar with the pi.nix activation pattern, which uses analogous
  imperative installs. Switching to uv tool for this one entry introduces a
  second pattern without a strong reason.

**2. Single MCP server entry in `mcp-servers.nix`, no per-harness opt-out.**

Rationale: The harness-kit's whole point is uniform MCP exposure. Letting
individual harnesses disable `cocoindex` would re-introduce the drift the
kit was built to eliminate.

*Alternatives considered:*

- **Per-host server entry**: rejected because cocoindex behaves identically
  on every host once the package is installed; nothing varies per host.
- **Per-harness opt-out via the existing `disabledServers` mechanism in the
  opencode formatter**: rejected because it's only honored by opencode and
  the user wants uniformity. The skill itself instructs agents on when to
  reach for cocoindex vs. rg, which is the right place for routing logic.

**3. Active routing in the skill, not in the harness instructions.**

The skill says "prefer cocoindex for semantic queries, fall back to rg for
literals." Harness-level instructions stay generic — they just announce the
skill exists. This keeps the routing rule in one place.

*Alternatives considered:*

- **Inline routing in each harness's `instructions.nix` block**: rejected
  because instructions are already long and this would duplicate the rule
  across N harnesses.
- **A separate `code-search-routing` skill that arbitrates between
  cocoindex and rg**: rejected as premature abstraction. The
  `cocoindex-query` skill already owns the semantic-search role; growing
  it to include the fallback rule is one less moving part.

**4. Tier A includes `ccc search *` and `ccc status` only; `ccc index` stays
off-allowlist.**

`ccc search` is read-only (returns chunks from the existing index).
`ccc status` reports index freshness. `ccc index` triggers re-embedding,
which is a write — the user can authorize it explicitly when they want it,
the same way `nh os switch` is off the allowlist.

*Alternatives considered:*

- **All `ccc *` patterns in Tier A**: rejected because `ccc index` performs
  a write and Tier A is read-only by definition.
- **`ccc index` in Tier B**: rejected for now — the user has no need to
  auto-allow indexing yet, and Tier B is for reversible local writes
  the agent might do incidentally. Re-indexing is intentional, not
  incidental. Can be promoted to Tier B in a future change if friction
  warrants it.

**5. `refresh_index=True` is the skill's recommended bootstrap path.**

The agent's skill instructions say "on the first call in a project, pass
`refresh_index=True` to bootstrap the index lazily." This avoids a separate
bootstrap script, daemon, or hook. It does mean the first call in a fresh
project is slow.

*Alternatives considered:*

- **SessionStart hook that runs `ccc index` if `.cocoindex_code/` is
  missing**: rejected because it adds invisible startup latency to every
  Claude session, including ones that never end up using cocoindex.
- **Direnv hook on entering a project directory**: rejected for the same
  reason — implicit indexing is surprising.

## Rollout & Gating

Five-step gated rollout. The standard sequence is `edit → nix flake check →
nh os build → user spot-check → nh os switch`. Every step below ends with
a build-or-verify gate before the next one starts.

**Slice 1 — global gitignore + allowlist additions.** Pure additive Nix
changes, zero runtime impact. Land first to keep the working tree clean
and prevent index files from being committed in subsequent slices.

- Gate: `nix flake check` passes.

**Slice 2 — activation script for `pipx install cocoindex-code[full]`.**
On its own this just installs the binary; nothing depends on it yet.

- Gate: `nh os build` succeeds; one host runs `nh os switch`; `which ccc`
  and `ccc --version` succeed in a fresh shell; the user confirms before
  rolling to other hosts.

**Slice 3 — `cocoindex` entry in `mcp-servers.nix`.** Harness-kit now
distributes it. No skill changes yet; agents have the tool but no guidance.

- Gate: `nh os switch` on one host; user opens claude, codex, gemini, and
  one other harness, confirms each lists a `cocoindex:search` tool.

**Slice 4 — rewrite of `cocoindex-query.nix` to active routing.** Skill
explicitly tells agents to prefer cocoindex. This is the behavior change.

- Gate: `nh os switch`; user runs a known semantic query in one harness
  and confirms cocoindex was consulted (visible via tool-use trace).

**Slice 5 — verification across remaining hosts.** Apply on all hosts;
spot-check at least one query per host.

- Gate: user explicitly confirms before declaring the change ready to
  archive.

Kill switch: the `mcp-servers.nix` entry can be commented out, which
removes `cocoindex:search` from every harness immediately on next
activation. The activation install can be removed with the same revert.
The skill rewrite reverts cleanly to the passive form.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| First `pipx install cocoindex-code[full]` pulls ~5 GB of model weights and ML deps; activation may stall on slow networks. | Run the install in the background of the activation script with a clear log line; show a message in the activation output. Re-runs are no-ops because pipx detects existing installs. Maps to a human-verification step in tasks.md. |
| `pipx` may not be in PATH at activation time on a fresh host. | Pre-install `pipx` via `home.packages` in the same module so the activation step's dependency is satisfied before it runs. |
| The `.cocoindex_code/` directory could grow large (hundreds of MB) per project and survive after the project is deleted. | Gitignore handles the in-repo case. Outside the repo, the directory lives next to the project; if the user deletes the project, they delete the index. Document this in the skill. |
| Local embeddings model is ~3 GB on disk; nix-darwin reactivations on a host with limited disk could fail. | Document the disk requirement in the proposal Impact section. Activation step checks free disk before installing and errors clearly if insufficient. (Future hardening; not blocking.) |
| Agents over-rely on cocoindex and call it for literal-string searches where `rg` would be faster and cheaper. | Skill instructions explicitly carve the boundary: literal identifier/path/string → `rg`; intent/semantic → cocoindex. Phrased as a "prefer X, fall back to Y" rule with examples in both directions. |
| The MCP server fails to start in a project that has no `.cocoindex_code/`; agents see an error on first search. | `refresh_index=True` on first call bootstraps the index. Skill instructions tell agents to pass it. If indexing fails for any reason (no embeddings model downloaded, permissions, etc.), skill instructs the agent to fall back to `rg`. Maps to a human-verification step. |
| `refresh_index=True` blocks the agent for tens of seconds on a large repo while embeddings compute. | Acceptable for now — the slowness is intrinsic. Skill notes the latency so agents don't time out their own thinking. Future optimization could pre-warm via a hook. |
| Embedding model version changes between cocoindex-code releases, invalidating existing indexes. | Out of scope for this change. Re-running `ccc index` rebuilds. Document in the skill. |

## Migration Plan

There's no existing cocoindex deployment to migrate from — the current skill
is purely advisory and the MCP server has never been wired. The "migration"
is just the first-time enablement.

**Step 1 — verify clean baseline.** Before any edits:

- Confirm `nh os build` succeeds on the current main.
- Confirm `openspec validate cocoindex-first-class` reports the proposal as
  the only artifact.

**Step 2 — apply Slice 1 (gitignore + allowlist).** Edit, then:

- `nix flake check`.
- User reviews diff before committing.

**Step 3 — apply Slice 2 (activation install).** Edit, then:

- `nh os build`.
- User runs `nh os switch` on demiurge (work mac, fastest iteration loop).
- User confirms `ccc --version` returns the expected version.
- User authorizes rolling to other hosts.

**Step 4 — apply Slice 3 (MCP server entry).** Edit, then:

- `nh os build`.
- `nh os switch` on demiurge.
- User opens at least three harnesses and confirms `cocoindex:search` is
  visible in each tool list.
- User authorizes Slice 4.

**Step 5 — apply Slice 4 (skill rewrite).** Edit, then:

- `nh os build`.
- `nh os switch` on demiurge.
- User runs a known semantic query in one harness; confirms cocoindex was
  consulted before any `rg` fallback.

**Step 6 — apply Slice 5 (all-host rollout).** User runs `nh os switch`
on each remaining host. User confirms each before the change is archived.

**Rollback:** any individual slice can be reverted with `git revert <commit>`
followed by `nh os switch`. The activation install can also be uninstalled
manually via `pipx uninstall cocoindex-code` if the user wants a clean state.

## Open Questions

- **Pre-warm the embeddings model?** Currently the first index call
  downloads the ~3 GB embeddings model on demand. We could pre-pull it
  during activation. Defer; address only if first-use latency proves
  painful.
- **Should `ccc index` move to Tier B eventually?** Currently off-allowlist.
  If the user repeatedly approves it during normal sessions, promote it.
  Not part of this change.
- **Cross-machine sync?** Not addressed. If the user wants the same index
  available on multiple machines for the same checkout, that's a different
  change (rsync, restic, or a network-mounted `.cocoindex_code/`).
