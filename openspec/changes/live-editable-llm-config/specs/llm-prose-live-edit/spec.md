## ADDED Requirements

### Requirement: A skill is a self-describing Markdown directory

Each local skill MUST live at `modules/home/programs/llm/skills/<name>/` with
`SKILL.md` at its root. `SKILL.md` MUST carry the skill metadata as flat YAML
frontmatter. Helper scripts and reference documents MUST be sibling files in
the same directory. No skill body may be stored as a Nix string.

#### Scenario: Frontmatter carries the metadata
- **POLARITY** positive
- **WHEN** a skill declares `description`, and optionally `allowed-tools`,
  `when_to_use`, `model`, and `effort`, in its `SKILL.md` frontmatter
- **THEN** the rendered skill for each harness carries the fields that harness
  accepts
- **AND** `lib/instructions.nix` reads the same `description` for the compact
  skill index

#### Scenario: Frontmatter is nested or malformed
- **POLARITY** negative
- **WHEN** a skill's frontmatter is absent, is not closed, or contains a nested
  value rather than flat `key: value` pairs
- **THEN** `nix flake check` fails with an error naming the skill and the
  offending line

### Requirement: The renderer runs without Nix evaluation

`sysinit-llm-render` MUST read the skill source tree and write one rendered
tree per harness under `$XDG_STATE_HOME/sysinit/llm/skills/<harness>/`. It MUST
NOT invoke `nix`, `nix-build`, or `nix eval`. Home Manager MUST run the same
script at activation, so a switch and a direct run produce identical output.

#### Scenario: Owner edits a skill body and reruns the renderer
- **POLARITY** positive
- **WHEN** the owner edits `skills/<name>/SKILL.md` and runs
  `sysinit-llm-render`
- **THEN** the rendered file under the state directory reflects the edit
- **AND** no rebuild or switch is required

#### Scenario: Activation output differs from a direct run
- **POLARITY** negative
- **WHEN** `nix flake check` renders the skill tree in a sandbox and compares
  it against the tree the activation path produces
- **THEN** any byte difference fails the check and names the differing file

#### Scenario: The renderer cannot write the state directory
- **POLARITY** negative
- **WHEN** `$XDG_STATE_HOME/sysinit/llm/skills/` is unwritable
- **THEN** the renderer exits non-zero, reports the path, and leaves any
  previously rendered tree intact

### Requirement: Editing a skill body needs no rebuild

Each local skill MUST be installed at every harness skill root as an
out-of-store directory symlink pointing at that harness's rendered tree. Adding
or removing a skill directory is a structural change and MAY require a switch.
Editing the body of an existing skill MUST NOT.

#### Scenario: Body edit reaches the harness immediately
- **POLARITY** positive
- **WHEN** the owner edits an existing skill body and runs
  `sysinit-llm-render`
- **THEN** `~/.claude/skills/<name>/SKILL.md` resolves to the updated content
- **AND** the Amp, Devin, and Copilot skill roots resolve to their own updated
  renders

#### Scenario: A new skill directory is added without a switch
- **POLARITY** negative
- **WHEN** a new skill directory is created and the renderer runs, but no
  switch has happened
- **THEN** the rendered tree contains the new skill
- **AND** no symlink exists at any harness skill root for it, because the link
  set is structural

### Requirement: Vendored skills stay Nix-managed

Skills sourced from `inputs.specutil` and `inputs.ast-grep-skills` MUST remain
Nix store symlinks installed by `home.file`. The renderer MUST NOT write to any
path that a vendored skill owns.

#### Scenario: Vendored and local skills coexist in one root
- **POLARITY** positive
- **WHEN** activation completes
- **THEN** `~/.claude/skills/` contains store symlinks for the vendored skills
  and out-of-store symlinks for the local skills

#### Scenario: A local skill name collides with a vendored skill name
- **POLARITY** negative
- **WHEN** a local skill directory uses a name that a vendored skill already
  claims
- **THEN** evaluation fails with an error naming the collision and both
  sources

### Requirement: The Claude render remains the lossless superset

The Claude render MUST carry every frontmatter field the source declares. Every
other harness render MUST be derivable from the same source without consulting
any additional input.

#### Scenario: Claude-only fields are dropped for Amp
- **POLARITY** positive
- **WHEN** a skill declares `model` and `effort`
- **THEN** the Claude render carries both fields
- **AND** the Amp, Devin, and Copilot renders carry neither

#### Scenario: A field is declared that no render accepts
- **POLARITY** negative
- **WHEN** a skill declares a frontmatter key outside the allowed set
- **THEN** both the renderer and `nix flake check` fail, naming the skill and
  the unknown key
