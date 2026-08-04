## 1. Package-owned schema

- **SHAPE** graph

- [x] 1.1 Move the overlay and schema into `overlays/openspec/` `deps:` none
- [x] 1.2 Install the custom schema into the OpenSpec package output `deps:` 1.1
- [x] 1.3 Remove the Home Manager schema module `deps:` 1.2
- [x] 1.4 Update checks and the drift script to use the package-owned source `deps:` 1.2
- [x] 1.5 Verify `nix fmt -- --check`, `nix flake check`, and the package probe `deps:` 1.3,1.4
- [x] 1.6 Adversarial review: not run; deterministic lint passed `deps:` 1.5

## 2. Rollout

- [x] 2.1 Verify: a built-package probe reports `rosh-spec-driven` with `Source: package`
- [x] 2.2 Apply: commit and `git push`, gated on the complete diff review and all checks exiting 0
- [x] 2.3 Confirm: the remote branch contains the package-owned schema commit
