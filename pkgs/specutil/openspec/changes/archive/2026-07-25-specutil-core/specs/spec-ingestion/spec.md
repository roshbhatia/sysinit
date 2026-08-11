## ADDED Requirements

### Requirement: Provider port with OpenSpec adapter
Ingestion SHALL occur behind a provider port so the spec framework is pluggable. v1 SHALL ship a single OpenSpec adapter that discovers changes under `openspec/changes/<name>/` and reads `proposal.md`, `specs/**/*.md`, `design.md`, and `tasks.md`.

#### Scenario: Discover and load an OpenSpec change
- **WHEN** the OpenSpec adapter is pointed at a repo containing a change directory with a proposal
- **THEN** it loads that change into the IR including all present artifacts

#### Scenario: Unknown provider is rejected
- **WHEN** a provider other than the supported OpenSpec adapter is requested
- **THEN** ingestion fails with an error naming the unsupported provider and lists the supported ones

#### Scenario: Missing required artifact is reported
- **WHEN** a change directory exists but has no `proposal.md`
- **THEN** ingestion reports which required artifact is missing rather than silently producing an empty IR

### Requirement: Normalized hybrid IR
The adapter SHALL produce a normalized IR in which each section is available both as structured fields and as its retained raw markdown block. The IR SHALL model a change as: proposal (why, what-changes, non-goals, capabilities{new, modified}, impact); specs (per capability: requirements → scenarios, tagged with delta operation ADDED/MODIFIED/REMOVED/RENAMED); design (context, goals, non-goals, decisions, risks, rollout, migration, open-questions); and tasks (phases → checkbox items with done state and kind verify|apply|confirm). The IR SHALL expose internal graph edges change→capability→requirement→task.

#### Scenario: Structured and raw views coexist
- **WHEN** a section is parsed into the IR
- **THEN** both its structured fields and its original raw markdown are retrievable for that section

#### Scenario: Delta operations are tagged
- **WHEN** a spec contains `## MODIFIED Requirements`
- **THEN** the requirements under it are tagged in the IR as MODIFIED (and likewise for ADDED/REMOVED/RENAMED)

#### Scenario: Task kind is classified
- **WHEN** a task item's text indicates a verify/apply/confirm step
- **THEN** the IR records the task's kind accordingly, defaulting to a plain task when no kind is indicated

### Requirement: Lenient markdown parsing with loud warnings
Parsing SHALL use a goldmark AST and SHALL be lenient: slightly-malformed sections (e.g., a scenario at the wrong heading depth) SHALL be recovered where possible and SHALL emit a warning rather than silently dropping content.

#### Scenario: Malformed scenario is recovered with a warning
- **WHEN** a scenario is written with three hashtags instead of four
- **THEN** the parser still associates it with its requirement and emits a warning identifying the file and line

#### Scenario: Unrecoverable content surfaces an error
- **WHEN** a file cannot be parsed into any recognizable section
- **THEN** the tool reports a parse error identifying the file rather than producing a partial IR silently
