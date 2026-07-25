## Context

`modules/home/programs/llm/citation-tools/` installs two shell tools, `citelock` and `specreview`. `specreview.sh` walks a change directory with `grep` and `awk` to enforce nine rubric rules. `specutil` already parses the same artifacts into a typed representation, and its `internal/extract` package lifts the declared markers the rubric reads. `specutil check` adds a rule engine over that representation, following the packaging pattern of the other flake-provided tools in `flake.nix`.

## Goals / Non-Goals

**Goals:**
- One parser for the artifact format
- A rubric that a repository can tune without editing a script
- Identical verdicts through the swap

**Non-Goals:**
- Changing any rule
- Extending the rubric in this change

## Decisions

- Decision: enforce the rubric with `specutil check` rather than maintaining `specreview.sh`
  - Alternative rejected: keep the shell script, because it has no dependency on the specutil flake input. Rejected because two parsers of one format drift, and the shell version cannot express a per-repository rubric.
- Decision: keep the rubric in a named preset rather than in this repository's `specutil.yaml`
  - Alternative rejected: declare every rule in `openspec/specutil.yaml`. Rejected because the rubric belongs to the schema, not to one repository, and a preset lets any repository adopt it by naming its schema.
- Decision: verify the swap by differential run before deleting the script
  - Alternative rejected: trust the unit tests. Rejected because the tests assert intent, and the question here is agreement with the incumbent on real artifacts.

## Rollout & Gating

One slice. Update the flake input and the references, run the differential check against every archived change, then delete the script. The gate sequence is: edit, `nix flake check`, `nh darwin build`, differential run, `nh darwin switch`, confirm `specutil check` resolves on PATH and `specreview` does not. The kill switch is `git revert` followed by a second switch.

## Risks / Trade-offs

- The rubric could differ on an artifact shape not covered by fixtures. Mitigation: run both tools over all 26 archived changes and compare verdicts before deleting the script.
- A stale `specutil` pin would ship a binary with no `check` verb. Mitigation: `nh darwin build` fails closed, because the skill text references a verb the binary must provide.

## Migration Plan

Update the input, swap the references, verify, switch, then delete. The deletion lands in the same commit as the swap so no state exists where the skill references a tool that is not installed.

## Adversarial Review

Reviewed against the spec scenarios below, the decisions above, the gating sequence, and the proposal non-goals. The deterministic lint is `specutil check`, run against this change itself. The critic loop is owner-gated per the `adversarial-review` skill.

## Open Questions

- Whether `severity: warn` should be forbidden for this schema's own rules, so a rule can be fixed but not downgraded. Deferred; the preset ships every rule at error severity today.
