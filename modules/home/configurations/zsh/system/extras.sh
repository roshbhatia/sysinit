#!/usr/bin/env zsh
# shellcheck disable=all
# Debug logging function
log_debug()
            {
  [[ -n "$SYSINIT_DEBUG" ]] && echo "[DEBUG] $*" >&2
}

# Setup cache directories
ZCACHE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zcache"
ZCACHE_EXTRAS_DIR="$ZCACHE_DIR/extras"
mkdir -p "$ZCACHE_EXTRAS_DIR"

# Cache cleaning function
function cache.clean()
                       {
  echo "Cleaning zsh cache..."
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
  mkdir -p "$ZCACHE_DIR" "$ZCACHE_EXTRAS_DIR"
}

# Check cache freshness (24h expiry)
_cache_expired()
                 {
  local cache="$1"
  local source="$2"

  # If cache doesn't exist or source doesn't exist, it's expired
  [[ ! -f "$cache" || ! -f "$source" ]] && return 0

  # If source is newer than cache, it's expired
  [[ "$source" -nt "$cache" ]] && return 0

  # Check if cache is older than 24h using macOS compatible stat
  local cache_mtime
  if ! cache_mtime=$(stat -f %m "$cache" 2> /dev/null); then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Failed to get cache mtime" cache="$cache"
    return 0
  fi

  local current_time
  if ! current_time=$(date +%s 2> /dev/null); then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Failed to get current time"
    return 0
  fi

  local day_seconds=86400
  if ((current_time - cache_mtime > day_seconds)); then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Cache expired" cache="$cache" age=$((current_time - cache_mtime))
    return 0
  fi

  return 1
}

# Source with caching
_cached_source()
                 {
  local source="$1"
  local cache="${ZCACHE_EXTRAS_DIR}/${source:t}.zwc"

  if _cache_expired "$cache" "$source"; then
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Compiling" path="$source" reason="cache expired"
    if ! zcompile "$source"; then
      [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Failed to compile" path="$source"
    fi
  else
    [[ -n "$SYSINIT_DEBUG" ]] && log_debug "Using cached version" path="$source"
  fi

  source "$source"
}

# Source extras
EXTRAS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/extras"
[[ -n "$SYSINIT_DEBUG" ]] && log_debug "Checking extras directory" dir="$EXTRAS_DIR"

if [[ -d "$EXTRAS_DIR" ]]; then
  setopt nullglob
  local extra_files=("$EXTRAS_DIR"/*.sh)
  unsetopt nullglob

  if ((${#extra_files[@]})); then
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
  source "$HOME/.zshsecrets"
fi
