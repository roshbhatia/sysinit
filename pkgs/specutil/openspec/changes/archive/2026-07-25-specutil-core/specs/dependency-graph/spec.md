## ADDED Requirements

### Requirement: Repo-level dependency manifest
Cross-change dependencies SHALL be sourced from a repo-level `openspec/specutil.yaml` manifest declaring an edge list between changes. specutil SHALL NOT read or write cross-change dependencies from OpenSpec's `.openspec.yaml`.

#### Scenario: Manifest edges build the DAG
- **WHEN** `specutil.yaml` declares change B depends on change A
- **THEN** the graph contains a directed edge A → B

#### Scenario: Edge to unknown change is reported
- **WHEN** the manifest references a change name that does not exist in the repo
- **THEN** the tool reports the dangling reference rather than silently dropping the edge

#### Scenario: Dependency cycle is detected
- **WHEN** the manifest forms a cycle among changes
- **THEN** the tool reports the cycle and the changes involved

### Requirement: Shared-capability inference (suggest only)
The `graph --suggest` mode SHALL propose candidate dependency edges inferred from capabilities shared between changes, but SHALL NOT modify the manifest unless explicitly directed.

#### Scenario: Suggestion is emitted, not applied
- **WHEN** the user runs `graph --suggest` and two changes touch the same capability
- **THEN** a candidate edge is reported for review and `specutil.yaml` is left unchanged

### Requirement: Graph projection in multiple formats
The `graph` verb SHALL project the dependency DAG to `json`, `mermaid`, and `dot` via `--as`. The `json` projection SHALL be the canonical feed consumed by visualizers.

#### Scenario: Mermaid projection
- **WHEN** the user runs `graph --as mermaid`
- **THEN** a valid Mermaid graph definition of the DAG is emitted

#### Scenario: JSON feed is stable
- **WHEN** `graph --as json` is run twice on an unchanged repo
- **THEN** the emitted JSON is byte-identical

#### Scenario: Unknown format is rejected
- **WHEN** the user runs `graph --as bogus`
- **THEN** the command exits non-zero naming the unknown format
