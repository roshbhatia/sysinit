# Prefix prepended to every bash command pi runs, so an alias defined in the
# owner's zsh config resolves inside the harness.
#
# Its own file so the `pi-shell-prefix-loads-aliases` flake check can RUN it. The
# property that matters is that bash parses this into commands that load an alias,
# and no assertion over the string can establish that: a line-count gate passes a
# backslash-continuation version, which bash reads as one command with `eval` as an
# argument, and rejects a correct semicolon-separated one-liner.
shopt -s expand_aliases
eval "$(grep '^alias ' ~/.zshrc 2> /dev/null)"
eval "$(grep -rh '^alias ' ~/.config/zsh 2> /dev/null)"
