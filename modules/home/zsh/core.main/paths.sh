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

# Add all directories to PATH
paths=(
  "/usr/local/opt/cython/bin"
  "$HOME/.cargo/bin"
  "$HOME/.config/yarn/global/node_modules/.bin"
  "$HOME/.config/zsh/extras/bin"
  "$HOME/.govm/shim"
  "$HOME/.krew/bin"
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.rvm/bin"
  "$HOME/.yarn/bin"
  "$HOME/bin"
  "opt/homebrew/opt/gettext/bin"

  "$(go env GOPATH)/bin"
)

for dir in "${paths[@]}"; do
  path.add.safe "$dir"
done
