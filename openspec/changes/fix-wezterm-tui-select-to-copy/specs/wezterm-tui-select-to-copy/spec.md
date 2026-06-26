## ADDED Requirements

### Requirement: Shift-modified drag selects and copies to the system clipboard under app mouse reporting

WezTerm SHALL provide a `SHIFT`-modified left-button gesture that performs
native text selection even when the foreground application has enabled mouse
reporting, and SHALL complete that selection to the system clipboard (not only
the primary selection). The bypass modifier MUST be `SHIFT`
(`bypass_mouse_reporting_modifiers`), and the `Down`, `Drag`, and `Up` events
of the gesture MUST all be bound so the gesture does not double-fire against
WezTerm's default `Down` handler.

#### Scenario: Selecting inside a full-screen mouse-capturing TUI

- **WHEN** Claude Code is running with `tui = "fullscreen"` (mouse reporting on)
  and the user holds `SHIFT` and drags across terminal text
- **THEN** WezTerm performs its own text selection rather than forwarding the
  drag to the application
- **AND** on release the selected text is placed on the system clipboard
- **AND** the selected text is also placed on the primary selection

#### Scenario: Plain drag is preserved for the application

- **WHEN** the user drags with no modifier inside a mouse-capturing TUI
- **THEN** the drag is forwarded to the application (Claude Code click-to-expand,
  URL click, and scroll continue to work)
- **AND** WezTerm does not begin a native text selection

#### Scenario: Existing triple-click semantic-zone selection is preserved

- **WHEN** the user triple-clicks (no modifier) outside app mouse reporting
- **THEN** WezTerm selects the semantic zone as before, unchanged by this change

#### Scenario: No double-fire from an Up-only binding

- **WHEN** the `SHIFT`+left gesture completes
- **THEN** only the configured selection actions run
- **AND** the default `Down` handler does not also fire (because `Down`, `Drag`,
  and `Up` are all explicitly bound for the `SHIFT` modifier)
