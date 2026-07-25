## 1. Make the templates conform

- **SHAPE** graph

- [x] 1.1 Add the missing required sections and a decision with its rejected alternative to the design template `deps:` none
- [x] 1.2 Add the per-slice adversarial-review checkbox and a Rollout slice to the tasks template `deps:` none
- [x] 1.3 Model a positive and a negative scenario in the spec template `deps:` none
- [x] 1.4 Give the proposal template's Impact section a shape the writing standard allows `deps:` none
- [x] 1.5 Add the `schema-templates-conform` flake check that scaffolds a change and lints it `deps:` 1.1, 1.2, 1.3, 1.4
- [x] 1.6 Verify: the check fails when a required section is removed from a template and passes when it is restored `deps:` 1.5
- [x] 1.7 Adversarial review (`adversarial-review` skill): critics attempt to break this slice against its spec scenarios, the decisions, and the gating sequence `deps:` 1.6

## 2. Rollout

- [x] 2.1 Verify: `nix flake check` green, including the new conformance check
- [x] 2.2 Apply: archive the change so the deployed specs record the invariant
- [x] 2.3 Confirm: copying the templates into a change directory yields a change that passes `specutil check` with no edits

> The first attempt at 2.3 used `openspec new change`, which writes only
> `.openspec.yaml` and no artifacts. That change passed the lint, because every
> rule treats an absent artifact as nothing to check. The vacuous pass was a
> false negative in specutil, fixed by a `change-has-artifacts` rule, and the
> specutil input was re-pinned to pick it up. The templates are copied by the
> artifact-generation step, not by `new change`, so the flake check copies them
> explicitly.
