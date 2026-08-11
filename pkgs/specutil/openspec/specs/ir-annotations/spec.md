# ir-annotations Specification

## Purpose
TBD - created by archiving change specutil-providers. Update Purpose after archive.
## Requirements
### Requirement: Annotations field on ir.Change
`ir.Change` SHALL include an `Annotations map[string]string` field. The field SHALL be nil when no provider populates it (not an empty map), consistent with how other optional IR fields behave. Callers MUST treat a nil map as equivalent to an empty map.

#### Scenario: Annotations nil for openspec provider
- **WHEN** the openspec provider loads a change that has no provider-specific metadata
- **THEN** `change.Annotations` is nil

#### Scenario: Annotations populated by BMAD provider
- **WHEN** the bmad provider loads a story with `**Status:** In Review`
- **THEN** `change.Annotations["bmad.status"]` equals `"In Review"`

### Requirement: Annotations preserved through render pipeline
The render pipeline SHALL pass `ir.Change` (including Annotations) to the template data struct without modification. Template access SHALL follow standard Go map indexing: `{{ index .Change.Annotations "key" }}`.

#### Scenario: Annotation accessible in user template
- **WHEN** a user override template contains `{{ index .Change.Annotations "bmad.status" }}`
- **THEN** the rendered output includes the annotation value if present, or the empty string if absent

#### Scenario: Missing annotation key renders empty string
- **WHEN** a template accesses `{{ index .Change.Annotations "nonexistent" }}`
- **THEN** the output is the empty string; no error or panic occurs

### Requirement: Annotation key namespace convention
Built-in providers SHALL use dotted-namespace keys (`provider.field`, e.g. `bmad.status`, `bmad.id`, `github.url`). User script adapters MAY use any string key. The binary SHALL not validate or restrict annotation keys.

#### Scenario: BMAD annotations follow namespace convention
- **WHEN** the bmad provider populates annotations
- **THEN** all keys are prefixed with `bmad.` (e.g. `bmad.status`, `bmad.id`)

### Requirement: Annotations accessible via Sprig in templates
When Sprig is available in the template engine, `{{ .Change.Annotations | toJson }}` SHALL produce valid JSON and `{{ index .Change.Annotations "key" | default "fallback" }}` SHALL return the fallback when the key is absent.

#### Scenario: Annotation with Sprig default function
- **WHEN** a template uses `{{ index .Change.Annotations "bmad.status" | default "active" }}`
- **THEN** `"active"` is rendered when the key is absent or empty

