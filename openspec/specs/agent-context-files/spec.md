# agent-context-files Specification

## Purpose
TBD - created by archiving change supercharge-agent-skills. Update Purpose after archive.
## Requirements
### Requirement: Global harness context files share one source
Every global harness context file MUST be generated from `modules/home/programs/llm/lib/instructions.nix`. Repository context belongs in that repository's `AGENTS.md`.

#### Scenario: Global contexts share the responsibility contract
- **WHEN** the harness contexts are evaluated
- **THEN** each rendered context contains the required responsibility rules

#### Scenario: A harness misses a responsibility rule
- **WHEN** a rendered context omits a required responsibility rule
- **THEN** evaluation fails with the harness and missing rule named

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

### Requirement: Repository facts stay local
Pinned versions, commands, and repository architecture MUST stay in the repository `AGENTS.md`, not the global harness context.

#### Scenario: Version drift caught
- **WHEN** a global context names a repository-specific tool version
- **THEN** review moves that fact to the repository context

### Requirement: Prohibitions are explicit
The `## Prohibitions` section MUST contain at minimum: "Never push to main", "Never commit unless directed", "Never add `any` or type suppressions without explicit permission", "Never add emojis to code", "Never use `--no-verify` or `--no-gpg-sign` on commits". Each prohibition MUST be a single bullet line, no nested sub-bullets.

#### Scenario: Baseline prohibitions present
- **WHEN** the rendered `AGENTS.md` is read
- **THEN** each of the listed prohibitions appears verbatim as a top-level bullet in `## Prohibitions`

### Requirement: Skills section is auto-generated from the registry
The `## Skills` section MUST be produced solely from the skill registry in `skills/default.nix` and MUST NOT be hand-maintained. Each line takes the form `<name>·<description-first-sentence>`.

#### Scenario: Adding a skill updates AGENTS.md
- **WHEN** a new skill is added to the registry and the build is run
- **THEN** the regenerated `AGENTS.md` contains a new line for that skill

#### Scenario: Stale skill reference caught
- **WHEN** `AGENTS.md` references a skill name that is not in the registry (e.g., the current stale entries `nix-development`, `lua-development`, `session-completion`)
- **THEN** the build fails citing the unknown skill name

### Requirement: Claude Code context file is generated, not symlinked
The Claude Code context file MUST be generated as a regular file (`~/.claude/CLAUDE.md`) from `instructions.nix`. It SHALL NOT be a symlink to a repository `AGENTS.md`.

#### Scenario: Both files generated independently
- **WHEN** the build is run
- **THEN** `~/.claude/CLAUDE.md` is a regular generated file
- **AND** it contains the shared responsibility contract

### Requirement: Global contexts state the responsibility contract

Every generated global context MUST state human ownership, evidence before
handoff, independent maintainability, and the limit of model review.

#### Scenario: A harness receives global context

- **POLARITY** positive
- **WHEN** any covered harness context is evaluated
- **THEN** it contains every required responsibility rule

#### Scenario: A responsibility rule is missing

- **POLARITY** negative
- **WHEN** a rendered context omits a required responsibility rule
- **THEN** evaluation fails with the harness and missing rule named

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

