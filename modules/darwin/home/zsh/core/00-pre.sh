#!/usr/bin/env zsh
# shellcheck disable=all
typeset -U path cdpath fpath manpath
setopt EXTENDED_GLOB

unset MAILCHECK
stty stop undef