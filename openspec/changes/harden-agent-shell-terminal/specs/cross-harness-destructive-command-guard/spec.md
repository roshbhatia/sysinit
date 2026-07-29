## MODIFIED Requirements

### Requirement: Destructive command patterns are defined once and shared

The destructive-command deny patterns (force-push including force-with-lease,
`--no-verify`, `--no-gpg-sign`, `git reset --hard`, `git clean -f`,
`git branch -D`) MUST be defined once in `lib/allowlist.nix` and consumed by
each guarded harness through a per-harness formatter, mirroring the existing
`tierA`/`tierB` pattern.

The guard scripts are consumers, not exceptions. `claude-bash-guard.sh` MUST
receive its patterns from `destructiveDenyRegexes` rather than inlining its own
copies. The guard's pattern list MUST be generated at build time from the
shared list, so a pattern cannot exist in the script and not in the list, or
differ in form between them.

Today the script inlines six regexes of its own and four of them have drifted
from the shared list. As one example, the shared list matches
`-f([[:space:]]|$)` while the script requires a leading space,
`[[:space:]]-f([[:space:]]|$)`.

#### Scenario: Single source of deny patterns

- **POLARITY** positive
- **WHEN** a maintainer adds a new destructive pattern
- **THEN** it is added once in `lib/allowlist.nix`
- **AND** every guarded harness picks it up through its formatter
- **AND** the guard scripts pick it up through their generated pattern list

#### Scenario: A guard script cannot hold a private pattern

- **POLARITY** negative
- **WHEN** a maintainer writes a deny pattern directly into a guard script
  instead of into `lib/allowlist.nix`
- **THEN** the build fails
- **AND** the maintainer is directed to the shared list

#### Scenario: Drift between the script and the shared list is detected

- **POLARITY** negative
- **WHEN** the script's effective pattern set differs from
  `destructiveDenyRegexes`
- **THEN** the check fails and names each differing pattern

## ADDED Requirements

### Requirement: The deny set is verified by fixtures

A `nix flake check` derivation MUST run every guard script against a fixture
table. Each fixture pairs a command string with the expected decision. The
check MUST assert both directions: every prohibited form is denied, and every
permitted form passes through.

The permitted set MUST include the forms this repository deliberately allows,
in particular plain `git push` and `git push origin main`. A guard that denies
those is a regression, and only a fixture states that as a fact.

#### Scenario: A prohibited form is denied

- **POLARITY** positive
- **WHEN** the fixture runs `git push --force-with-lease origin main` through
  the guard
- **THEN** the guard emits a deny decision
- **AND** the reason names the prohibition

#### Scenario: A permitted form passes

- **POLARITY** positive
- **WHEN** the fixture runs `git push origin main` through the guard
- **THEN** the guard emits no decision and exits zero

#### Scenario: A weakened pattern fails the check

- **POLARITY** negative
- **WHEN** a change to the shared pattern list stops matching
  `git reset --hard`
- **THEN** the fixture check fails and names the fixture that regressed

#### Scenario: An over-broad pattern fails the check

- **POLARITY** negative
- **WHEN** a change to the shared pattern list starts denying plain
  `git push origin main`
- **THEN** the fixture check fails and names the permitted form that was denied

### Requirement: The guard stays fail-open under fixture verification

Adding fixtures MUST NOT change the guard's fail-open contract. A malformed
event, a missing field, or an unparseable payload MUST still exit zero without
a decision. The fixtures MUST assert this rather than leaving it to the
comment.

#### Scenario: A well-formed event yields a decision

- **POLARITY** positive
- **WHEN** the guard receives a well-formed `PreToolUse` event for a prohibited
  command
- **THEN** it emits a deny decision and exits zero

#### Scenario: A malformed event does not block

- **POLARITY** negative
- **WHEN** the guard receives input that is not valid JSON
- **THEN** it emits no decision and exits zero
- **AND** the agent's command is not blocked by the guard failure
