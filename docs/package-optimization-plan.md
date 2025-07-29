# Package Manager Optimization Plan

## Current Performance Issues

The current `task nix:refresh` takes a long time even when packages don't need reinstallation due to:

1. **Full homebrew update**: `brew update` downloads latest formulae data
2. **Nix store rebuilds**: Full evaluation even when no changes occurred  
3. **Sequential operations**: No parallelization of independent tasks
4. **Redundant checks**: Re-evaluating unchanged configurations

## Optimization Strategy

### Phase 1: Intelligent Caching

**Implement configuration checksums**:
```bash
# Store hash of current configuration
CURRENT_HASH=$(find modules/ -name "*.nix" -exec cat {} \; | shasum -a 256)
STORED_HASH_FILE="$HOME/.cache/sysinit/config-hash"

if [[ -f "$STORED_HASH_FILE" ]] && [[ "$(cat $STORED_HASH_FILE)" == "$CURRENT_HASH" ]]; then
    echo "Configuration unchanged, skipping nix rebuild"
    exit 0
fi
```

**Homebrew change detection**:
```bash
# Only update homebrew if Brewfile changed
BREWFILE_HASH=$(shasum -a 256 Brewfile | cut -d' ' -f1)
STORED_BREWFILE_HASH="$HOME/.cache/sysinit/brewfile-hash"

if [[ "$(cat $STORED_BREWFILE_HASH 2>/dev/null)" != "$BREWFILE_HASH" ]]; then
    brew bundle --cleanup
    echo "$BREWFILE_HASH" > "$STORED_BREWFILE_HASH"
fi
```

### Phase 2: Nix Store Integration

**Use nix-env for package management**:
- Replace homebrew casks with nix packages where possible
- Leverage nix store's inherent caching and deduplication
- Enable binary cache for faster downloads

**Package mapping**:
```nix
# Replace homebrew casks with nix equivalents
nixPackages = with pkgs; [
  # Development tools available in nix
  nodejs yarn python3 go rust
  
  # CLI tools with better nix support  
  fd ripgrep bat jq yq tree htop
  
  # Applications available in nixpkgs
  firefox chromium vscode
];

# Keep only macOS-specific tools in homebrew
homebrewCasks = [
  "aerospace"        # Window manager
  "wezterm"         # Terminal (until nix version stabilizes)
  "displayplacer"   # Display management
];
```

### Phase 3: Parallel Execution

**Concurrent task execution**:
```bash
# Run independent tasks in parallel
{
    # Nix system rebuild
    darwin-rebuild switch --flake . &
    NIX_PID=$!
    
    # Homebrew updates (if needed)
    if [[ "$BREWFILE_CHANGED" == "true" ]]; then
        brew bundle --cleanup &
        BREW_PID=$!
    fi
    
    # Wait for completion
    wait $NIX_PID
    [[ -n "$BREW_PID" ]] && wait $BREW_PID
}
```

### Phase 4: Incremental Updates

**Smart dependency tracking**:
```nix
# Track which modules changed
let
  changedModules = lib.filterAttrs (name: path: 
    builtins.pathExists (path + "/.changed")
  ) allModules;
  
  # Only rebuild affected configurations
  incrementalConfig = lib.mkIf (changedModules != {}) {
    # Apply only changed modules
  };
in
```

## Performance Targets

- **Full rebuild**: < 60 seconds (from ~5 minutes)
- **No-change refresh**: < 5 seconds (from ~2 minutes)  
- **Incremental updates**: < 30 seconds
- **Homebrew integration**: Only when Brewfile changes

## Implementation Steps

1. **Add caching layer** to detect configuration changes
2. **Migrate GUI apps** from homebrew to nix where stable packages exist
3. **Implement parallel execution** for independent operations
4. **Add progress indicators** and better error handling  
5. **Create benchmark suite** to measure improvements

## Benefits

- **Faster development cycle**: Quick iterations on configuration changes
- **Better resource utilization**: Leverage nix store's deduplication
- **Reduced network usage**: Skip unnecessary downloads
- **Improved reliability**: Less dependency on external package managers