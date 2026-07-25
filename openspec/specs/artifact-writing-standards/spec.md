# artifact-writing-standards Specification

## Purpose
Require every rosh-spec-driven artifact to follow the CLAUDE.md Simplified Technical English standard, enforced mechanically by specreview.

## Requirements

### Requirement: Artifacts follow the CLAUDE.md communication standard
Every rosh-spec-driven artifact (proposal, specs, design, tasks) MUST be written in Simplified Technical English per the Communication section of `~/.claude/CLAUDE.md`: one instruction per sentence, active voice, one term per concept, and no em-dashes in prose. The `schema.yaml` artifact instructions MUST state this rule, and `specreview.sh` MUST enforce the mechanical parts it can check deterministically.

#### Scenario: A conforming artifact passes
- **POLARITY** positive
- **WHEN** an artifact has no em-dash and no disallowed bolded bullet lead
- **THEN** `specreview` accepts it on the writing-standard check

#### Scenario: An em-dash is rejected
- **POLARITY** negative
- **WHEN** an artifact contains an em-dash character in its prose
- **THEN** `specreview` fails with "em-dash in artifact", because the standard forbids em-dashes

### Requirement: Structured format markers are exempt from the bold-lead check
The openspec scenario keywords (`**WHEN**`, `**THEN**`, `**AND**`) and the rosh-spec-driven markers (`**POLARITY**`, `**SHAPE**`, `**STOP**`, `**MAX-ITERS**`, `**BREAKING**`) are bolded by format, not prose emphasis. `specreview` MUST NOT flag them as bolded-first-term bullet violations; it MUST flag only a prose bullet that leads with an arbitrary bolded term.

#### Scenario: A scenario keyword is not flagged
- **POLARITY** positive
- **WHEN** a bullet is `- **WHEN** the owner approves`
- **THEN** `specreview` does not flag it, because `WHEN` is an allowed format keyword

#### Scenario: A prose bold lead is rejected
- **POLARITY** negative
- **WHEN** a prose bullet leads with an arbitrary bolded term such as `- **Note** this is important`
- **THEN** `specreview` fails with "bolded bullet lead", because the standard forbids bolding the first term of a bullet
