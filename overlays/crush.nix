{ ... }:

final: _prev: {
  crush = final.writeShellScriptBin "crush" ''
    set -euo pipefail

    cache_root="''${XDG_CACHE_HOME:-$HOME/.cache}/crush"
    bin_dir="$cache_root/bin"

    export GOBIN="$bin_dir"
    export GOMODCACHE="$cache_root/gomod"

    if [ ! -x "$bin_dir/crush" ]; then
      mkdir -p "$bin_dir" "$GOMODCACHE"
      "${final.go}/bin/go" install github.com/charmbracelet/crush@v0.43.1
    fi

    exec "$bin_dir/crush" "$@"
  '';
}
