#!/usr/bin/env zsh
# shellcheck disable=all
# Core initialization - runs earliest in shell startup

# Ensure unique entries in path arrays
typeset -gU path PATH fpath FPATH

# Terminal settings
stty stop undef

# Shell options
setopt COMBINING_CHARS
setopt PROMPT_SUBST

# Minimal prompt until oh-my-posh loads
PROMPT='%~%% '
RPS1=""
