#!/usr/bin/env zsh
# shellcheck disable=all
# Caching utilities for zsh startup optimization

# Cache directories
ZCACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zcache"
ZCACHE_EXTRAS_DIR="$ZCACHE_DIR/extras"
mkdir -p "$ZCACHE_EXTRAS_DIR"

# Debug helper
_cache_debug() {
  [[ -n $SYSINIT_DEBUG ]] && echo "[CACHE] $*" >&2
}

# Clean all zsh caches
cache.clean() {
  echo "Cleaning zsh cache..."
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
  mkdir -p "$ZCACHE_DIR" "$ZCACHE_EXTRAS_DIR"
  echo "Cache cleaned. Restart shell for changes to take effect."
}

# Check if cache is expired (24h expiry)
_cache_expired() {
  local cache="$1"
  local source="$2"

  [[ ! -f $cache || ! -f $source ]] && return 0
  [[ $source -nt $cache ]] && return 0

  local cache_mtime current_time
  cache_mtime=$(stat -f %m "$cache" 2> /dev/null) || return 0
  current_time=$(date +%s 2> /dev/null) || return 0

  ((current_time - cache_mtime > 86400)) && return 0
  return 1
}

# Source file with zcompile caching
cached_source() {
  local source="$1"
  local cache="${ZCACHE_EXTRAS_DIR}/${source:t}.zwc"

  if _cache_expired "$cache" "$source"; then
    _cache_debug "Compiling $source"
    zcompile "$source" 2> /dev/null || true
  fi

  source "$source"
}
