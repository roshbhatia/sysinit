# agent-skill-library Specification

## Purpose
TBD - created by archiving change supercharge-agent-skills. Update Purpose after archive.
## Requirements
### Requirement: Skill registry is the single source of truth
The skill registry at `modules/home/programs/llm/skills/default.nix` SHALL be the only place where globally-installed agent skills are declared. Each entry MUST map a kebab-case skill name to a `{ description, content }` attrset, where `content` is imported from a sibling `.nix` file returning the SKILL.md body as a string.

#### Scenario: Adding a new global skill
- **WHEN** a contributor adds a new entry `<name> = { description = "..."; content = import ./<name>.nix; };` to `skills/default.nix` and rebuilds home-manager
- **THEN** the file `~/.claude/skills/<name>/SKILL.md` exists with the content from `<name>.nix`
- **AND** the skill description appears in the agent's compact skill index produced by `instructions.nix`

#### Scenario: Skills outside the registry are not installed
- **WHEN** a `.nix` file exists in `modules/home/programs/llm/skills/` but is not referenced by `default.nix`
- **THEN** no corresponding `SKILL.md` is generated and the skill is not advertised to agents

### Requirement: Required global skills are installed by default
The registry MUST include, at minimum, the following skill names installed for every user of this dotfiles repo: `shell-script-authoring`, `openspec-propose`, `openspec-apply`, `openspec-explore`, `openspec-archive`, `skills-ecosystem-discovery`, `feature-based-session-manager`, `search-code-routing`.

#### Scenario: Fresh install includes baseline skills
- **WHEN** a user runs `nh os switch` on a freshly cloned sysinit checkout
- **THEN** every required skill name above has a corresponding `~/.claude/skills/<name>/SKILL.md` file

#### Scenario: Removing a required skill is rejected at build time
- **WHEN** a contributor deletes one of the required skill entries from `skills/default.nix` and runs `nix flake check`
- **THEN** the build fails with an assertion identifying the missing required skill name

### Requirement: Skills install across all configured agents
For every agent module enabled in `modules/home/programs/llm/config/` (claude, codex, gemini, cursor, opencode, etc.), each skill from the registry MUST be installed at that agent's documented skill path, or excluded via an explicit per-agent skip list.

#### Scenario: Multi-agent skill placement
- **WHEN** the registry contains skill `<name>` and both `programs.claude-code.enable` and `programs.codex.enable` are true
- **THEN** the skill is present at both `~/.claude/skills/<name>/SKILL.md` and the codex-equivalent path

#### Scenario: Explicit per-agent skip
- **WHEN** a skill declares `skip = [ "codex" ];` in its registry entry
- **THEN** the skill is installed for claude but not for codex

### Requirement: External skills are vendored reproducibly
Skills sourced from third-party repositories (`anthropics/skills`, `vercel-labs/skills`, etc.) MUST be vendored via Nix fetchers (`pkgs.fetchurl`, `pkgs.fetchFromGitHub`) with content-addressed hashes pinned in the repo. Symlinks into untracked directories such as `~/.agents/skills/` SHALL NOT be the source of truth for any required skill.

#### Scenario: skills-ecosystem-discovery is reproducible
- **WHEN** the build is run on a machine that has no pre-existing `~/.agents/` directory
- **THEN** the `skills-ecosystem-discovery` SKILL.md is still produced from the vendored upstream copy

#### Scenario: Hash drift is caught
- **WHEN** the upstream tarball for a vendored skill changes content
- **THEN** the Nix build fails with a hash mismatch error rather than silently picking up new content

### Requirement: Skill artifacts are gitignored at the user level
The global gitignore at `~/.config/git/ignore` MUST exclude `**/.claude/`, `**/.agents/`, and `**/openspec/` so that skill files and OpenSpec artifacts dropped into user projects do not leak into per-project commits.

#### Scenario: Skill artifacts in a foreign repo are ignored
- **WHEN** an agent writes `~/code/some-other-repo/.claude/skills/example/SKILL.md` during a session
- **THEN** `git status` in that repo shows no untracked changes for the skill

