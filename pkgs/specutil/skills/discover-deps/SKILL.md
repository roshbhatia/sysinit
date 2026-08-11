---
name: discover-deps
description: Discover and suggest inter-change dependency edges using specutil graph --suggest, optionally powered by an AI harness. Use when the user wants to find implied dependencies, asks "what depends on what", or needs to map relationships between changes before planning a sync.
license: MIT
compatibility: Requires the specutil binary on PATH. AI harness (claude, gemini, codex, pi) is optional but improves coverage beyond capability heuristics.
allowed-tools: Bash(specutil:*) AskUserQuestion
metadata:
  author: specutil
  version: "1.0"
---

# Discover inter-change dependency edges

This skill finds implied dependency relationships between OpenSpec changes and
helps you record them in `openspec/specutil.yaml`.

Run this before planning multi-change work, so the graph reflects actual
ordering constraints. A missing edge means `specutil next` reports a change as
runnable when a prerequisite is still open.

## Flow

### 1. Heuristic discovery (always)

```bash
specutil graph --suggest
```

This finds changes that share capabilities — where one change adds a capability
and another modifies it, a dependency is implied. Review the output.

### 2. AI-powered discovery (optional, recommended)

If an AI harness is available, run semantic analysis too:

```bash
# Pick the harness matching your environment
specutil graph --suggest --harness claude
specutil graph --suggest --harness gemini
specutil graph --suggest --harness codex
specutil graph --suggest --harness pi
```

The harness reads all change proposals and suggests edges based on semantic
relationships (API usage, data flow, shared concerns) that heuristics miss. Both
modes output a `SuggestReport` JSON with `candidates`; each candidate has `from`
(prerequisite), `to` (dependent), and `capability` (reason).

### 3. Review with user

Summarize the candidates — group by: edges not already in `openspec/specutil.yaml`,
show from → to with reason. Use AskUserQuestion to confirm before writing.

### 4. Apply accepted edges

For each accepted candidate `{from, to}`, add it to `openspec/specutil.yaml`.
The manifest accepts two equivalent spellings. Match whichever the file already
uses; use `changes:` for a new file.

```yaml
changes:
  <to>:
    depends_on:
      - <from>
```

```yaml
edges:
  - from: <from>
    to: <to>
```

Edit the file directly. If the change entry already exists, append to its
`depends_on` list rather than adding a second entry.

### 5. Verify

```bash
specutil graph --as mermaid
```

Confirm the new edges appear and there are no cycles (reported as warnings).

## Guardrails

- Never add a self-edge (from == to).
- Never add an edge that creates a cycle — `specutil graph` reports cycles as
  warnings; if you see one after applying, remove the offending edge.
- Always confirm with the user before writing to `openspec/specutil.yaml`.
- Show the `capability` field (reason string) to help users evaluate each edge.
