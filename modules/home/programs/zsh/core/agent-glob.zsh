#!/usr/bin/env zsh
# shellcheck disable=all

# zsh aborts a command whose glob matches nothing. bash passes the pattern
# through literally, so `grep -rn --include=*.nix foo .` runs in bash and dies in
# zsh before grep starts, naming `--include=*.nix` as the unmatched pattern. An
# agent writes commands as text and cannot know in advance that a pattern will
# match, so it loses a turn to a shell error that says nothing about the task.
#
# This belongs in .zshenv rather than .zshrc: an agent's shell is `zsh -c`, which
# reads .zshenv and never reads .zshrc.
#
# Gated twice. Non-interactive keeps the typo guard in a real terminal, including
# a terminal an agent spawned, where `ls *.tzt` should still be an error rather
# than a literal argument. The marker keeps it to shells an agent actually owns.
# Only CLAUDECODE is verified present; a harness whose marker is not listed here
# still gets zsh's default, so add its variable when its surface is established.
if [[ ! -o interactive ]] && [[ -n ${CLAUDECODE:-} || -n ${CLAUDE_CODE_ENTRYPOINT:-} ]]; then
  unsetopt nomatch
fi
