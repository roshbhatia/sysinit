## Why

Replacing the lint updated the requirements that describe the rubric, but two requirements and three prose headers still name `specreview`, a tool this repository no longer installs. A spec that names a tool nobody can run is a spec a reader cannot act on.

## What Changes

- Restate the owner-gating requirement so it names `specutil check` as the deterministic half
- Restate the citation-verification lint requirement the same way
- Correct the Purpose headers that still name the retired tool
- Record the swap in the schema changelog

### Non-goals

- Changing any rubric rule or gate. This is a naming correction only
- Revisiting the owner-gated critic loop, which is unchanged

## Capabilities

### Modified Capabilities
- `adversarial-review-gating`: names the current lint in the gating requirement.
- `citation-verification`: names the current lint in the rubric requirement.

## Impact

Modified artifacts:
- `openspec/specs/adversarial-review-gating/spec.md`
- `openspec/specs/citation-verification/spec.md`
- `openspec/specs/artifact-writing-standards/spec.md`
- `openspec/schemas/rosh-spec-driven/CHANGES.md`

Dependencies: none.

Impactful and irreversible actions: none. This change touches documentation only and needs no switch.

Gating signal: `specutil check` passes on this change and `nix flake check` stays green.
