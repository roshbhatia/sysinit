#!/usr/bin/env zsh
# shellcheck disable=all

typeset -gU path PATH fpath FPATH
stty stop undef

setopt autocd
setopt autopushd
setopt pushdsilent
setopt pushdignoredups

setopt correct
setopt completeinword
setopt listambiguous

setopt extendedglob
setopt autoremoveslash
