## ADDED Requirements

### Requirement: Seven additional built-in extensions are active
The pi configuration SHALL include `model-status`, `preset`, `trigger-compact`, `input-transform`, `minimal-mode`, `mac-system-theme`, and `reload-runtime` in the `extensions` list, sourced from `piExtensionsSrc`.

#### Scenario: Extensions are written to disk
- **WHEN** home-manager activation runs
- **THEN** all seven extension `.ts` files exist at `~/.pi/agent/extensions/<name>.ts`

#### Scenario: Model status visible in status bar
- **WHEN** a pi session is active
- **THEN** the current model name is displayed in the status bar via `model-status`

#### Scenario: Preset cycling available
- **WHEN** user presses Ctrl+Shift+U or runs `/preset`
- **THEN** the `preset` extension responds (even with an empty presets file, the command is registered)

#### Scenario: Auto-compaction triggers
- **WHEN** token usage crosses the `trigger-compact` threshold during a session
- **THEN** compaction is triggered automatically without user intervention

#### Scenario: Hot-reload works
- **WHEN** user runs `/reload-runtime`
- **THEN** extensions, skills, and themes reload without restarting pi
