## Why

The owner does not use aider. The repo still installs it, generates `.aider.conf.yml` and `~/.aider/CONVENTIONS.md`, ships an icon for it, names it in the generated agent instructions, and carries three capability specs that describe its behavior. That is a harness nobody runs, plus specs a reader would act on.

## What Changes

- Delete the aider harness module and every live reference to it
- Retire the `aider-architect-mode` capability, whose only subject was the deleted module
- Restate the allowlist non-consumer list without aider
- Retire the aider commit-attribution requirement in `harness-config-modernization`

### Non-goals

- Changing any other harness. The model-pin refresh that landed alongside this removal is a separate concern
- Removing the `.aider.*` entries from `.nixignore` and the discrete template `.gitignore`. Those are ignore patterns, harmless when stale, and removing them would churn a template the owner shares across repos

## Capabilities

### Removed Capabilities
- `aider-architect-mode`: the module it described no longer exists.

### Modified Capabilities
- `harness-allowlist`: the non-consumer list no longer names a deleted harness.
- `harness-config-modernization`: drops the aider commit-attribution requirement.

## Impact

Modified artifacts:
- `modules/home/programs/llm/config/aider.nix` (deleted)
- `modules/home/programs/llm/default.nix`
- `modules/home/programs/llm/config/notify.nix`
- `modules/home/programs/llm/lib/instructions.nix`
- `modules/home/programs/llm/config/agent-state.sh`
- `modules/home/programs/llm/skills/writing-commit-message.nix`
- `AGENTS.md`
- `openspec/specs/aider-architect-mode/spec.md` (deleted on archive)
- `openspec/specs/harness-allowlist/spec.md`
- `openspec/specs/harness-config-modernization/spec.md`

Dependencies: none.

Impactful and irreversible actions: the aider package leaves the profile on the next `nh darwin switch`. Reversible by reverting the commit and switching again.

Gating signal: `specutil check` passes on this change and `nix flake check` stays green.
