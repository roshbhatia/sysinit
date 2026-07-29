## ADDED Requirements

### Requirement: Nix-embedded shell fragments are parsed at build time

Every zsh fragment that `modules/home/programs/zsh/default.nix` interpolates
into `programs.zsh.initContent` MUST be parsed by `zsh -n` in a `nix flake
check` derivation. A fragment that does not parse MUST fail the check.

The check MUST read the same file set the module reads. It MUST NOT hold a
hand-maintained second list, because a fragment added to the module and missed
by the list would pass unchecked.

#### Scenario: A valid fragment set passes

- **POLARITY** positive
- **WHEN** every fragment under `modules/home/programs/zsh/` parses
- **THEN** the check succeeds

#### Scenario: A syntax error fails the build

- **POLARITY** negative
- **WHEN** a fragment contains an unterminated `if` block
- **THEN** the check fails and names the file and the parser error
- **AND** `nix flake check` exits non-zero

#### Scenario: A newly added fragment is covered without editing the check

- **POLARITY** negative
- **WHEN** a maintainer adds a fragment that does not parse and does not touch
  the check derivation
- **THEN** the check still fails, because it derives its file set from the
  module rather than from a separate list

### Requirement: WezTerm Lua is parsed at build time

Every `.lua` file under `modules/home/programs/wezterm/lua/` MUST be parsed by
a Lua front end in a `nix flake check` derivation. A file that does not parse
MUST fail the check.

The check verifies syntax only. It MUST NOT attempt to load the files, because
they call `require("wezterm")`, which does not exist outside the WezTerm host.

#### Scenario: Valid Lua passes

- **POLARITY** positive
- **WHEN** every file under `lua/` is syntactically valid
- **THEN** the check succeeds

#### Scenario: A Lua syntax error fails the build

- **POLARITY** negative
- **WHEN** `ui.lua` is missing an `end`
- **THEN** the check fails and reports the file and line

#### Scenario: A missing WezTerm host does not fail the check

- **POLARITY** negative
- **WHEN** the check runs in a sandbox with no `wezterm` module available
- **THEN** the check still succeeds for valid files, because it parses rather
  than loads

### Requirement: LLM shell scripts pass shellcheck

Every `.sh` file under `modules/home/programs/llm/config/` MUST pass
`shellcheck`. Scripts already wrapped by `pkgs.writeShellApplication` are
covered by that wrapper. Any script not wrapped MUST be covered by an explicit
check derivation, so no script escapes analysis by not being wrapped.

#### Scenario: A wrapped script is covered by its wrapper

- **POLARITY** positive
- **WHEN** `claude-bash-guard.sh` is built through `writeShellApplication`
- **THEN** shellcheck runs as part of that derivation

#### Scenario: An unwrapped script with a defect fails the check

- **POLARITY** negative
- **WHEN** a new `.sh` file under `config/` is not referenced by any
  `writeShellApplication` and contains an unquoted expansion
- **THEN** the explicit check derivation fails and names the file

### Requirement: CI runs the verification gate on every change

A GitHub Actions workflow MUST run `nix flake check` and build at least one
host configuration on every push to `main` and on every pull request. The
workflow MUST NOT restrict itself by changed path, because a change under
`modules/` is exactly the case the existing `build-cache` workflow skips.

#### Scenario: A pull request runs the gate

- **POLARITY** positive
- **WHEN** a pull request changes a file under `modules/`
- **THEN** the workflow runs `nix flake check` and a host build
- **AND** the job result is visible on the pull request

#### Scenario: A failing check fails the job

- **POLARITY** negative
- **WHEN** a change introduces a zsh fragment that does not parse
- **THEN** the workflow job fails
- **AND** the failure names the check that failed

### Requirement: Documented commands exist

Every command that `AGENTS.md` documents under its Commands section MUST be
runnable from a clean checkout of this repository. A documented command that
no file provides MUST be removed from `AGENTS.md` or provided.

`task fmt:sh` and `task fmt:sh:check` are currently documented and no Taskfile
exists in the repository.

#### Scenario: Documented formatting command runs

- **POLARITY** positive
- **WHEN** the owner runs the documented shell formatting command from a clean
  checkout
- **THEN** the command runs and reports formatting status

#### Scenario: An undocumented-but-missing command is not left in place

- **POLARITY** negative
- **WHEN** `AGENTS.md` names a command that no file in the repository provides
- **THEN** the change removes the line or adds the provider
- **AND** no documented command fails with "command not found"
