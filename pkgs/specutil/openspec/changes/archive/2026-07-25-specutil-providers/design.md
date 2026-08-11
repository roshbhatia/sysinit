## Context

specutil's `Provider` interface and `render` mapping registry were deliberately designed for extension in v1 but only one adapter (openspec) and three render targets ship. The determinism boundary — the binary performs no network I/O — is the core invariant that makes specutil reliable and pipeable. All designs must preserve it.

Current extension surface:
- `internal/provider/provider.go`: the `Provider` interface is open but has no dispatch mechanism (CLI hardcodes `openspec.New(repo)`)
- `internal/render/render.go`: `mappings` is a plain Go map; new targets are added by declaring entries
- `internal/ir/ir.go`: typed struct; no generic metadata bag

## Goals / Non-Goals

**Goals:**
- Add `--from <provider>` dispatch to every verb that loads changes, with auto-detection fallback
- Ship BMAD and generic plan.md as compiled-in input providers alongside openspec
- Let users declare external script adapters in `specutil.yaml` without rebuilding
- Extend `ir.Change` with `Annotations map[string]string` for provider-specific metadata
- Add `github-issues` as a plan target with pre-rendered body in the operation JSON
- Merge Sprig into the render template engine; add embedded `github-issues.md.tmpl`

**Non-Goals:**
- Network I/O in the binary — GitHub Issues fetch is skill-owned; binary only reads local caches
- Bidirectional sync (read-back from GitHub Issues into IR)
- Plugin ABI (`.so` dynamic loading, WASM) — script adapters cover the extension case cleanly
- Changing the `plan --target linear|notion` contract — additive only

## Decisions

**D1: Provider selection via `--from` flag + auto-detection**

`--from <name>` is a persistent flag on the root command, so every verb inherits it. When absent, auto-detection runs in order:
1. `openspec/changes/` directory present → openspec
2. `stories/*.md` files present → bmad
3. `plan.md` at repo root → plan
4. Error with suggestions

Rationale: flags-free UX for the common case (openspec projects see no change); explicit flag when ambiguous. Config-driven detection (specutil.yaml) was considered but adds complexity for a problem that's solved by presence checks.

**D2: Script adapter protocol — scripts emit openspec-compatible markdown**

Script adapters declared in `specutil.yaml` emit openspec-compatible markdown to stdout (proposal/tasks/specs sections). The binary pipes stdout into the existing goldmark parser.

Alternative considered: scripts emit IR JSON. Rejected because IR JSON is harder to hand-author and debug; openspec markdown is documented, human-readable, and the parser is already lenient. Users can test an adapter with `./my-adapter.sh | specutil render --from stdin --as rfc`.

**D3: `Annotations map[string]string` over typed IR fields**

Provider-specific metadata (BMAD status, GitHub URL) lives in `Annotations` on `ir.Change` rather than typed struct fields. Typed fields only for concepts every renderer cares about.

Alternative considered: extend the typed struct per provider. Rejected — it leaks provider concerns into the core IR and requires modifying the struct for each new provider.

**D4: Pre-rendered body in github-issues plan operations**

The `github-issues` plan target extends `Operation` with a `GitHub *GitHubFields` pointer. `BuildPlan` renders the body using the embedded `github-issues.md.tmpl` template when `target == "github-issues"`. The skill receives a complete, self-contained operation and only needs to call the API.

Alternative considered: skill-side body templating. Rejected — it splits the rendering contract across binary and skill, making the output hard to inspect and test. Pre-rendering in the binary keeps the skill thin and the plan JSON human-readable (`jq '.[].github.body'`).

**D5: Sprig merged into existing FuncMap, not replacing it**

`sprig.FuncMap()` is merged with the existing `template.FuncMap{"section": ...}`. The `section` function takes precedence if Sprig ever ships a conflicting name (it doesn't currently). Existing templates are unaffected.

**D6: BMAD section coercion strategy**

| BMAD section | IR target |
|---|---|
| `## Story` (user story sentence) | `Proposal.Why` |
| `## Acceptance Criteria` (checkbox list) | `Spec.Requirements` |
| `## Tasks` (nested checkboxes) | `Tasks.Phases` |
| `## Dev Notes` | `Design.Context` |
| `**Status:**` inline field | `Annotations["bmad.status"]` |
| `# Story N.M: Title` heading | `Change.Name` + `Annotations["bmad.id"]` |

Dev Notes → Design.Context is a lossy coercion but acceptable: both are prose implementation context. The original raw text is preserved in `Section.Raw` for BMAD-specific templates.

**D7: stdin and --change interaction**

`--from stdin` reads the markdown once from os.Stdin and derives `change.Name` from the first `# heading`. The `--change` flag overrides the derived name. For `plan` and `lock` (which need a stable name for the lockfile), `--change` is required when `--from stdin` is used; the binary errors clearly if absent.

## Risks / Trade-offs

- **BMAD parser brittleness** → BMAD files use informal markdown conventions; the parser must be tolerant (warn loudly, never hard-fail). Treat every absent section as a warning, not an error — same contract as the openspec parser.
- **Script adapter security** → User-declared scripts run as shell commands. No sandboxing; this is the same trust level as any Makefile or Taskfile. Document clearly; do not add automatic execution.
- **Sprig dep size** → Sprig adds ~350KB compiled. Acceptable for a CLI; not a library concern.
- **github.body in plan JSON** → If the embedded template changes, re-running plan produces different bodies for existing issues. Mitigated by the lock+update pattern: the skill compares content hashes and only updates when the body actually changes.
