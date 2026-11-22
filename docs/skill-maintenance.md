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

## Workstation audit

The installed manifest declares 44 skill names across four harness roots. The
inventory found all 44 in each root after resolving symlinked skill directories.
Including `~/.agents/skills` and `~/.codex/skills`, it found 116 names and 20
with byte differences. Nine of the 20 had copies only in managed roots.
Spot checks of `search-code-routing`, `gh-stack`, and `writing-tone` showed
the expected renderer differences in model and effort metadata. Inspect a
copy's provenance and content before treating a difference as a conflict.

| Workflow | Default route | Keep the supporting skill for |
| --- | --- | --- |
| Code discovery and structural edits | `search-code-routing` routes literal search to `rg` and code shapes to `ast-grep`. | Upstream ast-grep references for rule and outline syntax. Use `calldiff` when call relationships matter. |
| Checkout, agent, and execution | `local-workflows` routes to `sy`, `agents`, `taskwarrior`, `tq`, and `ty`. | `conductor` for an explicit reusable Conductor YAML workflow. |
| Changes and PRs | The review reference selects Git, review checkpoints, Hunk, Diffview, or Atlas. The observation reference uses `gh` and `gh-pr-state`. | `gh-stack` for stack operations, and a writing skill for drafting the corresponding artifact. |
| Remote access | `tsh` for a remote shell and `tether attach` for an explicit native WezTerm attachment. | Preview the plan through the existing CLI before connecting when the transport matters. |
| Scripts and machine configuration | `shell-script-authoring` uses Nushell and the repository toolchain. `nix-deployment` covers activation of a Nix-managed host. | Bash conventions for retained scripts and the consuming repository's skills for production deployments. |

The audit corrected the inventory's false missing reports and the Bash-first
script guidance. It also added review and remote-access routes to
`local-workflows`. On this machine, both dry-run remote entry points returned
valid cached plans. The generic shell selected SSH and the explicit attach
selected native mux.

| Decision | Evidence and acceptance check |
| --- | --- |
| Consolidate PR maintenance guidance at its existing owner. | `autopilot` and `babysit` in the additional catalog have identical descriptions and different procedures. Keep one intake for authorized repair and use the managed PR reference for observation. Check explicit repair, watch-only, and merge-only prompts before removing a copy. |
| Keep structural search references pinned with their tools. | `search-code-routing` already points to the ast-grep outline skill. Keep that handoff and review upstream copies independently of machine-specific workflow decisions. |
| Review specialist skills for opt-in use. | The tutoring skill is pinned and published to the same roots as everyday workflows. Decide its default from explicit use and ownership. The inventory measures presence and content differences. |
| Keep work-only skills in the consuming repository. | The consuming manifest supplies work-specific skills, upstream requirements, and overrides. Compare their corrected behavior with the upstream owner before removing an override or replacing its source. |

Use the existing prompt corpus to verify selection in fresh harnesses before
pruning. The relevant cases here are a local checkpoint review, a PR watch, a
requested repair, and a native attach preview.
