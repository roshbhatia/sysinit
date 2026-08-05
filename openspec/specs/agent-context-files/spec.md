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
Generated context files MUST contain `Conventions`, optional `Skills`, `Responsibility`, and `Prohibitions` in that order. Harnesses without a native output-style layer append `Output Style`. The shared context MUST remain at or below 45 lines before the output style.

#### Scenario: Conformant structure
- **WHEN** the generated `AGENTS.md` is parsed
- **THEN** its shared headings place `Responsibility` before `Prohibitions`

#### Scenario: Architectural section rejected
- **WHEN** `instructions.nix` introduces a `## Repository Structure` section
- **THEN** the build fails citing the prohibited section

#### Scenario: Length cap enforced
- **WHEN** the shared rendered context exceeds 45 lines
- **THEN** the build fails reporting the actual line count

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
