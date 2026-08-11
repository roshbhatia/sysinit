## 1. Foundation

- [x] 1.1 Add `Annotations map[string]string` field to `ir.Change` in `internal/ir/ir.go`
- [x] 1.2 Expose `Annotations` in `templateData` struct in `internal/render/render.go` so templates can access `{{ index .Change.Annotations "key" }}`
- [x] 1.3 Add `github.com/Masterminds/sprig/v3` to `go.mod` and `go.sum`

## 2. Render Upgrades

- [x] 2.1 Merge `sprig.FuncMap()` into `render.go` template FuncMap, ensuring the `section` function takes precedence on any conflict
- [x] 2.2 Write embedded `github-issues.md.tmpl` body template (task title, phase, change name, markdown body) under `internal/render/templates/`
- [x] 2.3 Register `github-issues` as a render target in `internal/render/mapping.go` (used by plan body rendering; not exposed as a `--as` value directly)

## 3. Provider Registry Infrastructure

- [x] 3.1 Add `--from <provider>` as a persistent flag on the root cobra command in `internal/cli/root.go`
- [x] 3.2 Implement `internal/registry/registry.go`: `SelectProvider(from string, repo string, path string, providers []graph.ProviderConfig) (provider.Provider, error)` dispatching to built-in providers and script adapters, with clear error on unrecognized name
- [x] 3.3 Implement auto-detection in `SelectProvider` when `from` is empty: check `openspec/changes/` → `stories/*.md` → `plan.md` in order; error with suggestions if no signal matches
- [x] 3.4 Implement `--from stdin` as a special case in the plan provider reading os.Stdin once, parses as plan.md convention
- [x] 3.5 Extend `specutil.yaml` schema to parse a top-level `providers` array (`name`, `command`); added to `internal/graph/manifest.go`
- [x] 3.6 Implement script adapter runner in `internal/provider/script/script.go`: substitute `{change}` in command, exec, pipe stdout to openspec parser, propagate non-zero exit as error
- [x] 3.7 Replace all hardcoded `openspec.New(repo)` calls in `internal/cli/root.go` with `SelectProvider(from, repo)` using the resolved `--from` value
- [x] 3.8 Prefix parse warnings with provider name (`warning [<provider>]: ...`) in `emitWarnings`

## 4. BMAD Input Provider

- [x] 4.1 Create `internal/provider/bmad/bmad.go` implementing `provider.Provider`; discovery by `stories/*.md` glob
- [x] 4.2 Implement BMAD section mapper: `# Story N.M: Title` → `Change.Name` + `Annotations["bmad.id"]`; `## Story` → `Proposal.Why`; `## Acceptance Criteria` → `Spec.Requirements`; `## Tasks` → `Tasks.Phases`; `## Dev Notes` → `Design.Context`
- [x] 4.3 Extract inline `**Status:** <value>` field from BMAD files into `Annotations["bmad.status"]`
- [x] 4.4 Implement tolerant parsing: absent sections emit a `[bmad]` warning and leave the IR pointer nil; parser never hard-fails on missing sections
- [x] 4.5 Handle `--change` selection among multiple `stories/*.md` files; auto-select when exactly one is present

## 5. Generic Plan Input Provider

- [x] 5.1 Create `internal/provider/plan/plan.go` implementing `provider.Provider`; accepts a file path or falls back to `plan.md` at repo root
- [x] 5.2 Implement plan.md section mapper: first `# heading` → `Change.Name`; `## Why` → `Proposal.Why`; `## What Changes` → `Proposal.WhatChanges`; `## Tasks` with `### Phase` subheadings and `- [ ]` checkboxes → `Tasks.Phases`
- [x] 5.3 Implement tolerant parsing: unrecognized headings are skipped silently; missing known sections emit a `[plan]` warning; parsing never hard-fails
- [x] 5.4 Wire `--from stdin` as an alias that reads os.Stdin and feeds into the plan parser; enforce `--change` requirement for lock/plan/diff verbs

## 6. GitHub Issues Plan Target

- [x] 6.1 Add `GitHub *GitHubFields` to `Operation` struct in `internal/syncplan/plan.go` (`GitHubFields`: `Labels []string`, `Milestone string`, `Body string`)
- [x] 6.2 Implement `deriveGitHubLabels(phaseName string) []string`: lowercase, strip punctuation, prefix `"phase:"`
- [x] 6.3 Add `github-issues` branch in `BuildPlan`: when `target == "github-issues"`, populate `GitHub` on each operation using label derivation, change name as milestone, and body rendered from `github-issues.md.tmpl`
- [x] 6.4 Wire `--templates` override into the body rendering in `BuildPlan` (same override path as `render.Render`)
- [x] 6.5 Validate `--target github-issues` is accepted by `plan`, `diff`, and `lock` verbs with no error

## 7. sync-to-github-issues Skill

- [x] 7.1 Write `skills/sync-to-github-issues/SKILL.md` following the pattern of `sync-to-linear`: confirm → apply → lock set, with `--auto` escape hatch
- [x] 7.2 Implement the confirm step: display plan summary (create N, update M, orphan K) and prompt for approval
- [x] 7.3 Implement the apply step for `create` operations: `gh issue create --title ... --label ... --milestone ... --body ...`; call `specutil lock set --target github-issues`
- [x] 7.4 Implement the apply step for `update` operations: `gh issue edit <number> --body ...`; call `specutil lock set` with updated content hash
- [x] 7.5 Implement the orphan step: warn the user with issue URL; auto-close only when `--auto` is set

## 8. Tests and Docs

- [x] 8.1 Add unit tests for BMAD section mapping in `internal/provider/bmad/bmad_test.go` covering all section mappings and the tolerant-parse contract
- [x] 8.2 Add unit tests for plan.md parsing in `internal/provider/plan/plan_test.go` covering complete, partial, and unknown-heading inputs
- [x] 8.3 Add unit tests for `deriveGitHubLabels` and the github-issues plan target in `internal/syncplan/syncplan_test.go`
- [x] 8.4 Add unit tests for provider auto-detection in `internal/registry/registry_test.go`
- [x] 8.5 Update `README.md` with `--from` flag documentation and provider examples (openspec, bmad, plan, stdin, script adapter)
- [x] 8.6 Update CLI help text for `--from` flag and `--target github-issues` with concrete usage examples
