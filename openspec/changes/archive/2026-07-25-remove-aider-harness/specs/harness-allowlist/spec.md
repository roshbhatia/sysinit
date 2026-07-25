## MODIFIED Requirements

### Requirement: One formatter per harness consuming the allowlist
The allowlist MUST expose `formatFor<Harness>` for each harness whose native config can express a bash-allowlist: `formatForClaude` (returns `["Bash(<pattern>)" ...]`), `formatForOpencode` (returns the per-tool `bash.<key> = "allow"` attrset), `formatForGoose` (uses the existing `mcp.nix` formatter shape), `formatForAmp` (returns the `tool×match×action` triples), `formatForCrush` (returns the `allowed_tools` list), `formatForCursor` (returns `["Shell(<pattern>)" ...]`).

Harnesses that do not have a native bash-allowlist concept (`codex`, `copilot-cli`, `gemini`) SHALL NOT consume `allowlist`. Their configs MUST NOT reference it.

#### Scenario: Claude formatter output shape
- **POLARITY** positive
- **WHEN** `allowlist.formatForClaude allowlist.tierA` is evaluated
- **THEN** the result is a list of strings each matching the pattern `Bash(<pattern>)` and the length is exactly `builtins.length allowlist.tierA`

#### Scenario: Opencode formatter output shape
- **POLARITY** positive
- **WHEN** `allowlist.formatForOpencode (allowlist.tierA ++ allowlist.tierB)` is evaluated
- **THEN** the result is an attrset with one key per tool the harness recognizes, each value `"allow"`, and the attrset is non-empty

#### Scenario: Cross-harness consistency
- **POLARITY** positive
- **WHEN** the rendered Claude `settings.json` allow-list and the rendered opencode `permission.bash` attrset are both derived from the same `allowlist.tierA` source
- **THEN** every command auto-allowed in Claude is also auto-allowed in opencode (modulo Harness-specific syntactic differences)

#### Scenario: A non-consumer harness references the allowlist
- **POLARITY** negative
- **WHEN** a harness config for `codex`, `copilot-cli`, or `gemini` is written to consume `allowlist`
- **THEN** the config is rejected in review, because those harnesses have no native bash-allowlist concept to render it into
