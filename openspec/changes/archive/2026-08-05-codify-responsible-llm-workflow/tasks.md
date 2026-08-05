## 1. Responsibility contract

- **SHAPE** graph

- [x] 1.1 Add the responsibility invariants to `instructions.nix` `deps:` none
- [x] 1.2 Update the OpenSpec, review, citation, and writing skills `deps:` 1.1
- [x] 1.3 Update the schema instructions and templates `deps:` 1.2
- [x] 1.4 Update review vocabulary and preserve existing review records `deps:` 1.3
- [x] 1.5 Correct stale project context and schema change notes `deps:` 1.3
- [x] 1.6 Verify `citelock verify`, `specutil check`, `openspec validate`, `nix fmt -- --check`, `nix flake check`, and the explicit Darwin build `deps:` 1.4,1.5
- [x] 1.7 Adversarial review: not run; deterministic lint passed `deps:` 1.6

## 2. Rollout

- [x] 2.1 Verify: built harness contexts contain the responsibility section
- [x] 2.2 Apply: commit and `git push`, gated on the complete diff review and all checks exiting 0
- [x] 2.3 Confirm: the remote branch contains the responsibility-policy commit
