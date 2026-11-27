#!/usr/bin/env zsh
# shellcheck disable=all
typeset -gU path PATH fpath FPATH
if [[ -t 0 ]]; then
  stty stop undef
fi

setopt autocd autopushd pushdsilent pushdignoredups
setopt correct completeinword listambiguous
setopt extendedglob autoremoveslash
setopt interactivecomments

unsetopt BEEP

export KEYTIMEOUT=1
