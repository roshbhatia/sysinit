## MODIFIED Requirements

### Requirement: Upstream extension list excludes confirm-destructive

The `extensions` list in `pi.nix` that vendors upstream `.ts` files MUST NOT
include `confirm-destructive`, which `@gotgenes/pi-permission-system` replaces.

It MUST also NOT include `notify`. That extension raises its own OSC 777 toast
and is one of the four producers the single-producer rule retires. Pi reaches
`agent-notify` through the repository-authored bridge extension instead.

The list MUST NOT be enumerated as a fixed roster in this requirement. An
enumeration is falsified by any later change that adds or removes one entry,
which is what happened to the previous text when the notify producer was
retired. The requirement states the exclusions and the delivery rule; the
current membership lives in `pi.nix`.

#### Scenario: Extension list excludes both retired entries

- **POLARITY** positive
- **WHEN** the `extensions` Nix list in `pi.nix` is inspected
- **THEN** it contains neither `confirm-destructive` nor `notify`

#### Scenario: Pi still has a notification producer

- **POLARITY** positive
- **WHEN** `notify` is absent from the list
- **THEN** the repository-authored bridge extension is present and installed
- **AND** a settled pi turn still raises exactly one toast

#### Scenario: Removing notify without the bridge fails the build

- **POLARITY** negative
- **WHEN** `notify` is removed from the list and the bridge extension is not
  installed
- **THEN** the build fails and names pi as having no notification producer

#### Scenario: A reintroduced producer fails the build

- **POLARITY** negative
- **WHEN** a contributor re-adds `notify` or `confirm-destructive` to the list
- **THEN** the build fails and names the reintroduced entry
