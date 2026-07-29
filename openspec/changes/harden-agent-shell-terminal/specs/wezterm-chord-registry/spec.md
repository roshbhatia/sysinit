## ADDED Requirements

### Requirement: WezTerm chords are read from the bindings, not mirrored

The chord set used for collision detection MUST be derived from
`keybindings.lua` itself, by loading it outside the WezTerm host and reading
back the bindings it produces. It MUST NOT be a second copy of the chords
maintained by hand alongside the Lua.

A hand-maintained mirror drifts. The same repository already demonstrated the
failure: `lib/allowlist.nix` declared the destructive-command patterns as the
single source while `claude-bash-guard.sh` inlined its own copies, and five of
the six had diverged before anyone noticed.

Bindings that cannot be loaded headlessly MAY be declared, provided the
declaration names the reason.

#### Scenario: The chord set matches the bindings

- **POLARITY** positive
- **WHEN** the check runs against `keybindings.lua`
- **THEN** it extracts every chord the module binds
- **AND** no chord list is maintained separately from the bindings

#### Scenario: A new binding is covered without editing the check

- **POLARITY** positive
- **WHEN** a maintainer adds a binding to any group in `keybindings.lua`
- **THEN** the check sees the new chord on the next run

#### Scenario: Extraction failure is not silent

- **POLARITY** negative
- **WHEN** the module changes so that it no longer loads under the stub
- **THEN** the check fails and says the stub has drifted
- **AND** it does not report success against a partial chord set

#### Scenario: Under-extraction is rejected

- **POLARITY** negative
- **WHEN** extraction succeeds but returns implausibly few chords
- **THEN** the check fails rather than reporting no collisions over a short list

### Requirement: WezTerm takes part in cross-layer collision detection

A WezTerm chord that matches a reserved chord or an enabled symbolic hotkey
MUST fail the build, unless it is recorded as an accepted overlap with a stated
reason.

The bug that motivated the cross-layer assertion was a Hammerspoon chord
silently swallowing a WezTerm binding. WezTerm was the layer the assertion did
not model.

Both sides MUST canonicalize chords through one shared definition. Two spellings
of the same chord would read as two different chords and the collision would go
undetected.

#### Scenario: A non-colliding chord set passes

- **POLARITY** positive
- **WHEN** no WezTerm chord matches another layer
- **THEN** the check succeeds and reports the number of chords compared

#### Scenario: A collision with a reserved chord fails

- **POLARITY** negative
- **WHEN** a WezTerm binding claims a chord listed in `reservedChords`
- **THEN** the check fails and names the chord
- **AND** the message says to rebind it or record it as an accepted overlap

#### Scenario: A collision with an enabled symbolic hotkey fails

- **POLARITY** negative
- **WHEN** a WezTerm binding claims a chord an enabled symbolic hotkey holds
- **THEN** the check fails and names the chord

#### Scenario: An accepted overlap does not fail the build

- **POLARITY** positive
- **WHEN** a known overlap is listed with a reason
- **THEN** the check passes
- **AND** the overlap stays visible in the source rather than being silently
  tolerated

### Requirement: Aerospace collisions are prevented by invariant

Aerospace binds every chord with ALT and WezTerm binds none. Rather than compare
the two lists, the check MUST assert that WezTerm claims no ALT chord at all,
which makes an aerospace collision impossible by construction.

#### Scenario: No ALT chord passes

- **POLARITY** positive
- **WHEN** no WezTerm binding uses ALT
- **THEN** the invariant holds and aerospace cannot collide

#### Scenario: An ALT binding fails and points at aerospace

- **POLARITY** negative
- **WHEN** a WezTerm binding starts using an ALT chord
- **THEN** the check fails and names the chord
- **AND** the message directs the maintainer to `modules/darwin/aerospace.nix`

### Requirement: Duplicate WezTerm chords are rejected

`merge_keys` concatenates seven binding groups. A chord bound in two groups is
resolved silently by WezTerm, so one binding never fires and nothing reports it.
Two bindings of one chord MUST fail the build.

#### Scenario: Distinct chords pass

- **POLARITY** positive
- **WHEN** every extracted chord is unique
- **THEN** the check succeeds

#### Scenario: A duplicate chord fails

- **POLARITY** negative
- **WHEN** two binding groups both bind the same chord
- **THEN** the check fails and names it
