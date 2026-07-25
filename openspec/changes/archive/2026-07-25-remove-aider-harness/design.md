## Context

`modules/home/programs/llm/` configures eleven agent harnesses. Aider is the only one the owner reports never using. Its config is not inert: it installs a Python package, writes two files into `$HOME`, and contributes an icon derivation with a pinned upstream SHA that must be refreshed whenever the logo URL changes.

Three capability specs describe it. `aider-architect-mode` is entirely about the deleted module. The other two mention it in passing.

## Decisions

### Decision: Retire `aider-architect-mode` rather than restate it

The capability has two requirements, both about `aider.nix`. With the module gone there is no subject left to specify.

  - Alternative rejected: keep the spec and mark it aspirational. Rejected because a spec describing a module the repo does not build is drift by definition, and `specutil check` cannot tell an aspirational spec from a stale one.

### Decision: Delete the capability directory directly, not through a spec delta

`openspec archive` validates each rebuilt spec and aborts the whole archive when one would end with zero requirements. A `## REMOVED Requirements` delta covering every requirement in a capability therefore cannot be applied: the run fails with "Spec must have at least one requirement" and writes nothing, including the other capabilities' deltas. Whole-capability retirement is outside what the delta path can express, so `openspec/specs/aider-architect-mode/` is deleted as an explicit task and the reason is recorded here.

  - Alternative rejected: keep the REMOVED delta and let archive fail, then hand-apply. Rejected because a change that cannot be archived by its own tooling is not a change; it is a manual edit with extra files.

### Decision: Reproduce the modified requirements verbatim except for the aider token

openspec's archive-apply parser matches requirement and scenario headings strictly. A reworded heading drops the original rather than replacing it.

  - Alternative rejected: rewrite the allowlist requirement for clarity while editing it. Rejected because it mixes a naming correction with a prose change and risks a silent drop on archive.

### Decision: Leave the `.aider.*` ignore patterns in place

`.nixignore` and `templates/discrete/.gitignore` list aider cache files. These are ignore patterns, not configuration; a stale pattern matches nothing and costs nothing.

  - Alternative rejected: strip them for tidiness. Rejected because the template is shared into other repos, some of which may still run aider, so removing the patterns there could start tracking cache files.

## Rollout & Gating

1. Code removal lands first: the module, its import, the icon, and the doc references.
2. `nix flake check` must stay green, which proves no remaining Nix reference to the deleted module.
3. `specutil check` must pass on this change.
4. Archive the change so the deployed capability specs are rewritten.
5. `nh darwin switch` drops the aider package from the profile.

Rollback: revert the commit and switch again. No external state changes.

## Adversarial Review

One objection surfaced and was addressed: the first draft deleted `openspec/specs/aider-architect-mode/spec.md` directly instead of routing the retirement through a change. That bypasses the archive step, so the capability would have vanished from the specs tree with no record of why. The removal now goes through a `## REMOVED Requirements` delta and the archive applies it.

A second objection was considered and rejected: that removing a harness warrants a deprecation period. The harness has one user, who requested the removal, and reinstating it is a single revert.
