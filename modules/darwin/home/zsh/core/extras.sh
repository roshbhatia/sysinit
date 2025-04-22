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

# Source with zcompile caching
_cached_source() {
  local source="$1"
  local cache="${source:r:t}.zwc"
  cache="$ZCACHE_EXTRAS_DIR/$cache"

  if _cache_expired "$cache" "$source"; then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Compiling" path="$source"
    zcompile -R "$source" "$cache"
  fi

  source "$cache"
}

# Source extras
if [[ -d "$HOME/.config/zsh/extras" ]]; then
  for file in "$HOME/.config/zsh/extras/"*.sh(N); do
    if [[ -f "$file" ]]; then
      [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Caching file" file="$file"
      _cached_source "$file"
    fi
  done
fi
fi

# Source secrets with caching
if [[ -f "$HOME/.zshsecrets" ]]; then
  _cached_source "$HOME/.zshsecrets"
fi
