# render-sprig Specification

## Purpose
TBD - created by archiving change specutil-providers. Update Purpose after archive.
## Requirements
### Requirement: Sprig functions available in render templates
The `render` template engine SHALL merge the Sprig function map (`github.com/Masterminds/sprig/v3`) into the template FuncMap alongside the existing `section` function. When a Sprig function name conflicts with a specutil-defined function, the specutil function SHALL take precedence. All embedded and user-override templates SHALL have access to Sprig functions without any additional configuration.

#### Scenario: Sprig lower function usable in template
- **WHEN** a user override template contains `{{ .Title | lower }}`
- **THEN** the rendered output contains the lowercased title without error

#### Scenario: specutil section function not overridden by Sprig
- **WHEN** the Sprig map is merged and both Sprig and specutil define a function with the same name
- **THEN** the specutil-defined function is used; the template renders correctly

### Requirement: required function enforces non-empty sections
Templates MAY use `{{ required "<message>" (section .Section "<key>") }}` to fail rendering when a section is absent. When the required value is the placeholder string (`_None provided._`) or empty, the template execution SHALL fail with the provided message. This gives user template authors opt-in validation without modifying the binary.

#### Scenario: required fails on absent section
- **WHEN** a user template uses `{{ required "summary must be set" (section .Section "summary") }}` and the summary source is absent
- **THEN** render returns an error containing `"summary must be set"` and exits non-zero

#### Scenario: required passes on present section
- **WHEN** the section value is non-empty and not the placeholder
- **THEN** rendering proceeds normally

### Requirement: Existing embedded templates continue to work unchanged
The addition of Sprig SHALL be backward-compatible. Existing embedded templates (rfc.md.tmpl, design.md.tmpl, tickets.md.tmpl) SHALL render identically before and after the Sprig merge — they use only the `section` function and `.Title`/`.Change` data, none of which conflict with Sprig.

#### Scenario: rfc template renders identically after Sprig merge
- **WHEN** `specutil render --as rfc` is run before and after the Sprig dependency is added
- **THEN** the rendered output is byte-for-byte identical for the same input change

### Requirement: Embedded tracker templates ship as internal render targets
Embedded `ticket.md.tmpl` and `overview.md.tmpl` templates SHALL ship alongside rfc/design/tickets and SHALL be used to pre-render the `body` and `overview` fields in plan operations. They SHALL use the standard `section`, `.Title`, `.Export`, `.Ticket`, and Sprig functions. Users MAY override them via `--templates` following the existing override convention. Neither is exposed as a user-facing `--as` value.

#### Scenario: ticket template overridable
- **WHEN** `--templates ./templates/` and `./templates/ticket.md.tmpl` exists
- **THEN** the body field in plan operations uses the user-provided template

#### Scenario: ticket template falls back to embedded
- **WHEN** `--templates` is set but `ticket.md.tmpl` is absent from the override directory
- **THEN** specutil emits a warning and uses the embedded default

### Requirement: Sprig dependency declared in go.mod
`github.com/Masterminds/sprig/v3` SHALL be added to `go.mod` and `go.sum`. No other dependency management changes are required.

#### Scenario: go.mod contains sprig dependency
- **WHEN** the change is implemented
- **THEN** `go.mod` lists `github.com/Masterminds/sprig/v3` as a direct dependency

