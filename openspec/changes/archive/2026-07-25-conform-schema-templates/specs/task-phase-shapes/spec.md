## MODIFIED Requirements

### Requirement: Every non-Rollout plan phase declares a shape
Each non-Rollout `## <n>.` slice in `tasks.md` MUST declare a shape marker: `- **SHAPE** loop` or `- **SHAPE** graph`. `specutil check` MUST reject a non-Rollout slice that declares no shape. A `## <n>. Rollout` slice is exempt, matching how `specutil check` already exempts Rollout slices from the adversarial-review-checkbox check. This mirrors the declared-marker convention (`- **POLARITY**`), so the check reads a stated fact rather than inferring from prose.

#### Scenario: A slice declares its shape
- **POLARITY** positive
- **WHEN** a non-Rollout slice declares `- **SHAPE** loop` or `- **SHAPE** graph`
- **THEN** `specutil check` accepts the shape declaration

#### Scenario: A shapeless non-Rollout slice is rejected
- **POLARITY** negative
- **WHEN** a non-Rollout `## <n>.` slice has no `- **SHAPE**` marker
- **THEN** `specutil check` fails with "slice without a declared shape"

#### Scenario: The tasks template models a conforming slice
- **POLARITY** positive
- **WHEN** a change is scaffolded verbatim from the rosh-spec-driven tasks template
- **THEN** every non-Rollout slice already declares a shape and carries an adversarial-review checkbox, so the scaffold passes without edits

#### Scenario: A template slice missing its shape is rejected
- **POLARITY** negative
- **WHEN** the tasks template is edited to drop a slice's shape marker
- **THEN** the `schema-templates-conform` flake check fails, because a scaffolded change would start out non-conforming
