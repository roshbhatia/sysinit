## ADDED Requirements

### Requirement: harness-kit exposes one entry point
`modules/home/programs/llm/lib/harness-kit.nix` MUST expose exactly one top-level function `mkKit` taking `{ lib, pkgs, config }` and returning an attrset with the keys `llmLib`, `skillsLib`, `mcpServers`, `mkInstructions`. No other keys are exported.

#### Scenario: Kit construction
- **WHEN** a harness config calls `harnessKit.mkKit { inherit lib pkgs config; }`
- **THEN** the returned attrset contains exactly `llmLib`, `skillsLib`, `mcpServers`, `mkInstructions` and nothing else

#### Scenario: Missing argument
- **WHEN** a caller invokes `mkKit { inherit lib pkgs; }` without `config`
- **THEN** evaluation fails with an error citing the missing `config` parameter

### Requirement: harness configs do not reach past the kit
No file under `modules/home/programs/llm/config/` (except `pi.nix`, which is out of scope for this change) SHALL `import` any of `../lib/instructions.nix`, `../mcp.nix`, or `../skills.nix` directly. All access to those modules MUST go through `harnessKit.mkKit`.

#### Scenario: Conformant harness
- **WHEN** a harness's `let` block calls `harnessKit.mkKit` and destructures via `inherit (kit) llmLib skillsLib mcpServers mkInstructions`
- **THEN** `grep -rE "import \\.\\./(lib/instructions|mcp|skills)\\.nix" modules/home/programs/llm/config/` returns no matches (after excluding `pi.nix`)

#### Scenario: Direct-import violation
- **WHEN** a contributor edits `gemini.nix` to add a fresh `import ../mcp.nix { ... }` call alongside the kit
- **THEN** a build-time assertion in `harness-kit.nix` (or a `nix flake check`-level lint) fails citing the bypass

### Requirement: mkInstructions accepts only skillsRoot
The `mkInstructions` function exposed by the kit MUST take exactly one positional argument: `skillsRoot` (string, e.g., `"~/.claude/skills"`). It SHALL pass `localSkillDescriptions` (from `skillsLib`) and `openspecVersion` (from `pkgs.openspec.version`) through automatically.

#### Scenario: Standard invocation
- **WHEN** a harness calls `kit.mkInstructions "~/.config/codex/skills"`
- **THEN** the returned string is identical to what `llmLib.instructions.makeInstructions { localSkillDescriptions = skillsLib.localSkillDescriptions; openspecVersion = pkgs.openspec.version; skillsRoot = "~/.config/codex/skills"; }` would return

#### Scenario: Wrong shape passed
- **WHEN** a harness calls `kit.mkInstructions { skillsRoot = "..."; }` (attrset instead of string)
- **THEN** evaluation fails with a clear type error

### Requirement: Kit is referenced from lib/default.nix
`modules/home/programs/llm/lib/default.nix` MUST re-export `harnessKit = import ./harness-kit.nix;` so callers can `import ../lib` and access `harnessKit` without naming the file path. Direct imports of `harness-kit.nix` from outside `lib/` SHALL NOT be used.

#### Scenario: Standard caller pattern
- **WHEN** a harness uses `let llmTools = import ../lib { inherit lib; }; kit = llmTools.harnessKit.mkKit { inherit lib pkgs config; }; in ...`
- **THEN** evaluation succeeds and the kit returns its standard outputs

#### Scenario: Direct file import (anti-pattern)
- **WHEN** a harness uses `import ../lib/harness-kit.nix` directly
- **THEN** a `nix flake check`-level lint reports the file-path import as a style violation

### Requirement: Byte-identity preserved during refactor
For every harness migrated to use the kit, the rendered output file under `home.file` or `xdg.configFile` MUST be byte-identical before and after the migration. The migration is a pure structural refactor of the Nix source; no behavior changes.

#### Scenario: Pre- and post-refactor diff
- **WHEN** the rendered store path for a migrated harness is compared between `git stash` (pre-refactor) and current (post-refactor)
- **THEN** `diff -u` reports no differences

#### Scenario: Accidental semantic shift
- **WHEN** a contributor changes the order of operations in a harness's let-block such that the rendered output differs (e.g., reorders an attrset, changes a string)
- **THEN** the byte-identity diff check at the verify gate fails and the slice is rolled back before apply
