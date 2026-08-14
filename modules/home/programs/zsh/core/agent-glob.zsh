#!/usr/bin/env zsh
# shellcheck disable=all

if [[ ! -o interactive ]] && [[ -n ${CLAUDECODE:-} || -n ${CLAUDE_CODE_ENTRYPOINT:-} ]]; then
  unsetopt nomatch
fi
