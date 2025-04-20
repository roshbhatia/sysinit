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

paths=(
  "/usr/local/opt/cython/bin"
  "$XDG_CONFIG_HOME/.cargo/bin"
  "$XDG_CONFIG_HOME/yarn/global/node_modules/.bin"
  "$XDG_CONFIG_HOME/zsh/bin"
  "$HOME/.govm/shim"
  "$HOME/.krew/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.rvm/bin"
  "$HOME/.yarn/bin"
  "$(go env GOPATH)/bin"
)

for dir in "${paths[@]}"; do
  path.add.safe "$dir"
done
