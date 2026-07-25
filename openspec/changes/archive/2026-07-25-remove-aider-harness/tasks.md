## 1. Remove the harness

- **SHAPE** graph

- [x] 1.1 Delete `modules/home/programs/llm/config/aider.nix` and its import `deps:` none
- [x] 1.2 Drop the aider icon from `config/notify.nix` `deps:` 1.1
- [x] 1.3 Drop aider from the generated agent-tooling line in `lib/instructions.nix` and `AGENTS.md` `deps:` 1.1
- [x] 1.4 Drop aider from the commit-scope list and the `agent-state.sh` label comment `deps:` 1.1
- [x] 1.5 Adversarial review (owner waived the critic loop; the deterministic `specutil check` gate ran). One objection surfaced and was fixed: the first draft deleted the capability spec directly instead of routing it through a REMOVED delta and archive. `deps:` 1.2, 1.3, 1.4

## 2. Retire the specs

- **SHAPE** graph

- [x] 2.1 Delete `openspec/specs/aider-architect-mode/` directly; `openspec archive` aborts on a spec left with zero requirements, so a whole-capability retirement cannot ride a delta `deps:` 1.1
- [x] 2.2 Restate the allowlist non-consumer list without aider `deps:` 1.1
- [x] 2.3 Write the `harness-config-modernization` REMOVED delta `deps:` 1.1
- [x] 2.4 Adversarial review (owner waived the critic loop; the deterministic `specutil check` gate ran). One objection surfaced and was fixed: the modified allowlist requirement first carried no declared-negative scenario, so the rubric could not tell a non-consumer violation from a passing case. A negative scenario was added. `deps:` 2.1, 2.2, 2.3

## 3. Rollout

- [x] 3.1 Verify: `specutil check` passes on this change and `nix flake check` is green
- [x] 3.2 Apply: archive the change so the deployed specs are rewritten
- [x] 3.3 Confirm: no spec outside `openspec/changes/archive/` names aider
