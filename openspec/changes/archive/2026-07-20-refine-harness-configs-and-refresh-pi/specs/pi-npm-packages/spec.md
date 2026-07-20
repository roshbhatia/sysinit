## ADDED Requirements

### Requirement: pi-rtk-optimizer replaces pi-rtk
The pi configuration SHALL include `pi-rtk-optimizer` v0.9.0 as a
`mkFetchedNpmPackage` derivation added to `piPackagePaths`, and SHALL remove the
superseded `pi-rtk` v0.1.4. The nixpkgs `rtk` binary SHALL be confirmed to
provide the `rtk rewrite` subcommand before it is added to `home.packages`.

#### Scenario: Optimizer present, predecessor gone
- **WHEN** home-manager builds the pi package set
- **THEN** `pi-rtk-optimizer` is in `piPackagePaths`
- **AND** `pi-rtk` is no longer referenced

#### Scenario: Output compaction works without the binary
- **WHEN** `pkgs.rtk` does not provide `rtk rewrite`
- **THEN** `pi-rtk-optimizer` still compacts tool output
- **AND** command rewriting degrades to a no-op rather than adding an unrelated `rtk` to PATH

### Requirement: pi-web-access replaces pi-webfetch-to-markdown
The pi configuration SHALL include `pi-web-access` v0.13.0 as a
`mkBuiltNpmPackage` derivation (with a generated `./locks/pi-web-access.lock.json`)
added to `piPackagePaths`, and SHALL remove `pi-webfetch-to-markdown` v1.0.1.

#### Scenario: Web search and fetch available
- **WHEN** a pi session needs web search or URL content
- **THEN** `pi-web-access` provides both, and `pi-webfetch-to-markdown` is no longer referenced

#### Scenario: Librarian overlap resolved
- **WHEN** `pi-web-access` and the standalone `pi-librarian` both register a librarian capability
- **THEN** `pi-librarian` is kept
- **AND** the bundled librarian skill is disabled via `pi-web-access` config if it collides

### Requirement: @narumitw/pi-retry adds provider-failure resilience
The pi configuration SHALL include `@narumitw/pi-retry` v0.22.0 as a
`mkFetchedNpmPackage` derivation added to `piPackagePaths`.

#### Scenario: Transient provider failures are classified
- **WHEN** a provider returns a retryable error or stalls a stream
- **THEN** `pi-retry` classifies it so pi's native retry can recover

### Requirement: @monotykamary/pi-vcc adds deterministic compaction
The pi configuration SHALL include `@monotykamary/pi-vcc` v0.8.1 as a
`mkFetchedNpmPackage` derivation added to `piPackagePaths`, with
`overrideDefaultCompaction = true` set in `~/.pi/agent/pi-vcc-config.json`,
coordinated so the `trigger-compact` extension does not cause double compaction.

#### Scenario: Algorithmic compaction on threshold
- **WHEN** a pi session reaches its compaction threshold
- **THEN** `pi-vcc` compacts the session deterministically without an LLM call
- **AND** compaction runs once, not twice

### Requirement: pi-sidebar-tui adds a session sidebar
The pi configuration SHALL include `pi-sidebar-tui` v1.3.1 as a
`mkFetchedNpmPackage` derivation added to `piPackagePaths`.

#### Scenario: Sidebar shows session metrics
- **WHEN** a pi session runs
- **THEN** the sidebar shows session metrics, todos, subagents, MCP servers, and git status

### Requirement: pi-lens, codex-subagents, and show-files-read are excluded
The pi configuration SHALL NOT include `pi-lens`,
`@ogulcancelik/pi-codex-subagents`, or `@normful/pi-show-files-read`.

#### Scenario: Excluded packages absent
- **WHEN** the pi package set is inspected
- **THEN** none of the three excluded packages is referenced
