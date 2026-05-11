## ADDED Requirements

### Requirement: AGENTS.md and per-agent context files share one source
`AGENTS.md` at the repository root and every per-agent context file (CLAUDE.md, GEMINI.md, codex `instructions.md`, etc.) MUST be generated from `modules/home/programs/llm/lib/instructions.nix`. The repository SHALL NOT contain hand-edited `AGENTS.md` or `CLAUDE.md` content that diverges from what `instructions.nix` produces.

#### Scenario: Regenerated AGENTS.md matches source
- **WHEN** `nix build .#agents-md` is run
- **THEN** the generated content is byte-identical to the committed `AGENTS.md`

#### Scenario: Hand-edit drift caught
- **WHEN** a contributor edits `AGENTS.md` directly without changing `instructions.nix`
- **THEN** `nix flake check` fails reporting a drift between source and generated file

### Requirement: Context files follow the May 2026 AGENTS.md standard
Generated context files MUST contain only the following top-level sections, in order: `Stack`, `Commands`, `Conventions`, `Skills`, `Prohibitions`, `Context`. The file MUST NOT contain an "Architecture", "Repository Structure", "Repository Layout", or other architectural-overview section. The total length of any single generated context file MUST be ≤200 lines.

#### Scenario: Conformant structure
- **WHEN** the generated `AGENTS.md` is parsed
- **THEN** its `##` headings are exactly `Stack`, `Commands`, `Conventions`, `Skills`, `Prohibitions`, `Context` in that order

#### Scenario: Architectural section rejected
- **WHEN** `instructions.nix` introduces a `## Repository Structure` section
- **THEN** the build fails citing the prohibited section

#### Scenario: Length cap enforced
- **WHEN** the rendered context file exceeds 200 lines
- **THEN** the build fails reporting the actual line count

### Requirement: Stack section enumerates exact versions and commands
The `## Stack` section MUST list each tool with its pinned version from the Nix flake (e.g., `openspec 1.3.0`, `nixfmt-rfc-style`, `nodejs <version>`). The `## Commands` section MUST list each command as a fenced bash block with the exact flags the agent should use; commands without flags SHALL include a one-line note describing the expected effect.

#### Scenario: Version drift caught
- **WHEN** the openspec overlay is bumped to 1.4.0 but `instructions.nix` still prints 1.3.0
- **THEN** `nix flake check` fails reporting the version mismatch

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
The Claude Code context file MUST be generated as a regular file (`~/.claude/CLAUDE.md`) with content derived from the same source as `AGENTS.md`, plus Claude-Code-specific extensions appended after the shared sections. The file SHALL NOT be a symlink to `AGENTS.md`.

#### Scenario: Both files generated independently
- **WHEN** the build is run
- **THEN** `AGENTS.md` and `~/.claude/CLAUDE.md` are both regular files
- **AND** their shared sections (`Stack`, `Commands`, `Conventions`, `Skills`, `Prohibitions`, `Context`) are byte-identical
