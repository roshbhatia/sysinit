## MODIFIED Requirements

### Requirement: Skill registry is the single source of truth
The skill source tree at `modules/home/programs/llm/skills/` SHALL be the only
place where globally-installed agent skills are declared. Each local skill MUST
be a directory `skills/<name>/` whose `SKILL.md` carries the skill metadata as
flat YAML frontmatter and the skill body below it. `skills/default.nix` SHALL
scan that tree rather than enumerate entries by hand, and SHALL NOT store any
skill body as a Nix string.

#### Scenario: Adding a new global skill
- **POLARITY** positive
- **WHEN** a contributor creates `skills/<name>/SKILL.md` with a `description`
  in its frontmatter and rebuilds home-manager
- **THEN** `~/.claude/skills/<name>` resolves to the rendered skill for that
  name
- **AND** the skill description appears in the agent's compact skill index
  produced by `instructions.nix`

#### Scenario: Editing an existing skill body
- **POLARITY** positive
- **WHEN** a contributor edits the body of an existing `skills/<name>/SKILL.md`
  and runs `sysinit-llm-render`
- **THEN** every harness skill root serves the updated body
- **AND** no rebuild or switch is required

#### Scenario: A directory without a conforming SKILL.md
- **POLARITY** negative
- **WHEN** a directory exists under `skills/` but holds no `SKILL.md`, or its
  `SKILL.md` has no closed flat frontmatter block
- **THEN** `nix flake check` fails with an error naming the directory
- **AND** no skill is installed or advertised for that name

### Requirement: Required global skills are installed by default
The skill source tree MUST include, at minimum, the following skill names
installed for every user of this dotfiles repo: `shell-script-authoring`,
`skills-ecosystem-discovery`, `feature-based-session-manager`,
`search-code-routing`.

#### Scenario: Fresh install includes baseline skills
- **POLARITY** positive
- **WHEN** a user runs `nh darwin switch` on a freshly cloned sysinit checkout
- **THEN** every required skill name above resolves to a readable `SKILL.md`
  under `~/.claude/skills/<name>/`

#### Scenario: Removing a required skill is rejected at build time
- **POLARITY** negative
- **WHEN** a contributor deletes one of the required skill directories from
  `skills/` and runs `nix flake check`
- **THEN** the build fails with an assertion identifying the missing required
  skill name
