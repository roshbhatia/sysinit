# task-phase-shapes Specification

## Purpose
Give a plan phase a first-class loop or graph shape with validated markers, and render a declared shape as ASCII when the plan is presented.
## Requirements
### Requirement: Every non-Rollout plan phase declares a shape
Each non-Rollout `## <n>.` phase in `tasks.md` MUST declare a shape marker: `- **SHAPE** loop` or `- **SHAPE** graph`. `specutil check` MUST reject a non-Rollout phase that declares no shape. A `## <n>. Rollout` phase is exempt, matching how `specutil check` already exempts Rollout phases from the adversarial-review-checkbox check. This mirrors the declared-marker convention (`- **POLARITY**`), so the check reads a stated fact rather than inferring from prose.

#### Scenario: A phase declares its shape
- **POLARITY** positive
- **WHEN** a non-Rollout phase declares `- **SHAPE** loop` or `- **SHAPE** graph`
- **THEN** `specutil check` accepts the shape declaration

#### Scenario: A shapeless non-Rollout phase is rejected
- **POLARITY** negative
- **WHEN** a non-Rollout `## <n>.` phase has no `- **SHAPE**` marker
- **THEN** `specutil check` fails with "phase without a declared shape"

#### Scenario: The tasks template models a conforming phase
- **POLARITY** positive
- **WHEN** a change is scaffolded verbatim from the rosh-spec-driven tasks template
- **THEN** every non-Rollout phase already declares a shape and carries an adversarial-review checkbox, so the scaffold passes without edits

#### Scenario: A template phase missing its shape is rejected
- **POLARITY** negative
- **WHEN** the tasks template is edited to drop a phase's shape marker
- **THEN** the `schema-templates-conform` flake check fails, because a scaffolded change would start out non-conforming

### Requirement: Loop phases declare gather, act, verify, a stop condition, and a cap
A `loop` phase models the gather-context → act → verify cycle. It MUST declare a stop-condition marker (`- **STOP** <condition>`) and a max-iteration cap (`- **MAX-ITERS** <n>`). One iteration is the valid degenerate case. `specutil check` MUST reject a loop phase missing either marker.

#### Scenario: A well-formed loop phase
- **POLARITY** positive
- **WHEN** a `loop` phase declares `- **STOP**` and `- **MAX-ITERS**` with its gather/act/verify tasks
- **THEN** `specutil check` accepts it, including when MAX-ITERS is 1

#### Scenario: A loop with no stop condition is rejected
- **POLARITY** negative
- **WHEN** a `loop` phase omits the `- **STOP**` marker
- **THEN** `specutil check` fails with "loop phase without a stop condition", because an uncapped loop has no defined termination

### Requirement: Graph phases declare subtask dependencies that resolve
A `graph` phase models orchestrator-worker fan-out. Its subtasks MAY carry a `deps: <ids>` line naming prerequisite subtask ids; a subtask with no `deps:` is a root. Every id named in a `deps:` line MUST refer to another subtask id in the same phase. `specutil check` MUST reject a `deps:` line that references an id that does not exist.

#### Scenario: A graph phase with resolving deps
- **POLARITY** positive
- **WHEN** a `graph` phase lists subtasks where every `deps:` id names another subtask in the phase
- **THEN** `specutil check` accepts the dependency structure

#### Scenario: A dangling dependency is rejected
- **POLARITY** negative
- **WHEN** a `graph` phase has a `deps: 2.9` line but no subtask `2.9` exists in that phase
- **THEN** `specutil check` fails with "graph phase has a dangling dependency", because the edge points at nothing

### Requirement: Declared shapes are rendered as ASCII when the plan is presented
When an agent presents a plan or a shaped phase to the owner, it MUST render the shape as an inline ASCII diagram using the `diagram-mermaid-render` skill: a `loop` as a gather to act to verify cycle that returns to the stop check, a `graph` as a dependency DAG of its subtasks. This is a presentation rule for human understanding; `specutil check` does not check it because it is runtime behavior, not a fact stated in the artifact.

#### Scenario: A graph phase is shown as an ASCII DAG
- **POLARITY** positive
- **WHEN** the agent presents a `graph` phase to the owner
- **THEN** it renders an inline ASCII dependency diagram of the subtasks and their `deps:` edges via `diagram-mermaid-render`

#### Scenario: A shaped phase is not presented as prose alone
- **POLARITY** negative
- **WHEN** the agent presents a phase that declares a shape
- **THEN** it does not show only prose: the ASCII diagram accompanies the description, because the owner asked to see the shape

