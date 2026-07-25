# task-phase-shapes Specification

## Purpose
Give a plan phase a first-class loop or graph shape with validated markers, and render a declared shape as ASCII when the plan is presented.

## Requirements

### Requirement: Every non-Rollout plan phase declares a shape
Each non-Rollout `## <n>.` slice in `tasks.md` MUST declare a shape marker: `- **SHAPE** loop` or `- **SHAPE** graph`. `specreview` MUST reject a non-Rollout slice that declares no shape. A `## <n>. Rollout` slice is exempt, matching how `specreview` already exempts Rollout slices from the adversarial-review-checkbox check. This mirrors the declared-marker convention (`- **POLARITY**`), so the check reads a stated fact rather than inferring from prose.

#### Scenario: A slice declares its shape
- **POLARITY** positive
- **WHEN** a non-Rollout slice declares `- **SHAPE** loop` or `- **SHAPE** graph`
- **THEN** `specreview` accepts the shape declaration

#### Scenario: A shapeless non-Rollout slice is rejected
- **POLARITY** negative
- **WHEN** a non-Rollout `## <n>.` slice has no `- **SHAPE**` marker
- **THEN** `specreview` fails with "slice without a declared shape"

### Requirement: Loop phases declare gather, act, verify, a stop condition, and a cap
A `loop` slice models the gather-context → act → verify cycle. It MUST declare a stop-condition marker (`- **STOP** <condition>`) and a max-iteration cap (`- **MAX-ITERS** <n>`). One iteration is the valid degenerate case. `specreview` MUST reject a loop slice missing either marker.

#### Scenario: A well-formed loop slice
- **POLARITY** positive
- **WHEN** a `loop` slice declares `- **STOP**` and `- **MAX-ITERS**` with its gather/act/verify tasks
- **THEN** `specreview` accepts it, including when MAX-ITERS is 1

#### Scenario: A loop with no stop condition is rejected
- **POLARITY** negative
- **WHEN** a `loop` slice omits the `- **STOP**` marker
- **THEN** `specreview` fails with "loop slice without a stop condition", because an uncapped loop has no defined termination

### Requirement: Graph phases declare subtask dependencies that resolve
A `graph` slice models orchestrator-worker fan-out. Its subtasks MAY carry a `deps: <ids>` line naming prerequisite subtask ids; a subtask with no `deps:` is a root. Every id named in a `deps:` line MUST refer to another subtask id in the same slice. `specreview` MUST reject a `deps:` line that references an id that does not exist.

#### Scenario: A graph slice with resolving deps
- **POLARITY** positive
- **WHEN** a `graph` slice lists subtasks where every `deps:` id names another subtask in the slice
- **THEN** `specreview` accepts the dependency structure

#### Scenario: A dangling dependency is rejected
- **POLARITY** negative
- **WHEN** a `graph` slice has a `deps: 2.9` line but no subtask `2.9` exists in that slice
- **THEN** `specreview` fails with "graph slice has a dangling dependency", because the edge points at nothing

### Requirement: Declared shapes are rendered as ASCII when the plan is presented
When an agent presents a plan or a shaped slice to the owner, it MUST render the shape as an inline ASCII diagram using the `diagram-mermaid-render` skill: a `loop` as a gather to act to verify cycle that returns to the stop check, a `graph` as a dependency DAG of its subtasks. This is a presentation rule for human understanding; `specreview` does not check it because it is runtime behavior, not a fact stated in the artifact.

#### Scenario: A graph slice is shown as an ASCII DAG
- **POLARITY** positive
- **WHEN** the agent presents a `graph` slice to the owner
- **THEN** it renders an inline ASCII dependency diagram of the subtasks and their `deps:` edges via `diagram-mermaid-render`

#### Scenario: A shaped slice is not presented as prose alone
- **POLARITY** negative
- **WHEN** the agent presents a slice that declares a shape
- **THEN** it does not show only prose: the ASCII diagram accompanies the description, because the owner asked to see the shape

