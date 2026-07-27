## MODIFIED Requirements

### Requirement: PreToolUse hook denies irreversible bash commands

Claude Code SHALL run a `PreToolUse` hook matching the `Bash` tool that
inspects `tool_input.command` and denies the command when it matches the
fixed deny set sourced from the global CLAUDE.md prohibitions. The denial
SHALL be mechanical and independent of the conversational permission tiers
(`allow`/`ask`). A command in the deny set is blocked regardless of
permission mode.

The deny set SHALL cover:

- force pushes (`git push --force`, `git push -f`, `git push --force-with-lease`)
- hook-bypass flags (`--no-verify`, `--no-gpg-sign`)
- `git reset --hard`
- `git clean -f` (and `-fd`, `-fdx`, etc.)
- `git branch -D` (and `--delete --force`)

This hook SHALL be the only `PreToolUse` entry that returns a
`permissionDecision` for the `Bash` tool. Claude Code runs matching hooks in
parallel and documents no precedence rule for conflicting decisions, so a second
deciding hook could race the deny. The mirror rewrite therefore lives inside this
script rather than beside it.

The hook SHALL evaluate the deny set before any rewrite. A denied command SHALL
never be rewritten and SHALL never reach the mirror.

#### Scenario: A force push is denied

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with a command containing `git push --force`
  or `git push -f`
- **THEN** the hook emits the structured deny decision on stdout
- **AND** the JSON has `hookSpecificOutput.hookEventName = "PreToolUse"`,
  `hookSpecificOutput.permissionDecision = "deny"`, and a
  `permissionDecisionReason` naming the violated prohibition
- **AND** the JSON carries no `updatedInput`
- **AND** the bash command does not execute

#### Scenario: A hook-bypass flag is denied

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with a command containing `--no-verify`
  or `--no-gpg-sign`
- **THEN** the hook denies the command with a reason referencing the
  no-hook-bypass prohibition
- **AND** the command does not execute

#### Scenario: An irreversible git command is denied

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with `git reset --hard`, `git clean -f`,
  or `git branch -D`
- **THEN** the hook denies the command with a reason naming the prohibition
- **AND** the command does not execute

#### Scenario: A push to main is allowed

- **POLARITY** positive
- **WHEN** the Bash tool is invoked with `git push` (or `git push origin main`)
  with no force or bypass flag
- **THEN** the hook does not deny the command
- **AND** the repo-specific allowance to push to `main` is preserved

#### Scenario: An ordinary command passes through the deny set

- **POLARITY** positive
- **WHEN** the Bash tool is invoked with a command not in the deny set
  (e.g. `nh darwin build`, `git status`, `rg foo`)
- **THEN** the hook produces no deny decision
- **AND** the command is evaluated by the existing `allow`/`ask` permission tiers
  as before

## ADDED Requirements

### Requirement: The Bash guard wraps allowed commands for mirroring

When the guard does not deny a command, it SHALL return
`hookSpecificOutput.updatedInput` that replaces `command` with a wrapper that runs
the original under `script(1)` and copies its output to the calling pane's mirror
log. The hook SHALL pair `updatedInput` with `permissionDecision: "allow"`, because
Claude Code does not document `updatedInput` without an explicit decision.

The hook entry SHALL be synchronous. Claude Code cannot apply `updatedInput` from an
asynchronous hook.

Every line the hook emits SHALL be newline-delimited. Single-line wrapping is
forbidden: verified that `{ echo hi # note ; }` is a parse error, because the
trailing comment consumes the closing brace.

The original command SHALL be passed base64-encoded and decoded into a shell
variable, then given to `script` as a single argument. The encoding MUST have
newlines stripped, as `modules/home/programs/llm/config/agent-state.sh` already
does with `base64 | tr -d '\n'`. GNU `base64` from the nix profile wraps at 76
columns, which is 57 input bytes, and a wrapped value would be parsed as two
commands.

The wrapper SHALL fall back to running the original command verbatim when the decode
yields an empty result.

The hook SHALL emit the exit-status form matching the agent's shell, and SHALL emit
no rewrite when it cannot determine that shell. zsh uses `pipestatus`, 1-indexed;
bash uses `PIPESTATUS`, 0-indexed. The status SHALL be restored in a subshell, not
with a bare `exit`, which would terminate the agent's persistent shell.

The hook SHALL NOT rewrite a bare `cd`. Verified that `cd` does not survive the
wrapper's subshell: after `{ cd /; } | tee`, the shell's working directory was
unchanged. Claude Code's Bash tool tracks its working directory in its own shell, so
a wrapped `cd` would silently do nothing. Compound commands containing `cd` SHALL be
rewritten, because subshell scoping is already their correct behavior.

The hook SHALL NOT rewrite a Bash call whose `tool_input.run_in_background` is true.

The hook SHALL NOT rewrite when the file
`${XDG_STATE_HOME:-$HOME/.local/state}/agents/mirror.disabled` exists. The hook runs
as a fresh process on every tool call, so it observes the file immediately.

Rewriting SHALL be best-effort. Any failure to build the rewrite SHALL leave the
command unchanged rather than block or corrupt it.

#### Scenario: An allowed command is wrapped for mirroring

- **POLARITY** positive
- **WHEN** the Bash tool is invoked with `nh darwin build` and the guard does not
  deny it
- **THEN** the hook emits `hookSpecificOutput.permissionDecision = "allow"`
- **AND** `updatedInput.command` runs the original under `script`
- **AND** the agent receives the command's own exit code

#### Scenario: A command long enough to wrap the encoding

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with a command longer than 57 bytes, such as
  `cd modules/home/programs/llm && nix build .#checks 2>&1 | tail -40`
- **THEN** every emitted line is a single line
- **AND** the decoded command is byte-identical to the original
- **AND** no truncated prefix of the command is executed

#### Scenario: A quoted shell operator survives the wrap

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with `rg 'foo && rm -rf build' .`
- **THEN** the executed command still passes `foo && rm -rf build` as one argument
  to `rg`
- **AND** the `&&` is not evaluated as a shell operator
- **AND** no `rm` runs

#### Scenario: A command with a trailing comment

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with a command ending in `# note`
- **THEN** the wrapper does not fail to parse
- **AND** the command runs and returns its own exit code

#### Scenario: The agent's shell cannot be determined

- **POLARITY** negative
- **WHEN** the guard cannot determine which exit-status form the agent's shell uses
- **THEN** it emits no `updatedInput`
- **AND** the command runs unwrapped rather than with a wrong exit code

#### Scenario: A bare cd is left unrewritten

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with `cd modules/home`
- **THEN** the hook returns no `updatedInput` for that command
- **AND** Claude's tracked working directory changes as it did before this change

#### Scenario: A background command bypasses the mirror

- **POLARITY** negative
- **WHEN** the Bash tool is invoked with `run_in_background` set to true
- **THEN** the hook returns no `updatedInput` for that command

#### Scenario: Rewrite construction fails

- **POLARITY** negative
- **WHEN** the hook cannot read `cwd` or cannot build the wrapper
- **THEN** it emits no `updatedInput`
- **AND** it does not deny the command
- **AND** the original command executes unchanged
