## MODIFIED Requirements

### Requirement: Required global skills are installed by default

The registry MUST include, at minimum, the following skill names installed
for every user of this dotfiles repo: `shell-scripting`, `openspec-propose`,
`openspec-apply`, `openspec-explore`, `openspec-archive`, `find-skills`,
`seshy`, `cocoindex-query`. The `cocoindex-query` skill MUST be the
active-routing variant defined in this change — it instructs agents to
prefer cocoindex MCP search for semantic queries and to fall back to
`rg`/`grep` for literal-string matches. The previous passive variant that
treated cocoindex availability as optional is removed.

#### Scenario: Fresh install includes baseline skills

- **WHEN** a user runs `nh os switch` on a freshly cloned sysinit checkout
- **THEN** every required skill name above has a corresponding
  `~/.claude/skills/<name>/SKILL.md` file
- **AND** the `cocoindex-query` SKILL.md describes cocoindex as a primary
  search mechanism, not a conditional one

#### Scenario: Removing a required skill is rejected at build time

- **WHEN** a contributor deletes one of the required skill entries from
  `skills/default.nix` and runs `nix flake check`
- **THEN** the build fails with an assertion identifying the missing
  required skill name

#### Scenario: Skill instructions reflect first-class routing

- **WHEN** the rendered `cocoindex-query` SKILL.md is inspected after
  `nh os switch`
- **THEN** it explicitly states that cocoindex MCP search is the
  preferred path for intent-based / semantic queries and that `rg`/`grep`
  is the fallback for literal-string matches
- **AND** it instructs the agent to pass `refresh_index=True` on the
  first search call within a new project to bootstrap a missing index
- **AND** it instructs the agent to fall back to `rg`/`grep` if the
  bootstrap or any search call errors

#### Scenario: Stale passive variant is rejected

- **WHEN** the rendered `cocoindex-query` SKILL.md still contains the
  passive guidance language from the prior variant (e.g., wording that
  treats cocoindex as optional or that conditions its use on detecting a
  service)
- **THEN** the change is incomplete; the skill MUST be updated to the
  active-routing form before the change is archived
