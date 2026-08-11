---
name: sync-to-github-issues
description: Sync a spec change's tasks to GitHub Issues using specutil CLI for planning and the gh CLI for the remote writes. Use when the user wants to push, sync, or reconcile spec tasks as GitHub Issues, or asks to "create GitHub issues" from a change.
license: MIT
compatibility: Requires the specutil binary on PATH and the gh CLI authenticated.
allowed-tools: Bash(specutil:*) Bash(gh:*) AskUserQuestion
metadata:
  author: specutil
  version: "2.0"
---

# Sync spec tasks to GitHub Issues

The `specutil` binary reads your local change artifacts and produces a plan with
pre-rendered issue bodies; it never touches the network. You, the agent, are the
**only** thing that calls the GitHub API — via `gh` — and every local-state
mutation routes back through `specutil lock set`.

Never reimplement planning, label derivation, or body rendering. If you need to
know what to write, ask the binary.

## The naming contract

The plan is already written for a GitHub reader. Copy its fields verbatim.

- Never write a source task identifier (`1.1`, `2.3`) into a title, a body, or a
  comment.
- Never write a phase number (`## 1.`), a sibling key (`1a`, `1b`), or a spec
  delta keyword (`ADDED`, `MODIFIED`) into GitHub.
- Use `plan.title` (`Add auth layer`) as the milestone title, not the change
  slug. The slug stays in the lockfile only.

## Mapping

GitHub has one grouping level, so the change becomes the milestone and the
delivery stage becomes a label.

| Local concept | GitHub primitive | Plan field |
|---|---|---|
| Change | Milestone | `title`, `overview` |
| Phase | `stage:` label | `operations[].labels` |
| Task | Issue | `operations[].title`, `operations[].body` |
| Task kind | `kind:` label | `operations[].labels` |
| Stage ordering | Task list in the milestone description | see step 3 |

## Inputs

- `<change>`: the change name (e.g. `add-auth`). If omitted and only one change
  exists, the binary auto-selects it; otherwise ask the user.
- `--auto` (optional): skip the per-operation confirmation prompt.
- `--repo` (optional): GitHub repo in `owner/name` form. If omitted, `gh` uses
  the current repo.

## Flow: plan → review → write → lock set

### 1. Plan

```bash
specutil plan --change <change> --target github-issues
```

This emits JSON to stdout. Each operation is ready to write as-is:

```json
{
  "change": "add-auth-layer",
  "title": "Add auth layer",
  "overview": "The API currently has no authentication...\n\n## Acceptance criteria\n...",
  "target": "github-issues",
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
      "externalId": "42",
      "contentHash": "eb73...",
      "title": "Harden the session cookie",
      "milestone": "Foundation",
      "position": 2,
      "labels": ["stage:foundation", "kind:verify"],
      "body": "..."
    },
    { "kind": "orphan", "identity": "ghost...", "externalId": "7", "title": "Removed task" }
  ]
}
```

Operation kinds:
- **create** — no lock entry; create a new GitHub issue.
- **update** — a lock entry exists but the task content changed; update the
  issue numbered by `externalId`.
- **orphan** — a lock entry whose task no longer exists locally. The binary will
  not close anything. Surface it and let the user decide.

### 2. Review (confirmation default)

Summarize the plan grouped by kind: N to create, M to update, K orphaned. Unless
`--auto` was given, use AskUserQuestion to confirm. List orphans explicitly.

### 3. Write (the only network step)

Write in this order. A container must exist before the issues that reference it.

1. **Milestone.** Create it if it does not exist. Its description carries the
   acceptance criteria, so a reader who opens any issue finds them one level up.

   ```bash
   gh api repos/{owner}/{repo}/milestones --method POST \
     --field title="<plan.title>" --field description="<plan.overview>"
   ```

   Check for an existing milestone with that title first, to avoid duplicates.

2. **Labels.** Collect every distinct label across `operations[].labels` and
   create the ones that do not exist yet.

   ```bash
   gh label list --json name --jq '.[].name'
   gh label create "stage:foundation" --color "0075ca"
   gh label create "kind:verify" --color "d4c5f9"
   ```

3. **Issues.** For each operation, in plan order:

   **create:**
   ```bash
   gh issue create \
     --title "<op.title>" \
     --body "<op.body>" \
     --label "<label1>" --label "<label2>" \
     --milestone "<plan.title>"
   ```
   Use `jq` to read fields from the plan JSON. `gh issue create` prints the new
   issue URL; take the issue number from its last path segment.

   **update:**
   ```bash
   gh issue edit <op.externalId> --body "<op.body>"
   ```
   Add `--title "<op.title>"` when the title changed.

   **orphan:** warn the user with the issue URL
   (`gh issue view <op.externalId> --json url`). Do **not** close the issue
   unless `--auto` is set:
   ```bash
   gh issue close <op.externalId>   # only with --auto
   ```

4. **Stage ordering.** GitHub has no blocking relation. Append a task list to the
   milestone description instead, grouping issue references under a heading per
   entry in `plan.milestones`, in array order. That is the delivery order a
   reader needs.

Without `--auto`, confirm each write before issuing it.

### 4. Lock set (write-back through the binary)

Immediately after each successful create or update, record the mapping:

```bash
specutil lock set <identity> <issue-number> \
  --change <change> --target github-issues \
  --content-hash <contentHash> --title "<title>"
```

Take `identity`, `contentHash`, and `title` from the plan operation, and the
issue number from the `gh` response. Never invent these values.

For orphans you closed with `--auto`, leave the lock entry in place — the binary
has no delete verb.

### 5. Verify

```bash
specutil diff --change <change> --target github-issues
```

A clean sync reports empty `new` and `changed`. Remaining `orphaned` entries are
expected if the user chose to leave them open.

## Guardrails

- The binary makes **no** network calls. If you want the binary to talk to
  GitHub, stop — that work belongs here, in the skill.
- External IDs (issue numbers) live **only** in the lockfile, never in the
  source artifacts.
- Default to confirmation; `--auto` is the only thing that suppresses it.
- Never invent identities or content hashes — always copy them from the plan.
- Use `op.body` and `op.title` verbatim. They are pre-rendered by the binary.
  Do not re-template them.
- `gh issue create` creates; `gh issue edit <number>` updates. Do not confuse
  the two.
