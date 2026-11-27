# Spec-driven workflow options

The managed workflow uses one optional local note. It reuses Taskwarrior for
local handoff and leaves the issue and PR as the team-facing record. This fits
worktrees, multiple harnesses, and repositories that already have a separate
documentation owner.

| Option | Strength | Fit |
| --- | --- | --- |
| [Warp](https://github.com/warpdotdev/common-skills/blob/8792394ff1b655e0af451b8fabb68ef0cfcbd208/.agents/skills/spec-driven-implementation/SKILL.md) | Separates product intent from technical design. | Borrow the distinction. Its default tracks specs beside code and can open a Linear issue. |
| [OpenSpec](https://openspec.dev/docs/customize-schemas) | Describes incremental behavior changes and can tailor the artifacts with a custom schema. | Best fit when a team wants living specs. Schema overrides can be local, and a [registered store](https://openspec.dev/docs/stores) can move the artifacts out of the code repo. Its standard archive updates the specs. |
| [GitHub Spec Kit](https://github.github.com/spec-kit/overview/core.html) | Provides clarification, planning, task breakdown, and consistency checks. | LV426 declares v1.1.0. Its [feature resolver](https://github.com/github/spec-kit/blob/v1.1.0/scripts/bash/common.sh) supports an external `SPECIFY_FEATURE_DIRECTORY` and `SPECIFY_FEATURE_NO_PERSIST=1`. The project still needs initialization. |
| [Kiro](https://kiro.dev/docs/specs/quick-plan/) | Generates requirements, design, and tasks with IDE support. | Useful as an example of a lightweight entry point. Its project artifacts and IDE context handling add a second workflow for a terminal-first, multi-harness setup. |
| [BMad](https://docs.bmad-method.org/) | Offers structured discovery, design, implementation, and review workflows. | Borrow focused acceptance and verification questions. Its broader process adds roles and artifacts that overlap with existing skills. |

Use the local skill for general work. Choose a tool for an individual project
when its owners want the extra lifecycle and agree where durable specifications
live. Evaluate any such choice in a disposable checkout before onboarding it.

## GitHub Next research

[SpecLang](https://githubnext.com/projects/speclang/) is a 2023 research
prototype. It treats structured prose as the program and regenerates the affected
implementation as the developer edits the prose and sees the result. Its demo
focuses on a live React Native preview. The project page shows the CLI but does
not provide a public installation path or a verification guarantee.

[Extract, Edit, Apply](https://githubnext.com/projects/extract-edit-apply/) is
the closer fit for an existing system. Extract the current behavior from
source, edit the description of the intended change, then apply that delta and
verify the result. The working description can be temporary. The local skill
uses this loop while keeping the implementation and tests reviewable.

[PDD Kit](https://githubnext.com/projects/pdd-kit/) explores a different
boundary. Its Rust examples use Verus to prove formal contracts and tests for
the assumptions at their boundary. Borrow its habit of stating what each
check establishes. Its toolchain is a research prototype.
