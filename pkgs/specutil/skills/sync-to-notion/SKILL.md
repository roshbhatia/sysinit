---
name: sync-to-notion
description: Sync a spec change to Notion as an RFC or design doc using specutil CLI for rendering/planning and the Notion MCP tools for the remote writes. Use when the user wants to push, sync, or publish a spec proposal as a Notion RFC or a spec as a Notion design doc.
license: MIT
compatibility: Requires the specutil binary on PATH and the Notion MCP server connected.
allowed-tools: Bash(specutil:*) mcp__claude_ai_Notion__notion-create-pages mcp__claude_ai_Notion__notion-update-page mcp__claude_ai_Notion__notion-fetch AskUserQuestion
metadata:
  author: specutil
  version: "2.0"
---

# Sync a spec change to Notion

The `specutil` binary renders your local change artifacts to Markdown; it never
touches the network. You, the agent, are the **only** thing that talks to
Notion — via the Notion MCP tools — and every local-state mutation routes back
through `specutil lock set`.

Notion is **document-grained**, not task-grained: a change projects to one Notion
page (an RFC from the proposal, or a design doc from the design and specs), not
one page per task. The unit of sync is the whole rendered document.

## The naming contract

Notion readers are the furthest from the repository, so the rule is strictest.

- Never write a source task identifier (`1.1`, `2.3`), a phase number (`## 1.`),
  or a sibling key (`1a`, `1b`) into a page.
- Never write a spec delta keyword (`ADDED Requirements`, `MODIFIED`) into a
  page. The renderer already translated requirements into acceptance criteria.
- Use the rendered document title (`Add auth layer`), not the change slug
  (`add-auth-layer`). The slug stays in the lockfile only.

The renderer emits acceptance criteria as Given/When/Then checkboxes under a
requirement heading. Leave that structure intact — it is what makes the page
verifiable for a reader who has never seen the repository.

## Mapping

| Local concept | Notion primitive |
|---|---|
| Change | Page |
| Projection (rfc or design) | Page, one per projection |
| Requirement | Heading |
| Scenario | Checkbox item with Given/When/Then sub-bullets |
| Delivery stage | Heading in the tickets projection |

## Markdown handling (resolved)

`notion-create-pages` and `notion-update-page` accept **Notion-flavored Markdown
directly** in their `content` field — there is no manual block conversion. Pass
the rendered Markdown straight through. For full fidelity on advanced constructs
(callouts, columns, toggles), first read the MCP resource
`notion://docs/enhanced-markdown-spec` via your client's resource interface and
adjust the rendered Markdown to match. Do **not** put the page title inside
`content`; set it under `properties.title`.

## Inputs

- `<change>`: the change name. If omitted and only one change exists, the binary
  auto-selects it; otherwise ask the user.
- Which projection: `rfc` (from the proposal), `design` (from the design and
  specs), or `tickets` (scope, acceptance criteria, and the delivery plan).
- The destination Notion parent (a `page_id`, or a `data_source_id` when filing
  under a database). Ask the user once if unknown.
- `--auto` (optional): skip confirmation. Without it, **confirm before the
  remote write**.

## Flow: render → review → write → lock set

### 1. Render

```bash
specutil render <change> --as rfc        # or: --as design, --as tickets
```

This emits clean Markdown to stdout. Its first heading is the reader-facing
title. Capture it. Use `specutil diff <change> --target notion` to learn whether
this is a create (no lock entry) or an update (content drifted vs the lockfile).

### 2. Review (confirmation default)

Tell the user what you are about to publish: document title, projection,
destination parent, and create-vs-update. Unless `--auto` was given, use
AskUserQuestion to confirm before writing.

### 3. Write (the only network step)

- **Create** (no existing page for this change and projection): call
  `mcp__claude_ai_Notion__notion-create-pages` with the chosen `parent`, the
  document title under `properties.title`, and the rendered Markdown as
  `content` with its leading `# Title` line removed. Capture the returned page
  ID and URL.
- **Update** (a lock entry maps this change and projection to a page): call
  `mcp__claude_ai_Notion__notion-update-page` targeting that page ID, replacing
  its content with the freshly rendered Markdown.

Use a stable identity for the document, namespaced by projection: `rfc`,
`design`, or `tickets` as the lock identity under the `notion` target. That
gives one page per projection per change. Confirm before the write unless
`--auto`.

### 4. Lock set (write-back through the binary)

After a successful create or update, record the page mapping:

```bash
specutil lock set <projection> <notion-page-id> \
  --change <change> --target notion \
  --content-hash <contentHash> --title "<doc title>"
```

where `<projection>` is `rfc`, `design`, or `tickets`. Take `<contentHash>` from
`specutil diff <change> --target notion` so the next diff reports the document
as in sync.

### 5. Verify

Re-run `specutil diff <change> --target notion`. A clean publish reports no
`new` or `changed` entries for that projection's identity.

## Guardrails

- The binary makes **no** network calls. Rendering is offline; only this skill
  writes to Notion.
- Page IDs live **only** in the lockfile, never in the source artifacts.
- Default to confirmation; `--auto` is the only thing that suppresses it.
- Pass rendered Markdown verbatim — do not hand-convert to blocks, and do not
  duplicate the title into `content`.
- One page per projection per change; re-syncing updates that page rather than
  creating a duplicate.
