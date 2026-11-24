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

Shared sources use [Agent Skills frontmatter](https://agentskills.io/specification).
Declare `name` explicitly and match it to the directory. Write a description
that says what the skill does and when it applies. The Nix reader accepts
single-line scalars and a JSON-style YAML map for `metadata`. Unknown fields,
duplicate fields, and invalid values fail evaluation.

The shared catalog maps source directories to published domain-and-action
names. The published frontmatter name matches the installed directory. Use
`sysinit.llm.enabledOptInSkills` to select a specialist skill from the catalog.
Skill names and CLI commands are separate interfaces. Include actual command
names in the description and examples so agents can discover them.
Opting into `workflow-run-conductor` also installs the Conductor CLI.

Store Claude-specific settings as string values under namespaced `metadata`
keys, such as `sysinit-claude-model`. The Claude renderer translates those
values to native fields. Other renders use the standard fields. The catalog
check parses the source and rendered frontmatter as YAML in every managed
root. Resources may be at the root or nested.

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

Treat a skill as a workflow contract. Give it a short trigger description.
Keep command contracts, authorization boundaries, and required evidence in the
entrypoint. Put specialist procedure and tool syntax in references loaded for
the selected branch. Let the active harness choose the model unless a specific
model requirement has been measured.

Record the capabilities the workflow needs: direct skill-file reads, native
skill loading, delegated read-only context, or enforced lifecycle hooks.
Verify them in the active session before relying on them. For example, the
judged review uses Claude Code's configured critic and mediator roles and
hook events. Other harnesses can perform ordinary reviews with evidence
from the current checkout.
