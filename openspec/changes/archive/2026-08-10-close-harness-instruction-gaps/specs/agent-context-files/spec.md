## MODIFIED Requirements

### Requirement: Context files follow the May 2026 AGENTS.md standard

Generated context files MUST contain only the following top-level sections, in
order: `Conventions`, `Skills`, `Prohibitions`, and `Output Style`. `Skills`
renders only for a harness with no skill loader. `Output Style` renders only
for a harness with no native output-style layer.

The file MUST NOT contain an "Architecture", "Repository Structure",
"Repository Layout", or other architectural-overview section. A repository fact
belongs in that repository's own `AGENTS.md`, not in the cross-repository
context.

The total length of any single generated context file MUST be at or under 45
lines. The cap is sized to the cross-repository rules plus headroom for one
more section. A breach means a repository fact or a domain rule leaked in.

The previous text of this requirement named six sections, including `Stack`,
`Commands`, and `Context`, and a 200-line cap. The renderer at
`modules/home/programs/llm/lib/instructions.nix` produces neither. Extending
that renderer to four more harnesses while leaving the old text in force would
ship a spec that contradicts itself and a coverage requirement that cannot be
satisfied jointly with it.

#### Scenario: Conformant structure

- **POLARITY** positive
- **WHEN** the generated context file is parsed
- **THEN** its `##` headings are drawn only from `Conventions`, `Skills`,
  `Prohibitions`, and `Output Style`, in that order
- **AND** `Prohibitions` renders after `Conventions`, so the highest-stakes
  section holds the recency position

#### Scenario: Architectural section rejected

- **POLARITY** negative
- **WHEN** `instructions.nix` introduces a `## Repository Structure` section
- **THEN** the build fails citing the prohibited section

#### Scenario: Length cap enforced

- **POLARITY** negative
- **WHEN** the rendered context file exceeds 45 lines
- **THEN** the build fails reporting the actual line count
- **AND** the message directs the author to move the text to a repository
  `AGENTS.md` or to the owning skill

## ADDED Requirements

### Requirement: Every configured harness receives the generated context

Each harness this repository configures SHALL receive the text produced by
`instructions.nix` at a path that harness reads without a flag. A harness that
has no such path SHALL be declared exempt in one place, with the reason
recorded beside the declaration.

The declaration SHALL live in a single attribute set that names every
configured harness. Adding a harness config without adding it to that set MUST
fail the build.

The path for each harness MUST be verified against the installed build before
it is declared. A path taken from a vendor document without a check against the
binary is not sufficient.

#### Scenario: A newly covered harness renders the shared text

- **POLARITY** positive
- **WHEN** the configuration is built
- **THEN** cursor and pi each have a context file containing the Conventions
  and Prohibitions sections, and each file also carries the output style rules
- **AND** every other configured harness is either covered or declared exempt
  with a reason

The roster names only the two harnesses whose paths are confirmed. Goose and
copilot are allowed to end as exempt, because their phases permit that outcome.
Naming them here would make the scenario false on a run in which every task
completed as designed.

#### Scenario: A harness added without a declaration fails the build

- **POLARITY** negative
- **WHEN** a contributor adds a harness config file but does not add that
  harness to the coverage set
- **THEN** the build fails and names the missing harness

#### Scenario: An exempt harness states its reason

- **POLARITY** negative
- **WHEN** a harness exposes no global context path
- **THEN** it is declared exempt with a stated reason
- **AND** the build does not treat the absence as coverage

#### Scenario: An unverified path is not declared

- **POLARITY** negative
- **WHEN** a context path cannot be confirmed against the installed binary or
  its bundled documentation
- **THEN** the harness is declared exempt rather than pointed at a guessed path
- **AND** the reason records that the path is unconfirmed

### Requirement: Output style reaches every harness exactly once

Every harness SHALL receive the output style rules through exactly one
mechanism. Claude uses its native output-style file. Every other harness
receives the rules appended at the end of its context file.

A harness MUST NOT receive the rules twice, because a repeated rule set spends
context without reinforcing the rule.

#### Scenario: A non-Claude harness carries the rules once

- **POLARITY** positive
- **WHEN** a non-Claude harness's context file is rendered
- **THEN** the output style section appears exactly once
- **AND** it appears after every other section

#### Scenario: A duplicated style block fails the build

- **POLARITY** negative
- **WHEN** a harness config appends the output style to text that already
  carries it
- **THEN** the build fails and names the harness
