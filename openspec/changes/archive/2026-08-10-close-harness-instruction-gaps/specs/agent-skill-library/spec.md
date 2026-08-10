## MODIFIED Requirements

### Requirement: Skills install across all configured agents

Each skill from the registry MUST be installed at every enabled agent's
documented skill path, or excluded via an explicit per-agent skip list. Any
harness that reads the Claude Code skills tree natively (opencode, Crush, Amp)
MUST advertise `~/.claude/skills` as its skills root rather than a per-tool path
that contains no SKILL.md files.

A harness that can load skills only from a configured path MUST have that path
configured. Pi loads skills from its `skills` setting; that setting MUST name
the populated tree. Advertising a skills root in a harness's context file while
leaving that harness unable to load from it is a defect, not coverage.

The rule scopes to the harnesses declared in the coverage set. It MUST NOT fire
on a harness outside that set. The renderer advertises a skills root in the
Conventions section for every harness it renders, including gemini and codex,
neither of which is in scope here. Applying the rule to them would fail the
build on a harness this change does not touch.

Undeclaring a skills path MUST remove it from the live file for a harness whose
settings are written by a deep merge. Pi is such a harness. Removing the
`skills` entry from Nix leaves the key on disk, so the retired-key mechanism
applies to it.

The coverage assertion MUST read the rendered settings value, not a
hand-declared entry in a parallel attribute set. A hand-declared entry stays
true after the setting is dropped, because the live file preserves the old
value and hides the drop. Reading the rendered value makes the drop a build
failure.

#### Scenario: Multi-agent skill placement

- **POLARITY** positive
- **WHEN** the registry contains skill `<name>` and both
  `programs.claude-code.enable` and `programs.codex.enable` are true
- **THEN** the skill is present at both `~/.claude/skills/<name>/SKILL.md` and
  the codex-equivalent path

#### Scenario: Pi loads the shared tree

- **POLARITY** positive
- **WHEN** the pi settings file is rendered
- **THEN** its `skills` array names the populated skills tree
- **AND** a pi session lists the registry skills as `/skill:<name>` commands

#### Scenario: Explicit per-agent skip

- **POLARITY** negative
- **WHEN** a skill declares `skip = [ "codex" ];` in its registry entry
- **THEN** the skill is installed for claude but not for codex

#### Scenario: Native-reader harness advertises a populated skills root

- **POLARITY** positive
- **WHEN** a harness that reads the Claude Code skills tree natively renders its
  instructions
- **THEN** the advertised skills root is `~/.claude/skills`
- **AND** that directory contains the SKILL.md files produced from the registry

#### Scenario: An advertised root a harness cannot load fails the build

- **POLARITY** negative
- **WHEN** a harness in the coverage set advertises a skills root, and that
  harness neither reads the root natively nor has it configured
- **THEN** the build fails and names the harness and the root

#### Scenario: A harness outside the coverage set is not judged

- **POLARITY** negative
- **WHEN** gemini or codex renders the advertised skills root while remaining
  outside the coverage set
- **THEN** the build does not fail on that harness
- **AND** the rule applies only once that harness is declared
