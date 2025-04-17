#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
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
  "$HOME/.config/zsh/bin"
  "$HOME/.govm/shim"
  "$HOME/.krew/bin"
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.rvm/bin"
  "$HOME/.yarn/bin"
  "$HOME/bin"
  "$(go env GOPATH)/bin"
)

for dir in "${paths[@]}"; do
  path.add.safe "$dir"
done
