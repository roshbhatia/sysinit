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

