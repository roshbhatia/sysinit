## 1. Swap the deterministic lint

- **SHAPE** graph

- [x] 1.1 Update the `specutil` flake input to a revision shipping the `check` verb `deps:` none
- [x] 1.2 Replace the `specreview` invocation with `specutil check` in `modules/home/programs/llm/skills/adversarial-review.nix` `deps:` 1.1
- [x] 1.3 Replace the `specreview` references in `openspec/schemas/rosh-spec-driven/schema.yaml` `deps:` 1.1
- [x] 1.4 Remove `specreview` from `modules/home/programs/llm/citation-tools/default.nix` and delete `specreview.sh` `deps:` 1.2, 1.3
- [x] 1.5 Verify: run both tools over every archived change and confirm the verdicts agree `deps:` 1.1
- [x] 1.6 Adversarial review (owner waived the critic loop; the deterministic `specutil check` gate ran and passed). The confirm step caught a real defect: `specreview` was removed while `specutil` was never installed as a binary, so the rubric had no enforcer. Fixed by adding specutil to the inputs overlay and `home.packages`. `deps:` 1.4, 1.5

## 2. Rollout

- [x] 2.1 Verify: `nix flake check` green and `nh darwin build` green
- [x] 2.2 Apply: `nh darwin switch`
- [x] 2.3 Confirm: `specutil check` resolves on PATH, `specreview` does not, and this change passes its own lint
