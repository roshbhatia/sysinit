shopt -s expand_aliases
eval "$(grep '^alias ' ~/.zshrc 2> /dev/null)"
eval "$(grep -rh '^alias ' ~/.config/zsh 2> /dev/null)"
