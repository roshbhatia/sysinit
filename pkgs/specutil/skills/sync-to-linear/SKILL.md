---
name: sync-to-linear
description: Sync a spec change's tasks to Linear issues using specutil CLI for planning and the Linear MCP tools for the remote writes. Use when the user wants to push, sync, or reconcile spec tasks as Linear issues, or asks to "create Linear tickets" from a change.
license: MIT
compatibility: Requires the specutil binary on PATH and the Linear MCP server connected.
allowed-tools: Bash(specutil:*) mcp__claude_ai_Linear__save_issue mcp__claude_ai_Linear__get_issue mcp__claude_ai_Linear__list_teams AskUserQuestion
metadata:
  author: specutil
  version: "2.0"
---

# Sync spec tasks to Linear

The `specutil` binary reads your local change artifacts and produces a plan; it
never touches the network. You, the agent, are the **only** thing that talks to
Linear — via the Linear MCP tools — and every local-state mutation routes back
through `specutil lock set`.

Never reimplement planning, hashing, diffing, or wording here. If you need to
know what to write, ask the binary.

## The naming contract

The plan is already written for a Linear reader. Copy its fields verbatim.

- Never write a source task identifier (`1.1`, `2.3`) into a title, a
  description, or a comment.
- Never write a phase number (`## 1.`), a sibling key (`1a`, `1b`), or a spec
  delta keyword (`ADDED`, `MODIFIED`) into Linear.
- Never write the change slug (`add-auth-layer`) as a reader-facing name. Use
  `plan.title` (`Add auth layer`). The slug stays in the lockfile only.

If you find yourself reformatting a title, stop. The binary already did it.

## Mapping

| Local concept | Linear primitive | Plan field |
|---|---|---|
| Change | Project | `title`, `summary`, `overview` |
| Phase | Project milestone | `milestones[]`, `operations[].milestone` |
| Task | Issue | `operations[].title`, `operations[].body` |
| Task order | Issue sort position | `operations[].position` |
| Task kind and stage | Labels | `operations[].labels` |
| Stage ordering | Blocking relations | see step 3 |

## Inputs

- `<change>`: the change name (e.g. `add-auth`). If omitted and only one change
  exists, the binary auto-selects it; otherwise ask the user.
- `--auto` (optional): the user said "just go do it" — skip the per-operation
  confirmation prompt. Without it, **confirm before every remote write**.
- The target Linear `team`. Ask the user once and reuse it for the whole run.

## Flow: plan → review → write → lock set

### 1. Plan

```bash
specutil plan <change> --target linear
```

Each operation is ready to write as-is:

```json
{
  "change": "add-auth-layer",
  "title": "Add auth layer",
  "summary": "The API currently has no authentication...",
  "overview": "The API currently has no authentication...\n\n## Scope\n...\n\n## Acceptance criteria\n\n### Token issuance\n\n- [ ] **Valid credentials**\n  - Given a POST to `/auth/token` with valid credentials\n  - When the server verifies them\n  - Then it returns HTTP 200 with a signed token\n",
  "target": "linear",
  "milestones": ["Foundation", "API Integration", "Rollout"],
  "operations": [
    {
      "kind": "create",
      "identity": "01ac2154...",
      "contentHash": "b649...",
      "title": "Add the login form",
      "milestone": "Foundation",
      "position": 1,
      "labels": ["stage:foundation"],
      "body": "Part of **Add auth layer** — Foundation.\n\n..."
    },
    {
      "kind": "update",
      "identity": "06d998fb...",
      "externalId": "ENG-42",
      "contentHash": "eb73...",
      "title": "Harden the session cookie",
      "milestone": "Foundation",
      "position": 2,
      "labels": ["stage:foundation"],
      "body": "..."
    },
    { "kind": "orphan", "identity": "ghost...", "externalId": "ENG-7", "title": "Removed task" }
  ]
}
```

Operation kinds:
- **create** — no lock entry; create a new Linear issue.
- **update** — a lock entry exists but the task content changed; update the
  issue named by `externalId`.
- **orphan** — a lock entry whose task no longer exists locally. The binary will
  not delete anything. Surface it and let the user decide.

### 2. Review (confirmation default)

Summarize the plan grouped by kind: N to create, M to update, K orphaned. Unless
`--auto` was given, use AskUserQuestion to confirm. List orphans explicitly.
They are the only ones that imply remote deletion intent.

### 3. Write (the only network step)

Write in this order. A container must exist before the issues that reference it.

1. **Project.** Create or find a Linear project named `plan.title`. Set its
   description to `plan.overview`. That is where the acceptance criteria live,
   so a reader who opens any issue finds them one level up.
2. **Project milestones.** Create one milestone per entry in `plan.milestones`,
   in array order. The array order is the delivery order.
3. **Issues.** For each create or update operation, in plan order:
   - **create**: call `mcp__claude_ai_Linear__save_issue` with `team`,
     `title: <op.title>`, `description: <op.body>` (literal newlines, not escape
     sequences), the project from step 1, the milestone matching
     `op.milestone`, and `labels: <op.labels>`. Do **not** pass `id`. Capture
     the returned identifier (e.g. `ENG-123`).
   - **update**: call `save_issue` with `id: <op.externalId>` and the new
     `title`, `description`, and `labels`.
   - **orphan**: act only if the user chose to. To close, call `save_issue` with
     `id: <op.externalId>` and `state` set to a done or canceled state.
4. **Blocking relations.** Stages are sequential: every issue in milestone N is
   blocked by every issue in milestone N-1. After all issues exist, add a
   `blocked by` relation for each such pair. Issues inside one milestone run in
   parallel — never relate them to each other.

Without `--auto`, confirm each write (or each batch) before issuing it.

### 4. Lock set (write-back through the binary)

Immediately after each successful create or update, record the mapping so the
next `plan` or `diff` sees it as in sync:

```bash
specutil lock set <identity> <external-id> \
  --change <change> --target linear \
  --content-hash <contentHash> --title "<title>"
```

Take `identity`, `contentHash`, and `title` straight from the plan operation,
and `external-id` from Linear. For an orphan you closed, leave the lock entry in
place; the binary has no delete verb.

### 5. Verify

```bash
specutil diff <change> --target linear
```

A clean sync reports empty `new` and `changed`. Remaining `orphaned` entries are
expected if the user chose to leave them.

## Guardrails

- The binary makes **no** network calls. If you want the binary to talk to
  Linear, stop — that work belongs here, in the skill.
- External IDs live **only** in the lockfile, never in the source artifacts.
- Default to confirmation; `--auto` is the only thing that suppresses it.
- Never invent identities or content hashes — always copy them from the plan.
- Never rewrite `title` or `body`. They are the reader-facing projection.
- `save_issue` with no `id` creates; with `id` updates. Do not pass `id` on a
  create operation or you will silently edit the wrong issue.
