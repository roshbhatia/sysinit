## ADDED Requirements

### Requirement: WezTerm chords are declared once in Nix

The chord half of every WezTerm binding, meaning its key and its modifier set,
MUST be declared in Nix. The declaration MUST render to a list that
`keybindings.lua` reads at load time and to a list that the cross-layer
collision assertion in `modules/darwin/keybindings.nix` consumes.

The action half stays in Lua. A WezTerm action is a closure over
`wezterm.action_callback` and cannot be expressed in Nix.

The rendering target is `wezterm/config.json`, which
`modules/home/programs/wezterm/default.nix` already writes and
`plugin_loader.lua` already reads.

#### Scenario: One declaration reaches both consumers

- **POLARITY** positive
- **WHEN** a maintainer adds a chord to the Nix declaration
- **THEN** `keybindings.lua` binds it
- **AND** the collision assertion evaluates it against the other layers

#### Scenario: A Lua-only chord is rejected

- **POLARITY** negative
- **WHEN** a chord is bound in `keybindings.lua` with no matching entry in the
  Nix declaration
- **THEN** the build fails and names the undeclared chord
- **AND** the maintainer is directed to the Nix declaration

### Requirement: WezTerm chords take part in the cross-layer collision check

The collision assertion currently spans symbolic hotkeys, aerospace bindings,
and hand-listed reserved chords. WezTerm MUST become a fourth layer in that
assertion. A WezTerm chord that matches a reserved chord or an enabled symbolic
hotkey MUST fail evaluation.

The bug that motivated the assertion was a Hammerspoon chord swallowing a
WezTerm binding. WezTerm is the layer the assertion does not yet model.

#### Scenario: A non-colliding chord set evaluates

- **POLARITY** positive
- **WHEN** no WezTerm chord matches another layer
- **THEN** evaluation succeeds

#### Scenario: A WezTerm chord colliding with a reserved chord fails

- **POLARITY** negative
- **WHEN** a WezTerm binding claims a chord listed in `reservedChords`
- **THEN** evaluation fails
- **AND** the message names the chord and both owning layers

#### Scenario: A WezTerm chord colliding with a symbolic hotkey fails

- **POLARITY** negative
- **WHEN** a WezTerm binding claims a chord an enabled symbolic hotkey holds
- **THEN** evaluation fails and names both

### Requirement: Duplicate WezTerm chords are rejected

`merge_keys` concatenates seven binding groups. A chord bound in two groups is
resolved silently by WezTerm, so one binding never fires and nothing reports
it. Two declarations of one chord MUST fail evaluation.

#### Scenario: Distinct chords merge

- **POLARITY** positive
- **WHEN** every declared chord is unique
- **THEN** evaluation succeeds and the merged table holds every binding

#### Scenario: A duplicate chord fails evaluation

- **POLARITY** negative
- **WHEN** two binding groups both declare `CTRL+w`
- **THEN** evaluation fails
- **AND** the message names the chord and both groups

### Requirement: The chord vocabulary is shared across layers

The layers spell the same chord differently. Symbolic hotkeys use numeric key
codes and a modifier bitmask. Aerospace uses `alt-shift-1`. WezTerm uses
`SUPER|SHIFT` and key names such as `UpArrow`. A single canonicalization MUST
map every layer onto one vocabulary, extending the existing `mkChord`,
`keyAliases`, and `canonicalKey` helpers rather than adding a parallel set.

#### Scenario: Equivalent spellings canonicalize to one chord

- **POLARITY** positive
- **WHEN** WezTerm declares `SUPER|SHIFT` with key `UpArrow` and another layer
  declares the same chord in its own spelling
- **THEN** both canonicalize to the same string
- **AND** the collision is detected

#### Scenario: An unmapped key name fails loudly

- **POLARITY** negative
- **WHEN** a WezTerm chord uses a key name the canonicalization does not know
- **THEN** evaluation fails and names the unmapped key
- **AND** the chord is not silently treated as unique
