## ADDED Requirements

### Requirement: A doctor command reports build-to-runtime drift

A `sysinit doctor` command MUST report drift between the built configuration
and the running machine. It MUST cover the class of failure that build-time
checks cannot see, because that state exists only after a switch.

The command MUST be packaged the way the other operator scripts are, following
`modules/home/programs/llm/config/notify.nix:77`.

#### Scenario: A healthy machine reports clean

- **POLARITY** positive
- **WHEN** the running machine matches the built configuration
- **THEN** the command reports every probe as passing
- **AND** it exits zero

#### Scenario: Drift is reported and fails the exit code

- **POLARITY** negative
- **WHEN** at least one probe finds drift
- **THEN** the command names the probe, the expected state, and the observed
  state
- **AND** it exits non-zero

### Requirement: The doctor reports the shell escape hatches

`~/.zshenv`, `~/.zshsecrets`, and every file under
`$XDG_CONFIG_HOME/zsh/extras/` are sourced unconditionally and are not managed
by Nix. The command MUST list the ones present, because they are the surface
that explains an unexpected shell without appearing in any module.

The command MUST NOT modify them. They stay owner-managed.

#### Scenario: Present escape hatches are listed

- **POLARITY** positive
- **WHEN** `~/.zshenv` and two files under `extras/` exist
- **THEN** the command lists all three with their paths

#### Scenario: An unreadable escape hatch is reported, not fatal

- **POLARITY** negative
- **WHEN** a file under `extras/` exists but cannot be read
- **THEN** the command reports it as unreadable
- **AND** it continues running the remaining probes

### Requirement: The doctor reports stale shell evaluation caches

`evalcache` stores the output of `eval "$(tool init)"` and has no invalidation
tied to the system generation. An entry cached against a removed store path
produces a shell that silently loses an integration.

The command MUST report cache entries whose recorded source no longer resolves.

#### Scenario: A resolvable cache is reported as current

- **POLARITY** positive
- **WHEN** every evalcache entry references a store path that exists
- **THEN** the command reports the cache as current

#### Scenario: A cache entry pointing at a removed store path is reported

- **POLARITY** negative
- **WHEN** an evalcache entry references a store path that no longer exists
- **THEN** the command reports the entry and names the removal command
- **AND** the command does not delete the entry on its own

### Requirement: The doctor reports agent bus health

The command MUST report the per-pane agent state files: how many exist, how
many name a live pane, and how many are stale. This makes the collection
behavior observable rather than inferred.

#### Scenario: Live entries are counted

- **POLARITY** positive
- **WHEN** two panes are running agents
- **THEN** the command reports two live entries

#### Scenario: A malformed state file is reported, not fatal

- **POLARITY** negative
- **WHEN** a state file is not valid JSON
- **THEN** the command reports the file as malformed
- **AND** it continues counting the remaining entries
- **AND** it exits non-zero
