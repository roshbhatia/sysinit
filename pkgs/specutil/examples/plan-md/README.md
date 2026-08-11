# plan.md Example

A standalone `plan.md` file used with specutil's `plan` input provider — no
framework setup required. Drop a `plan.md` in any directory and specutil can
render it or plan tasks from it.

## What's here

```
plan.md    # Billing retry feature plan with phases and tasks
```

## Try it

Run all commands from this directory (`examples/plan-md/`).

```bash
# Render the plan as an RFC
specutil --from plan render --as rfc --change billing-retry

# Render as a design doc
specutil --from plan render --as design --change billing-retry

# See the Linear sync plan
specutil --from plan plan --target linear --change billing-retry

# Open the web dashboard
specutil --from plan web
```

## Reading from stdin

The plan provider also accepts stdin — useful for piping:

```bash
cat plan.md | specutil --from stdin render --as rfc --change billing-retry
```

## Structure

A `plan.md` uses the same section conventions as OpenSpec's proposal + tasks artifacts:

| Section           | Maps to          | Notes                                      |
|-------------------|------------------|--------------------------------------------|
| `## Why`          | proposal.why     | Required for RFC/design render             |
| `## What Changes` | proposal.what    | Required for RFC/design render             |
| `## Capabilities` | proposal.caps    | Optional; structured capability list       |
| `## Impact`       | proposal.impact  | Optional; code/infra impact summary        |
| `## Phases`       | tasks.phases     | Numbered phases with task checkboxes       |

Any section can be omitted; specutil emits a warning but continues rendering.
