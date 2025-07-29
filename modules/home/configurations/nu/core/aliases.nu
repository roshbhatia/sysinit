#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/aliases.nu (begin)
alias ".." = cd ..
alias "..." = cd ../..
alias "...." = cd ../../..
alias "....." = cd ../../../..
alias "~" = cd ~

alias l = eza --icons=always -1
alias la = eza --icons=always -1 -a
alias ll = eza --icons=always -1 -a
alias ls = eza
alias lt = eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'

alias code = code-insiders
alias c = code-insiders
alias kubectl = kubecolor
alias tf = terraform
alias y = yazi
alias v = nvim
alias g = git
alias diff = diff --color
alias grep = grep -s --color=auto
alias watch = watch --quiet

alias cat = bat
alias find = fd
# modules/darwin/home/nu/core/aliases.nu (end)

