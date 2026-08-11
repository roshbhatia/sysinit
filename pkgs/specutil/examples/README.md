# Examples

Working examples for each specutil input provider.

| Directory | Provider | Description |
|-----------|----------|-------------|
| [`getting-started/`](getting-started/) | `openspec` | Two-change OpenSpec repo with a dependency DAG — the full specutil workflow |
| [`bmad-project/`](bmad-project/) | `bmad` | BMAD story files from `stories/` with render and plan |
| [`plan-md/`](plan-md/) | `plan` | Single `plan.md` file — no framework setup needed |

## Quick picks

**I have an OpenSpec project:**
```bash
cd examples/getting-started
specutil web
```

**I have BMAD stories:**
```bash
cd examples/bmad-project
specutil --from bmad web
```

**I just have a plan.md:**
```bash
cd examples/plan-md
specutil --from plan render --as rfc
```

**I want to pipe a plan from stdin:**
```bash
cat plan.md | specutil --from stdin render --as design --change my-feature
```
