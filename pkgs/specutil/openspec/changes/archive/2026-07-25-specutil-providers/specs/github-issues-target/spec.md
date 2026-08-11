## ADDED Requirements

### Requirement: plan emits ready-to-write operations for every target
`specutil plan --target <name>` SHALL emit the standard `Plan` JSON (change, title, summary, overview, target, milestones, operations array) with each `Operation` carrying the fields a tracker needs to write the item without further templating: `title`, `milestone`, `position`, `labels`, and `body`. These fields SHALL be target-neutral, so `github-issues`, `linear`, and `notion` all receive the same shape.

#### Scenario: Plan emits ready-to-write operations
- **WHEN** user runs `specutil plan --target github-issues --change my-feature`
- **THEN** stdout is valid JSON with `"target": "github-issues"` and each operation includes `title`, `milestone`, `position`, `labels`, and `body`

#### Scenario: Labels derived from stage and task kind
- **WHEN** a task belongs to phase `"1. Foundation"` and is a `verify:` step
- **THEN** `labels` includes `"stage:foundation"` and `"kind:verify"` (lowercased, punctuation reduced to hyphens)

#### Scenario: Container body carries the acceptance criteria once
- **WHEN** the change has spec scenarios
- **THEN** the plan's `overview` field holds the rendered acceptance criteria, and individual operation bodies reference it rather than repeating it

### Requirement: Ticket body pre-rendered by binary
The `body` field SHALL be rendered using the embedded `ticket.md.tmpl` template, and the `overview` field using the embedded `overview.md.tmpl`. Both SHALL be user-overridable via `--templates` (the same override mechanism as rfc/design/tickets). The binary renders them deterministically; no network call is made.

#### Scenario: Body rendered with embedded template
- **WHEN** `--templates` is not set
- **THEN** `body` is rendered using the embedded `ticket.md.tmpl`

#### Scenario: Body rendered with user override template
- **WHEN** `--templates ./my-templates/` and `./my-templates/ticket.md.tmpl` exists
- **THEN** `body` is rendered using the user-provided template

#### Scenario: Plan output is human-readable
- **WHEN** user runs `specutil plan --target github-issues | jq '.operations[0].body'`
- **THEN** the body is a readable markdown string suitable for inspection without calling the API

### Requirement: Source numbering never reaches a tracker
Fields destined for an external system SHALL carry no spec-framework convention: no task identifier (`1.1`), no phase number (`## 2.`), no sibling key (`1a`), and no spec delta keyword (`ADDED Requirements`). Ordering SHALL be expressed with `position` and `milestone` instead.

#### Scenario: Task identifier stripped from the title
- **WHEN** a task reads `- [ ] 1.4 verify: tests pass`
- **THEN** the operation's `title` is `Tests pass`, its `labels` include `kind:verify`, and no field contains `1.4`

#### Scenario: Requirements become acceptance criteria
- **WHEN** a spec declares `## ADDED Requirements` with a `#### Scenario:` block
- **THEN** the rendered output presents it as an acceptance criterion with Given/When/Then steps and no delta keyword

### Requirement: sync-to-github-issues skill orchestrates API calls
A `sync-to-github-issues` skill SHALL consume `specutil plan --target github-issues` JSON and apply each operation via `gh issue create` / `gh issue edit`, then call `specutil lock set` to record the mapping. The skill SHALL follow the confirm-then-apply pattern established by `sync-to-linear`.

#### Scenario: Create operation creates a GitHub issue
- **WHEN** the plan contains a `create` operation
- **THEN** the skill runs `gh issue create --title <title> --label <labels> --milestone <plan title> --body <body>` and calls `specutil lock set` with the returned issue number

#### Scenario: Update operation updates existing issue
- **WHEN** the plan contains an `update` operation with a stored `externalId` (issue number)
- **THEN** the skill runs `gh issue edit <number> --body <body>` and updates the lock

#### Scenario: Orphan operation flags but does not close
- **WHEN** the plan contains an `orphan` operation
- **THEN** the skill warns the user about the orphaned issue without closing it; auto-close requires `--auto` flag

### Requirement: github-issues target respects existing lock+diff contract
`specutil diff --target github-issues` SHALL work identically to `diff --target linear`: comparing current tasks against the lockfile and surfacing create/update/orphan operations. The `--target github-issues` namespace in the lockfile SHALL be independent of linear/notion namespaces.

#### Scenario: Diff shows drift for github-issues target
- **WHEN** a task has been renamed since the last sync to GitHub Issues
- **THEN** `specutil diff --target github-issues` shows the task as `update` with the stored issue number
