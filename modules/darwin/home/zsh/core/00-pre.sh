#!/usr/bin/env zsh
# shellcheck disable=all
typeset -U path cdpath fpath manpath
setopt EXTENDED_GLOB
[[ -f "${HOME}/.zshsecrets" ]] && source "${HOME}/.zshsecrets"
[[ -f "${HOME}/.zshwork" ]] && source "${HOME}/.zshwork"
 
unset MAILCHECK
stty stop undef