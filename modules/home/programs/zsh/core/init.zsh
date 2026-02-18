#!/usr/bin/env zsh
# shellcheck disable=all
typeset -gU path PATH fpath FPATH
stty stop undef

setopt autocd autopushd pushdsilent pushdignoredups
setopt correct completeinword listambiguous
setopt extendedglob autoremoveslash
setopt interactivecomments

unsetopt BEEP

export KEYTIMEOUT=1
