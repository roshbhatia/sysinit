#!/usr/bin/env zsh
# shellcheck disable=all

# Every non-interactive zsh, not just Claude Code's. This used to test CLAUDECODE
# and CLAUDE_CODE_ENTRYPOINT, so thirteen of the fourteen agents still died on an
# unmatched glob. No other harness sets a comparable variable, so the shell's own
# non-interactive flag is the only harness-agnostic signal there is.
if [[ ! -o interactive ]]; then
  unsetopt nomatch
fi
