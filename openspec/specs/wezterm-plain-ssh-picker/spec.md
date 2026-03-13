## ADDED Requirements

### Requirement: Fuzzy SSH Host Selection
The system SHALL provide a fuzzy-searchable list of SSH hosts defined in the local configuration.

#### Scenario: Opening the picker
- **WHEN** the user triggers the SSH picker keybinding
- **THEN** an `InputSelector` UI SHALL appear
- **AND** it SHALL contain entries for all valid hosts in `~/.ssh/config`

### Requirement: Version-Agnostic SSH Spawning
The system SHALL use the standard system `ssh` binary to establish remote connections.

#### Scenario: Connecting to a host
- **WHEN** a host is selected from the picker
- **THEN** a new Wezterm tab SHALL open
- **AND** it SHALL execute the command `ssh <hostname>`

### Requirement: Automated Workspace Switching
The system SHALL organize SSH sessions into dedicated workspaces named after the remote host.

#### Scenario: Workspace isolation
- **WHEN** an SSH connection is established via the picker
- **THEN** the active window SHALL switch to a workspace with the name of the remote host
