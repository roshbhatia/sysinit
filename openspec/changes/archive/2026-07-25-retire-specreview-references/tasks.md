## 1. Retire the retired name

- **SHAPE** graph

- [x] 1.1 Restate the owner-gating requirement to name `specutil check` `deps:` none
- [x] 1.2 Restate the citation-verification rubric requirement the same way `deps:` none
- [x] 1.3 Correct the Purpose headers that still name the retired tool `deps:` 1.1, 1.2
- [x] 1.4 Record the swap in `openspec/schemas/rosh-spec-driven/CHANGES.md` `deps:` 1.1, 1.2
- [x] 1.5 Adversarial review (owner waived the critic loop; the deterministic `specutil check` gate ran and passed). One objection surfaced and was fixed: the first MODIFIED draft renamed scenarios, which openspec archive rejects because renaming drops the originals. Every delta was rebuilt verbatim from the current spec. `deps:` 1.3, 1.4

## 2. Rollout

- [x] 2.1 Verify: `specutil check` passes on this change and `nix flake check` is green
- [x] 2.2 Apply: archive the change so the deployed specs are rewritten
- [x] 2.3 Confirm: no current spec outside `openspec/changes/archive/` names the retired tool
