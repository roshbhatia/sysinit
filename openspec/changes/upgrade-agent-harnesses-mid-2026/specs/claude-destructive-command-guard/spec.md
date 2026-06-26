## ADDED Requirements

### Requirement: PreToolUse hook denies irreversible bash commands

Claude Code SHALL run a `PreToolUse` hook matching the `Bash` tool that
inspects `tool_input.command` and denies the command when it matches the
fixed deny set sourced from the global CLAUDE.md prohibitions. The denial
SHALL be mechanical and independent of the conversational permission tiers
(`allow`/`ask`) — a command in the deny set is blocked regardless of
permission mode.

The deny set SHALL cover:

- force pushes (`git push --force`, `git push -f`, `git push --force-with-lease`)
- hook-bypass flags (`--no-verify`, `--no-gpg-sign`)
- `git reset --hard`
- `git clean -f` (and `-fd`, `-fdx`, etc.)
- `git branch -D` (and `--delete --force`)

#### Scenario: A force push is denied

- **WHEN** the Bash tool is invoked with a command containing `git push --force`
  or `git push -f`
- **THEN** the hook emits the structured deny decision on stdout
- **AND** the JSON has `hookSpecificOutput.hookEventName = "PreToolUse"`,
  `hookSpecificOutput.permissionDecision = "deny"`, and a
  `permissionDecisionReason` naming the violated prohibition
- **AND** the bash command does not execute

#### Scenario: A hook-bypass flag is denied

- **WHEN** the Bash tool is invoked with a command containing `--no-verify`
  or `--no-gpg-sign`
- **THEN** the hook denies the command with a reason referencing the
  no-hook-bypass prohibition
- **AND** the command does not execute

#### Scenario: An irreversible git command is denied

- **WHEN** the Bash tool is invoked with `git reset --hard`, `git clean -f`,
  or `git branch -D`
- **THEN** the hook denies the command with a reason naming the prohibition
- **AND** the command does not execute

#### Scenario: A push to main is allowed

- **WHEN** the Bash tool is invoked with `git push` (or `git push origin main`)
  with no force or bypass flag
- **THEN** the hook does not deny the command
- **AND** the command proceeds to the normal permission tiers
- **AND** the repo-specific allowance to push to `main` is preserved

#### Scenario: An ordinary command passes through untouched

- **WHEN** the Bash tool is invoked with a command not in the deny set
  (e.g. `nh darwin build`, `git status`, `rg foo`)
- **THEN** the hook produces no deny decision and the command is evaluated
  by the existing `allow`/`ask` permission tiers as before
