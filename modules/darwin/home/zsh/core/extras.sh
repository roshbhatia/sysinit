#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

# Setup cache directories
ZCACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zcache"
ZCACHE_EXTRAS_DIR="$ZCACHE_DIR/extras"
mkdir -p "$ZCACHE_EXTRAS_DIR"

# Cache cleaning function
function cache.clean() {
  echo "Cleaning zsh cache..."
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
  mkdir -p "$ZCACHE_DIR" "$ZCACHE_EXTRAS_DIR"
}

# Check cache freshness (24h expiry)
_cache_expired() {
  local cache="$1"
  local source="$2"
  [[ ! -f "$cache" ]] || \
  [[ ! -f "$source" ]] || \
  [[ "$cache" -ot "$source" ]] || \
  [[ $(find "$cache" -mtime +1) ]]
}

# Source with caching
_cached_source() {
  local source="$1"
  local cache="${ZCACHE_EXTRAS_DIR}/${source:t}.zwc"

  if _cache_expired "$cache" "$source"; then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Compiling" path="$source"
    zcompile "$source"
  fi

  source "$source"
}

# Source extras
EXTRAS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"
[[ -n "$SYSINIT_DEBUG" ]] && log_debug "Checking extras directory" dir="$EXTRAS_DIR"

if [[ -d "$EXTRAS_DIR" ]]; then
  setopt null_glob
  local extra_files=("$EXTRAS_DIR"/*.sh)
  unsetopt null_glob
  
  if (( ${#extra_files[@]} )); then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Found extras" count="${#extra_files[@]}"
    for file in "${extra_files[@]}"; do
      [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Loading extra" file="$file"
      _cached_source "$file"
    done
  else
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "No extras found in directory" dir="$EXTRAS_DIR"
  fi
else
  [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Extras directory does not exist" dir="$EXTRAS_DIR"
fi

# Source secrets
if [[ -f "$HOME/.zshsecrets" ]]; then
  [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Loading secrets" file="$HOME/.zshsecrets"
  _cached_source "$HOME/.zshsecrets"
fi
