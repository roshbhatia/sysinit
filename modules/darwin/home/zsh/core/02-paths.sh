#!/usr/bin/env zsh
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

if [[ -d "$HOME/.config/zsh/extras" ]]; then
  for file in "$HOME/.config/zsh/extras/"*.sh(N); do
    if [[ -f "$file" ]]; then
      if [[ -n "$SYSINIT_DEBUG" ]]; then
        log_debug "Sourcing file" path="$file"
        source "$file"
      else
        source "$file"
      fi
    fi
  done
fi

if [[ -f "$HOME/.zshsecrets" ]]; then
  if [[ -n "$SYSINIT_DEBUG" ]]; then
    log_debug "Sourcing secrets file" path="$HOME/.zshsecrets"
    source "$HOME/.zshsecrets"
  else
    source "$HOME/.zshsecrets"
  fi
fi
