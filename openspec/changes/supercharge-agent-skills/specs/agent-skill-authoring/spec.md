## ADDED Requirements

### Requirement: SKILL.md frontmatter conforms to the May 2026 spec
Every SKILL.md generated from the registry MUST contain exactly two required frontmatter fields, `name` and `description`, and MAY contain the optional fields `allowed-tools`, `when_to_use`, and `disable-model-invocation`. The fields `license`, `compatibility`, `version`, `metadata`, `author`, and `generatedBy` SHALL NOT be emitted. The `name` field MUST be ≤64 characters, lowercase ASCII letters/digits/hyphens, and SHALL NOT contain the substrings `anthropic` or `claude`.

#### Scenario: Conformant frontmatter
- **WHEN** the registry entry for skill `example` declares only `description`
- **THEN** the generated frontmatter contains exactly `name: example` and `description: ...` and no other keys

#### Scenario: Legacy fields rejected
- **WHEN** a contributor adds `license = "MIT";` to a skill registry entry
- **THEN** `nix flake check` fails with an error pointing at the disallowed field

#### Scenario: Invalid name rejected
- **WHEN** a skill name is `Claude-Helper` or `my_skill` or exceeds 64 characters
- **THEN** the build fails with a message identifying the offending name and rule

### Requirement: Descriptions are trigger-rich and third-person
The `description` field MUST be written in third person and MUST enumerate the user-visible triggers (verbs, nouns, situations) that should cause the agent to select the skill. Descriptions SHALL be ≤1024 characters. The phrases "I ", "my ", "you should", and ALL-CAPS imperatives such as "ALWAYS" or "NEVER" SHALL NOT appear in the description.

#### Scenario: Compliant description
- **WHEN** the description is "Generates an OpenSpec proposal with proposal, design, and tasks artifacts. Use when the user says 'propose a change', mentions OpenSpec, asks to scope new work, or wants to capture a design before implementation."
- **THEN** the linter passes

#### Scenario: First-person description rejected
- **WHEN** the description begins with "I'll create..."
- **THEN** the build fails with a message identifying the first-person violation

### Requirement: SKILL.md bodies obey length and reference-depth caps
Each SKILL.md body (excluding frontmatter) MUST be ≤500 lines. Reference files linked from a SKILL.md MUST live in the same skill directory and SHALL be reachable in at most one link hop from SKILL.md. Reference files >100 lines MUST begin with a table of contents enumerating their top-level sections.

#### Scenario: Overlong skill caught
- **WHEN** a generated SKILL.md body exceeds 500 lines
- **THEN** the build fails identifying the skill name and line count

#### Scenario: Nested reference caught
- **WHEN** SKILL.md links to `helpers.md`, which itself links to `internals.md` referenced only from `helpers.md`
- **THEN** the build fails citing the prohibited second hop

### Requirement: Optional tool hints are declared explicitly
When a skill declares `allowed-tools` in its registry entry, the value MUST be a space-separated string of tool patterns following Claude Code conventions (`Bash(<prefix>:*)`, `Read`, `Edit`, `Write`, fully-qualified `ServerName:tool_name` for MCP tools).

#### Scenario: Well-formed allowed-tools
- **WHEN** the registry entry contains `allowed-tools = "Bash(git:*) Bash(openspec:*) Read"`
- **THEN** the rendered frontmatter contains the same value verbatim

#### Scenario: Malformed tool pattern rejected
- **WHEN** `allowed-tools` contains an entry like `bash git`, missing the `(prefix:*)` shape
- **THEN** the build fails identifying the malformed entry

### Requirement: Trigger description appears in the agent's skill index
The compact skill index emitted by `instructions.nix` MUST list each globally-installed skill exactly once as `<name>·<description-first-sentence>`, in a single section labelled `## Skills|<skillsRoot>`. The same content SHALL be emitted for every agent that has a context file (CLAUDE.md, AGENTS.md, GEMINI.md, codex `instructions.md`).

#### Scenario: Skill appears in CLAUDE.md
- **WHEN** the registry contains a skill named `seshy`
- **THEN** the generated `~/.claude/CLAUDE.md` contains a line in the `## Skills|~/.claude/skills` section starting with `seshy·`
