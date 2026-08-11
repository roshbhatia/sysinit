## ADDED Requirements

### Requirement: Provider selection via --from flag
Every verb that loads changes (render, plan, diff, lock, graph, web) SHALL accept a persistent `--from <name>` flag that selects the input provider. Recognized built-in values are `openspec`, `bmad`, `plan`, and `stdin`. User-defined values MUST match a `providers[].name` entry in `specutil.yaml`. An unrecognized value SHALL produce an error listing available providers.

#### Scenario: Explicit built-in provider selected
- **WHEN** user runs `specutil render --from bmad --as rfc stories/story-1.md`
- **THEN** the bmad provider is used to load the change from the given path

#### Scenario: Unrecognized provider name
- **WHEN** user runs `specutil render --from jira --as rfc`
- **THEN** specutil exits non-zero with an error listing available provider names

### Requirement: Provider auto-detection when --from is omitted
When `--from` is absent, specutil SHALL auto-detect the provider by inspecting the repository root in order: (1) `openspec/changes/` directory present → `openspec`; (2) `stories/*.md` files present → `bmad`; (3) `plan.md` at root → `plan`. When multiple signals match, the first match in order wins. When no signal matches, specutil SHALL exit with a clear error suggesting the correct `--from` flag.

#### Scenario: OpenSpec directory auto-detected
- **WHEN** `--from` is absent and `openspec/changes/` exists
- **THEN** the openspec provider is selected without any flag required

#### Scenario: No provider signals found
- **WHEN** `--from` is absent and no detection signal matches
- **THEN** specutil exits non-zero with an error message suggesting `--from openspec|bmad|plan|stdin`

### Requirement: stdin provider
`--from stdin` SHALL read openspec-compatible markdown from standard input once and treat it as a single change. The change name SHALL be derived from the first `# Heading` in the input; the `--change` flag overrides this derivation. Verbs that require a stable change name for lockfile operations (plan, diff, lock) SHALL require `--change` when `--from stdin` is used and SHALL error clearly if it is absent.

#### Scenario: Render from piped input
- **WHEN** user runs `./my-adapter.sh | specutil render --from stdin --as rfc`
- **THEN** specutil reads stdin, derives the change name from the first heading, and renders to stdout

#### Scenario: Plan requires --change with stdin
- **WHEN** user runs `cat plan.md | specutil plan --from stdin --target linear` without `--change`
- **THEN** specutil exits non-zero with an error stating `--change is required when --from stdin`

### Requirement: User-defined script adapters via specutil.yaml
The `providers` array in `specutil.yaml` SHALL declare user-defined script adapters. Each entry SHALL have a `name` (string, unique) and `command` (string, shell command template). The `{change}` placeholder in `command` SHALL be substituted with the `--change` value at runtime. The script SHALL be executed and its stdout SHALL be parsed as openspec-compatible markdown by the existing parser. Non-zero exit from the script SHALL propagate as an error.

#### Scenario: Declared script adapter invoked
- **WHEN** `specutil.yaml` declares `providers: [{name: jira, command: "./hack/jira.sh {change}"}]`
- **THEN** `specutil render --from jira --change PROJ-123 --as rfc` executes `./hack/jira.sh PROJ-123` and parses its stdout

#### Scenario: Script exits non-zero
- **WHEN** the declared script exits with code 1
- **THEN** specutil exits non-zero propagating the error; no rendering is attempted

### Requirement: Provider name surfaced in warnings
Parse warnings emitted to stderr SHALL include the active provider name so errors are attributable to the correct adapter without inspecting flags.

#### Scenario: Warning includes provider name
- **WHEN** a loaded change has a missing proposal section
- **THEN** the warning message includes the provider name (e.g. `warning [bmad]: story-1: ...`)
