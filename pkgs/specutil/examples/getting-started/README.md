# Getting Started — specutil integration example

A minimal two-change OpenSpec repository demonstrating specutil's full workflow:
dependency DAG, rendering, sync planning, and the web dashboard.

## What's here

```
openspec/
├── specutil.yaml                          # cross-change dependency manifest
└── changes/
    ├── add-auth-layer/                    # Phase 1: JWT auth middleware
    │   ├── proposal.md
    │   ├── tasks.md
    │   └── specs/auth-service/spec.md
    └── user-profile-api/                  # Phase 2: depends on add-auth-layer
        ├── proposal.md
        └── tasks.md
```

`user-profile-api` depends on `add-auth-layer` — the profile endpoints read
caller identity from JWT claims that the auth middleware puts in context.

## Try it

Run all commands from this directory (`examples/getting-started/`).

```bash
# Open the web dashboard in your browser
specutil web

# Inspect the dependency graph
specutil graph --as mermaid

# Render add-auth-layer as an RFC
specutil render add-auth-layer --as rfc

# See what a Linear sync would create
specutil plan add-auth-layer --target linear

# Check for inferred dependency candidates
specutil graph --suggest
```

## Workflow: render → plan → sync

```bash
# 1. Render the proposal as a design doc for review
specutil render add-auth-layer --as design -o /tmp/auth-design.md

# 2. Emit the sync plan (no network calls)
specutil plan add-auth-layer --target linear -o /tmp/auth-plan.json

# 3. Inspect what would be created
cat /tmp/auth-plan.json | jq '.operations[].action'

# 4. After syncing (via the sync-to-linear skill), record the mapping:
#    specutil lock set <identity> <linear-id> --target linear --change add-auth-layer

# 5. Check for drift after edits
specutil diff add-auth-layer --target linear
```
