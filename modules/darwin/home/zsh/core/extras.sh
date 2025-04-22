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

# Source with combined caching
_cached_source() {
  local source="$1"
  local combined_cache="$ZCACHE_EXTRAS_DIR/combined.zwc"
  local hash_file="$ZCACHE_EXTRAS_DIR/combined.hash"
  local current_hash

  # Generate hash of all source files
  if [[ -f "$source" ]]; then
    current_hash=$(sha256sum "$source" | cut -d' ' -f1)
  fi

  # Check if cache needs updating
  if [[ ! -f "$combined_cache" ]] || \
     [[ ! -f "$hash_file" ]] || \
     [[ "$(cat "$hash_file")" != "$current_hash" ]]; then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Recompiling cache" path="$source"
    zcompile -R "$source" "$combined_cache"
    echo "$current_hash" > "$hash_file"
  fi

  source "$combined_cache"
}

# Source extras
EXTRAS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"
if [[ -d "$EXTRAS_DIR" ]]; then
  for file in "$EXTRAS_DIR/"*.sh(N); do
    if [[ -f "$file" ]]; then
      [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Loading" file="$file"
      _cached_source "$file"
    fi
  done
fi

# Source secrets with caching
if [[ -f "$HOME/.zshsecrets" ]]; then
  [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Caching file" file="$file"
  _cached_source "$HOME/.zshsecrets"
fi
