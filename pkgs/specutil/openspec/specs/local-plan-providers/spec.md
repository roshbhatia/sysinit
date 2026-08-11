# local-plan-providers Specification

## Purpose
TBD - created by archiving change specutil-providers. Update Purpose after archive.
## Requirements
### Requirement: BMAD story parser maps sections to IR
The `bmad` provider SHALL parse BMAD story files (e.g. `stories/story-N.M.md`) into `ir.Change`. Section mapping: first `# Story N.M: Title` heading → `Change.Name` and `Annotations["bmad.id"]`; `## Story` body → `Proposal.Why`; `## Acceptance Criteria` checkbox list → `Spec.Requirements` (one requirement per top-level item, scenarios from indented items); `## Tasks` nested checkbox list → `Tasks.Phases` (phase per top-level group, items per nested checkbox); `## Dev Notes` body → `Design.Context`. The inline `**Status:** <value>` field SHALL be extracted to `Annotations["bmad.status"]`. Sections absent from the file SHALL emit a warning and leave the corresponding IR pointer nil.

#### Scenario: Complete BMAD story parsed
- **WHEN** `--from bmad stories/story-1.1.md` is given and the file contains all standard BMAD sections
- **THEN** `change.Name` is set from the heading, `Proposal.Why` from `## Story`, `Spec.Requirements` from `## Acceptance Criteria`, `Tasks.Phases` from `## Tasks`, `Design.Context` from `## Dev Notes`, and `Annotations["bmad.status"]` from the inline field

#### Scenario: Missing BMAD section emits warning
- **WHEN** a BMAD file has no `## Acceptance Criteria` section
- **THEN** the bmad provider emits a warning `[bmad]: <file>: section "Acceptance Criteria" absent` and continues without failing

#### Scenario: BMAD status annotation extracted
- **WHEN** the file contains `**Status:** In Progress`
- **THEN** `Annotations["bmad.status"]` equals `"In Progress"`

### Requirement: BMAD provider discovers stories by glob when no path given
When `--from bmad` is used without a positional path argument, the provider SHALL discover all `stories/*.md` files under the `--repo` root. `--change` selects among discovered files by matching the derived change name. If exactly one file is found and `--change` is absent, it is used automatically.

#### Scenario: Single story auto-selected
- **WHEN** `--from bmad` with no path and one `stories/*.md` file exists
- **THEN** that file is loaded without requiring `--change`

#### Scenario: Multiple stories require --change
- **WHEN** `--from bmad` with no path and multiple `stories/*.md` files exist and `--change` is absent
- **THEN** specutil exits non-zero listing the discovered story names

### Requirement: Generic plan.md parser maps markdown convention to IR
The `plan` provider SHALL parse any markdown file (or stdin path) following a lightweight convention into `ir.Change`. Mapping: first `# heading` → `Change.Name` (overridable by `--change`); `## Why` → `Proposal.Why`; `## What Changes` bullet list → `Proposal.WhatChanges` and capability names; `## Tasks` with `### Phase N: Name` subheadings and `- [ ] N.M text` checkboxes → `Tasks.Phases`. The parser SHALL be tolerant: absent sections emit warnings and leave the corresponding IR pointer nil; unrecognized headings are ignored without error.

#### Scenario: Plan.md rendered as RFC
- **WHEN** a `plan.md` file has `# my-feature`, `## Why`, `## What Changes`, and `## Tasks` sections
- **THEN** `specutil render --from plan plan.md --as rfc` renders without error, mapping each section to the RFC template

#### Scenario: Missing Why section warns but continues
- **WHEN** `plan.md` has no `## Why` section
- **THEN** specutil emits a warning and renders with the placeholder text for the summary section

#### Scenario: Unrecognized heading ignored
- **WHEN** `plan.md` contains a `## Appendix` section not in the known mapping
- **THEN** that section is silently skipped; no error or warning is emitted

### Requirement: Plan provider discovers plan.md when no path given
When `--from plan` is used without a positional path argument, the provider SHALL look for `plan.md` at the `--repo` root. If absent, specutil SHALL exit with a clear error.

#### Scenario: plan.md auto-discovered
- **WHEN** `--from plan` with no path and `plan.md` exists at repo root
- **THEN** that file is loaded automatically

#### Scenario: plan.md absent produces error
- **WHEN** `--from plan` with no path and no `plan.md` exists
- **THEN** specutil exits non-zero with an error: `plan.md not found at <repo>; pass a path or create plan.md`

