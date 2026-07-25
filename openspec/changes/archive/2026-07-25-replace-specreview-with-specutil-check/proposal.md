## Why

`specreview` reimplements in bash and awk what `specutil` already does in Go: parse a change's artifacts and read the markers the author declared. The shell version re-derives the parse on every run, understands only `rosh-spec-driven`, and cannot be tuned per repository. `specutil check` covers the same rubric from the real parse, so keeping both means maintaining two parsers of one format.

## What Changes

- Replace the `specreview` invocation with `specutil check` in the `adversarial-review` skill and in the `rosh-spec-driven` schema instructions
- Remove `specreview.sh` and its `home.packages` entry
- Restate the four capability specs that name `specreview` as the enforcement mechanism, so they name the rubric rather than the tool
- Keep the rubric identical: the same nine checks, the same verdicts

### Non-goals

- Changing any rubric rule. This swaps the enforcer, not the standard
- Changing the owner-gated critic loop. Only the deterministic half moves
- Removing `citelock`, which is unrelated and stays in `citation-tools`

## Capabilities

### Modified Capabilities
- `adversarial-review-gating`: names `specutil check` as the deterministic lint.
- `artifact-writing-standards`: names `specutil check` as the mechanical enforcer.
- `task-phase-shapes`: names `specutil check` as the shape enforcer.

## Impact

Modified code:
- `modules/home/programs/llm/skills/adversarial-review.nix`
- `modules/home/programs/llm/citation-tools/default.nix`
- `openspec/schemas/rosh-spec-driven/schema.yaml`

Removed code:
- `modules/home/programs/llm/citation-tools/specreview.sh`

Dependencies: the `specutil` flake input moves to a revision that ships the `check` verb.

Impactful and irreversible actions: `nh darwin switch` replaces the live `specreview` binary with nothing. A rollback is a revert and a second switch, which takes minutes. Gate it behind `nh darwin build` and a differential run.

Gating signal: `nix flake check` and `nh darwin build` both pass before any switch.
