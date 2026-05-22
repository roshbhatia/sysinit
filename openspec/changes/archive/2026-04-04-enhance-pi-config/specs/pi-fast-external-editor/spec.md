## ADDED Requirements

### Requirement: nvim-pi wrapper script is available
The pi configuration SHALL create a `nvim-pi` shell script via `pkgs.writeShellScriptBin` that invokes `nvim --clean -c "set ft=markdown"`.

#### Scenario: nvim-pi on PATH
- **WHEN** home-manager activation completes
- **THEN** `nvim-pi` is available on `$PATH`

#### Scenario: nvim-pi starts without plugins
- **WHEN** `nvim-pi` is invoked
- **THEN** nvim starts with `--clean` (no init files, no plugins loaded)

#### Scenario: nvim-pi sets markdown filetype
- **WHEN** `nvim-pi` opens a file
- **THEN** the filetype is set to `markdown` automatically

### Requirement: pi externalEditor uses nvim-pi
The pi keybindings SHALL configure `externalEditor` to invoke `nvim-pi` so that Ctrl+E opens a fast, plugin-free editor.

#### Scenario: Ctrl+E opens fast
- **WHEN** user presses Ctrl+E in a pi session
- **THEN** an editor opens quickly (no lazy.nvim plugin load delay)

#### Scenario: Prompt text round-trips correctly
- **WHEN** user edits text in nvim-pi and saves+quits
- **THEN** pi receives the updated text as the current prompt
