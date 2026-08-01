## ADDED Requirements

### Requirement: A harness config file that the harness writes is never a store symlink

Every harness config file that the harness itself writes at runtime MUST be
installed as a real writable file owned by `lib/managed-file.nix`. It MUST NOT
be installed as a `home.file` or `xdg.configFile` symlink into the Nix store.

#### Scenario: Owner changes a setting from inside the harness
- **POLARITY** positive
- **WHEN** the owner changes a setting from inside a harness whose config file
  is declared as a managed file
- **THEN** the harness writes the file successfully
- **AND** the change survives until the next activation

#### Scenario: A writable target is declared as a store symlink
- **POLARITY** negative
- **WHEN** a harness config declares a path in both `managedFiles` and
  `home.file` or `xdg.configFile`
- **THEN** evaluation fails with an error naming the path and both declaring
  sites

### Requirement: Activation reconciles through a three-way merge against a recorded base

`lib/managed-file.nix` MUST write the exact content it applied to a sidecar
base file next to the target. The next activation MUST merge three inputs: the
recorded base, the live file on disk, and the newly evaluated content. A key
present in the recorded base, absent from the new content, and unchanged on
disk MUST be deleted. A key absent from the recorded base and present on disk
MUST be preserved.

#### Scenario: Nix stops declaring a key
- **POLARITY** positive
- **WHEN** a key is removed from a harness config in Nix and the owner runs
  `nh darwin switch`
- **THEN** the key is deleted from the live file
- **AND** no entry in any hand-written retired-key list is required

#### Scenario: The harness added a key Nix does not declare
- **POLARITY** positive
- **WHEN** the harness wrote a key at runtime that Nix never declared
- **THEN** activation preserves that key

#### Scenario: The owner edited a key that Nix also changed
- **POLARITY** negative
- **WHEN** a key differs from the recorded base on disk AND differs from the
  recorded base in the new content
- **THEN** activation fails, reports the conflicting key and all three values,
  and leaves the live file untouched

#### Scenario: The target exists and has no sidecar base yet
- **POLARITY** positive
- **WHEN** the target file exists but no sidecar base does, which is the state
  of every target on the first activation after conversion
- **THEN** activation adopts the target once: it deep-merges the new content
  over the live file with the new content winning, writes the result, seeds the
  sidecar base from the new content, and reports the adoption
- **AND** every later activation uses the three-way merge

#### Scenario: The sidecar base exists but is unreadable
- **POLARITY** negative
- **WHEN** a sidecar base file exists but is empty or does not parse in the
  declared format
- **THEN** activation exits non-zero, leaves the live file untouched, and
  reports the path of the unusable base

### Requirement: A managed file is validated before it replaces the target

`lib/managed-file.nix` MUST write the merged result to a temporary file, run
any declared schema check against it, and move it into place only after the
check passes.

#### Scenario: Merged result satisfies the declared schema
- **POLARITY** positive
- **WHEN** a managed file declares a schema and the merged result satisfies it
- **THEN** the merged result replaces the target and the sidecar base is
  updated

#### Scenario: Merged result violates the declared schema
- **POLARITY** negative
- **WHEN** a managed file declares a schema and the merged result violates it
- **THEN** activation exits non-zero, reports the validator output, and leaves
  both the target and the sidecar base unchanged

### Requirement: Each managed file has an independent kill switch

Each managed file declaration MUST accept an `enable` flag. Setting it to
false MUST leave the target file entirely alone, so one misbehaving harness is
disabled without reverting the others.

#### Scenario: One harness is disabled
- **POLARITY** positive
- **WHEN** the owner sets `enable = false` for one managed file and runs
  `nh darwin switch`
- **THEN** that target file is neither read nor written
- **AND** every other managed file reconciles normally

#### Scenario: A disabled target is still referenced elsewhere
- **POLARITY** negative
- **WHEN** a managed file is disabled but another module interpolates its
  target path as a dependency
- **THEN** evaluation fails with an error naming the disabled target and the
  referencing site

### Requirement: Runtime edits are recoverable as Nix source

The `sysinit-llm-capture <harness>` command MUST report the difference between
the sidecar base and the live file, and MUST print the added or changed keys as
a Nix attrset on stdout. It MUST NOT write to any file under `modules/`.

#### Scenario: Owner backports an in-harness setting change
- **POLARITY** positive
- **WHEN** the owner changed a setting inside a harness and runs
  `sysinit-llm-capture <harness>`
- **THEN** stdout carries a Nix attrset containing that key and its new value
- **AND** the repository working tree is unmodified

#### Scenario: Capture is asked for an unknown or unmanaged harness
- **POLARITY** negative
- **WHEN** `sysinit-llm-capture` is given a harness name that declares no
  managed file
- **THEN** the command exits non-zero and lists the harness names that do
  declare one
