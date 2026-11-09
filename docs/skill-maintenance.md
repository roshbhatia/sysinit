# Skill maintenance and routing checks

Keep always-loaded instructions for authorization, ownership, required checks,
and compact workflow selection. Workflow procedures belong in skills; detailed
reference material is loaded only when its branch is needed. Deterministic
parsing and validation belong in small helpers with explicit inputs and outputs.
Use dependencies declared by Nix and keep existing owning CLIs as the executors.

Shared workflows live in sysinit. Host-specific workflows and corrections belong
in the consuming repository. The harness registry publishes each managed skill
root; downstream synchronization derives destinations from that registry.
`~/.config/sysinit/skills.json` describes the managed catalog. Do not overwrite
unmanaged application/plugin skill copies just to make their names agree.
Prefer the managed root and report a conflicting duplicate's source and content.

The shared metadata reader intentionally accepts flat scalar fields: name,
description, allowed-tools, when_to_use, model, effort, disable-model-invocation.
Unknown fields fail evaluation. Boolean values remain booleans; quoted strings
are decoded. Resources may be at the root or nested; only SKILL.md is excluded.
The Amp render omits Claude-specific model/effort keys. Add a tested translation
before introducing a field unsupported by a target harness.

Run the skill-catalog and harness-instructions flake checks after changing
rendering, resources, or roots. Helpers need fixtures for malformed/empty inputs,
read failures, and their real externally observable contract. Referenced commands
and source paths should resolve in the installed package, not just the checkout.

## Manual selection corpus

`docs/skill-routing-cases.json` contains representative prompts and expected or
unwanted skill selections. Consuming repositories own their domain cases.
For a routing/description change, run the affected prompts in a fresh supported
harness with the candidate configuration. Record harness/model/config revision,
actual skill reads, output, and pass/fail against the case. Include negative and
ambiguous requests. Run only the requested bounded task; a release-routing case
can be exercised as a read-only plan without executing a release.

Static checks only validate corpus references and packaging. They do not prove
model selection, adherence, or reliability. No model judge or external eval
service is required. Add broader evaluation machinery only when observed
regressions justify its maintenance cost.
