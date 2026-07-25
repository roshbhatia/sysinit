## MODIFIED Requirements

### Requirement: Artifacts follow the CLAUDE.md communication standard
Every rosh-spec-driven artifact (proposal, specs, design, tasks) MUST be written in Simplified Technical English per the Communication section of `~/.claude/CLAUDE.md`: one instruction per sentence, active voice, one term per concept, and no em-dashes in prose. The `schema.yaml` artifact instructions MUST state this rule, and `specutil check` MUST enforce the mechanical parts it can check deterministically.

#### Scenario: A conforming artifact passes
- **POLARITY** positive
- **WHEN** an artifact has no em-dash and no disallowed bolded bullet lead
- **THEN** `specutil check` accepts it on the writing-standard check

#### Scenario: An em-dash is rejected
- **POLARITY** negative
- **WHEN** an artifact contains an em-dash character in its prose
- **THEN** `specutil check` fails with "em-dash in artifact", because the standard forbids em-dashes

#### Scenario: The templates model the standard they require
- **POLARITY** positive
- **WHEN** a change is scaffolded verbatim from the rosh-spec-driven templates
- **THEN** `specutil check` accepts it, because the templates carry no disallowed bolded bullet lead and no em-dash

#### Scenario: A template that breaks the standard is rejected
- **POLARITY** negative
- **WHEN** a template is edited to open a bullet with a disallowed bolded term
- **THEN** the `schema-templates-conform` flake check fails, because a scaffolded change would inherit the violation
