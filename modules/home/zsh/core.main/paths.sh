#!/usr/bin/env zsh
# shellcheck disable=all
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
#       ___           ___           ___           ___           ___
#      /  /\         /  /\         /__/\         /  /\         /  /\
#     /  /::|       /  /:/_        \  \:\       /  /::\       /  /:/
#    /  /:/:|      /  /:/ /\        \__\:\     /  /:/\:\     /  /:/
#   /  /:/|:|__   /  /:/ /::\   ___ /  /::\   /  /:/~/:/    /  /:/  ___
#  /__/:/ |:| /\ /__/:/ /:/\:\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/  /  /\
#  \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/
#      |  |:/:/   \  \::/ /:/   \  \::/       \  \::/~~~~   \  \:\  /:/
#      |  |::/     \__\/ /:/     \  \:\        \  \:\        \  \:\/:/
#      |  |:/        /__/:/       \  \:\        \  \:\        \  \::/
#      |__|/         \__\/         \__\/         \__\/         \__\/

source "$HOME/.config/zsh/loglib.sh"

path.print() {
  echo "$PATH" | tr ':' '\n' | bat --style=numbers,grid
}

path.add.safe() {
  local dir="$1"
  if [ -d "$dir" ]; then
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
      log_debug "Added $dir to PATH"
    fi
  else
    log_debug "Directory $dir does not exist, skipping PATH addition"
  fi
}

# Path settings
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Add all directories to PATH
paths=(
  "$HOME/.cargo/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.yarn/bin"
  "$HOME/.config/yarn/global/node_modules/.bin"
  "/usr/local/opt/cython/bin"
  "$HOME/.local/bin"
  "$HOME/.rvm/bin"
  "$HOME/.govm/shim"
  "$HOME/.krew/bin"
  "$HOME/bin"
  "$HOME/.config/zsh/extras/bin"
  "opt/homebrew/opt/gettext/bin"
)

for dir in "${paths[@]}"; do
  path.add.safe "$dir"
done

# Go specific path (requires go to be installed)
if command -v go &> /dev/null; then
  path.add.safe "$(go env GOPATH)/bin"
fi
