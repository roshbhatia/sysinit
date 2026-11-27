#!/usr/bin/env zsh
# shellcheck disable=all

# Keep unmatched globs literal even for harnesses without an agent marker.
if [[ ! -o interactive ]]; then
  unsetopt nomatch
  # Limit the other Bash-like expansions to detected or opted-in agents.
  if [[ -n ${CLAUDECODE:-} || -n ${CODEX_THREAD_ID:-} || ${SYSINIT_AGENT_SHELL:-0} == 1 ]]; then
    setopt sh_word_split no_equals
  fi
fi
