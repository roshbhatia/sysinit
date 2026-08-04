# OpenSpec Awareness

This workspace uses [OpenSpec](https://github.com/Fission-AI/OpenSpec) for spec-driven changes. Active changes live under `openspec/changes/<name>/` with proposal, design, specs, and tasks artifacts. The forked schema in use is `rosh-spec-driven`, which adds rules around progressive rollouts, pattern reuse, and human-verification gates before impactful actions.

## Read active state with these commands

```bash
openspec list --json                          # list active changes (most relevant first)
openspec status --change "<name>" --json      # progress on a specific change
openspec instructions <artifact> --change "<name>" --json
                                              # rules + template for an artifact
openspec validate "<name>"                    # syntax/structure check
openspec show "<name>"                        # rendered summary
```

When the user mentions a change name, OpenSpec workflow, or spec-driven work, prefer these CLI calls over guessing. The schema's rules — Non-goals, alternatives in Decisions, negative scenarios, phased tasks with verify/apply/confirm gates — are enforced by the instruction text returned from `openspec instructions`.

## Workflow

The four canonical phases (matching Claude Code's `/opsx:*` slash commands and Pi's recipe set):

- **propose** — draft a new change with proposal, design, specs, tasks
- **apply** — implement the tasks, marking `[x]` as you go
- **explore** — thinking-partner mode, no implementation
- **archive** — finalize a completed change, merging delta specs

Run `openspec --help` for the full command list.

## Active change

The current active change name is whatever `openspec list --json` returns. If empty, no change is in flight. Always check before assuming.
