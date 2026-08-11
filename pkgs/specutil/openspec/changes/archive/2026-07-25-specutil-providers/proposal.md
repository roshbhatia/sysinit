## Why

specutil's value compounds when it can read from more than one spec format and write to more than one sync target, but today it is locked to OpenSpec as input and linear/notion as plan targets with no extension point for users who work in BMAD, AI-generated plan files, or want to push to GitHub Issues. Making the provider and output layers pluggable — compiled-in adapters for common formats, script adapters for custom ones — unlocks specutil as a general spec lifecycle toolkit rather than an OpenSpec-specific tool.

## What Changes

- Introduce a `--from <provider>` flag on all verbs that load changes; add auto-detection logic that selects the right provider based on repo layout
- Add two built-in input providers: `bmad` (parses `stories/*.md` BMAD story files) and `plan` (parses any `plan.md` or stdin following a lightweight convention compatible with Claude/Codex/AI-generated plans)
- Allow `specutil.yaml` to declare user-defined script adapters that emit openspec-compatible markdown to stdout; add `--from stdin` as a pipe-friendly alias
- Add `Annotations map[string]string` to `ir.Change` so providers can attach provider-specific metadata (BMAD story status, GitHub URL, Jira priority) without polluting the typed IR
- Add `github-issues` as a first-class `plan --target` value; plan operations include a pre-rendered `github` block (labels derived from phase, milestone from change name, pre-rendered body) so the companion skill only needs to call the API
- Upgrade the `render` template engine from vanilla `text/template` to `text/template` + [Sprig](https://masterminds.github.io/sprig/), adding `required`, `default`, `toJson`, `lower`, `title`, and ~80 other functions; ship an embedded `github-issues.md.tmpl` body template alongside the existing rfc/design/tickets templates

## Capabilities

### New Capabilities
- `provider-registry`: `--from` flag, provider auto-detection by repo layout, `specutil.yaml` script adapter protocol (script emits openspec markdown; `--from stdin` alias)
- `local-plan-providers`: BMAD story parser (`--from bmad`) and generic plan.md parser (`--from plan`), both mapping their markdown conventions to the existing IR
- `ir-annotations`: `Annotations map[string]string` on `ir.Change`; populated by providers; accessible in Go templates via `{{ index .Change.Annotations "key" }}`
- `github-issues-target`: `plan --target github-issues` with extended operation schema (`github.labels`, `github.milestone`, `github.body`); embedded `github-issues.md.tmpl` body template; companion `sync-to-github-issues` skill
- `render-sprig`: Sprig FuncMap merged into the `render` template engine; `required` validation for user templates; updated docs and template examples

### Modified Capabilities
<!-- None. All capabilities are net-new. -->

## Impact

- `internal/ir/ir.go`: add `Annotations map[string]string` to `ir.Change`
- `internal/provider/provider.go`: add `--from`-selected dispatch; extend `Provider` interface with optional metadata
- `internal/provider/`: new `bmad/` and `plan/` subdirectories alongside existing `openspec/`
- `internal/render/render.go`: swap `template.FuncMap` for sprig-merged map; add embedded `github-issues.md.tmpl`
- `internal/syncplan/plan.go`: extend `Operation` with `GitHub *GitHubFields`; new target branch in `BuildPlan`
- `internal/cli/root.go`: add `--from` persistent flag; wire provider selection and auto-detection
- `specutil.yaml` schema: new `providers` array for script adapter declarations
- New skill: `sync-to-github-issues` (skills/ directory, parallel to `sync-to-linear`)
- `go.mod`: add `github.com/Masterminds/sprig/v3`
