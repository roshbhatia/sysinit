## ADDED Requirements

### Requirement: Render verb projects the IR to target artifacts
The `render` verb SHALL project a change's IR into a target artifact selected by `--as`, supporting at least `rfc`, `design`, and `tickets`, writing markdown to stdout (or a path) deterministically.

#### Scenario: Render a proposal as an RFC
- **WHEN** the user runs `specutil render <change> --as rfc`
- **THEN** the tool emits RFC-shaped markdown derived from the change's IR

#### Scenario: Deterministic output
- **WHEN** `render` is run twice on the same unchanged IR with the same templates
- **THEN** the byte output is identical

#### Scenario: Unknown target is rejected
- **WHEN** the user runs `render --as bogus`
- **THEN** the command exits non-zero naming the unknown target and lists supported targets

### Requirement: Two-layer rendering — semantic mapping then template
Rendering SHALL apply a declarative semantic mapping (IR section → target section) to assemble target content, then render it through a Go `text/template`. The mapping SHALL be separable from the template so a target can be retargeted without rewriting layout.

#### Scenario: Mapping feeds the template
- **WHEN** a target's mapping routes `proposal.why` to the RFC summary/motivation and `design.risks` to RFC drawbacks
- **THEN** the rendered RFC places that content in the corresponding sections

#### Scenario: Missing source section is handled
- **WHEN** a mapping references an IR section that is absent from the change
- **THEN** the target section is omitted or marked empty per the mapping, and a warning names the absent source

### Requirement: Embedded, overridable templates mirroring known skeletons
The RFC and design-doc templates SHALL mirror the canonical section skeletons (RFC: summary, motivation, guide-level, reference-level, drawbacks, rationale/alternatives, unresolved questions; design: context, goals/non-goals, decisions, risks, etc.). Templates SHALL be embedded and overridable.

#### Scenario: Default skeleton is used
- **WHEN** the user renders an RFC with no template override
- **THEN** the output contains the canonical RFC sections in order

#### Scenario: Overridden template is honored
- **WHEN** the user supplies an override template for a target
- **THEN** rendering uses the override and ignores the embedded default for that target
