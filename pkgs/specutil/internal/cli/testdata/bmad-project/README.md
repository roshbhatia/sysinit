# BMAD Project Example

A minimal BMAD-format project showing specutil's BMAD provider. BMAD stores work
as story files under `stories/`; specutil loads them as changes.

## What's here

```
stories/
├── story-1.1.md    # Add User Authentication (In Progress)
└── story-1.2.md    # User Profile API (Draft)
```

Story 1.2 builds on the auth middleware from 1.1 — a natural dependency.

## Try it

Run all commands from this directory (`examples/bmad-project/`).

```bash
# List all stories as change names
specutil --from bmad render --as rfc --change story-1.1

# Render as a design doc
specutil --from bmad render --as design --change story-1.1

# See what a Linear sync plan would look like
specutil --from bmad plan --target linear --change story-1.1

# Open the web dashboard
specutil --from bmad web

# Dependency graph (mermaid)
specutil --from bmad graph --as mermaid
```

## Workflow

```bash
# 1. Render story 1.1 for a design review
specutil --from bmad render --as rfc --change story-1.1 -o /tmp/auth-rfc.md

# 2. Plan tasks for Linear
specutil --from bmad plan --target linear --change story-1.1 -o /tmp/auth-plan.json

# 3. After syncing via the sync-to-linear skill, record the IDs:
#    specutil --from bmad lock set <identity> <linear-id> --target linear --change story-1.1
```
