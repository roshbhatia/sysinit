## Why

A change scaffolded verbatim from the `rosh-spec-driven` templates fails the `rosh-spec-driven` rubric with five errors. The schema grew required sections and per-slice gates, and the templates were never updated to match. An author who fills in the template still trips the gate, then has to reverse-engineer the rule from a failure message.

## What Changes

- Add the missing `Rollout & Gating`, `Migration Plan`, `Adversarial Review`, and `Open Questions` sections to the design template, and model a decision with its rejected alternative
- Add the per-slice adversarial-review checkbox and a Rollout slice to the tasks template
- Model both a positive and a negative scenario in the spec template
- Give the proposal template's Impact section a shape the writing standard allows
- Add a flake check asserting a scaffolded change passes the rubric, so the templates cannot drift again

### Non-goals

- Changing any rubric rule. The rules are correct; the templates were stale
- Rewriting the 19 archived proposals that use the older bullet style. Archived changes are history and are never re-linted
- Changing the schema instruction prose, which describes sections rather than modelling artifact output

## Capabilities

### Modified Capabilities
- `artifact-writing-standards`: the templates model the writing standard they require.
- `task-phase-shapes`: the tasks template models a conforming slice.

## Impact

Modified code:
- `openspec/schemas/rosh-spec-driven/templates/proposal.md`
- `openspec/schemas/rosh-spec-driven/templates/design.md`
- `openspec/schemas/rosh-spec-driven/templates/tasks.md`
- `openspec/schemas/rosh-spec-driven/templates/spec.md`
- `flake.nix`

Dependencies: none.

Impactful and irreversible actions: none. The templates seed new changes only, so no existing artifact is rewritten and no switch is required.

Gating signal: `nix flake check` runs the new conformance check on every evaluation.
