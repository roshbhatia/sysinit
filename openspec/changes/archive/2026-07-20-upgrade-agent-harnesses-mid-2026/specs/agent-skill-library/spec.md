## MODIFIED Requirements

### Requirement: Skills install across all configured agents

Each skill from the registry MUST be installed at every enabled agent's documented skill path (claude, codex, gemini, cursor, opencode, crush, etc.), or excluded via an explicit per-agent skip list, AND any harness that reads the Claude Code skills tree natively (opencode, Crush, Amp) MUST advertise `~/.claude/skills` as its skills root rather than a per-tool path that contains no SKILL.md files.

#### Scenario: Multi-agent skill placement

- **WHEN** the registry contains skill `<name>` and both
  `programs.claude-code.enable` and `programs.codex.enable` are true
- **THEN** the skill is present at both `~/.claude/skills/<name>/SKILL.md` and
  the codex-equivalent path

#### Scenario: Explicit per-agent skip

- **WHEN** a skill declares `skip = [ "codex" ];` in its registry entry
- **THEN** the skill is installed for claude but not for codex

#### Scenario: Native-reader harness advertises a populated skills root

- **WHEN** a harness that reads the Claude Code skills tree natively (opencode,
  Crush) renders its instructions via `mkInstructions`
- **THEN** the advertised skills root is `~/.claude/skills`
- **AND** that directory contains the SKILL.md files produced from the registry
- **AND** no enabled harness advertises a skills root directory that contains
  no SKILL.md files
