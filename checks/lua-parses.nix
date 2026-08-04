{
  pkgs,
  ...
}:
# Parse gate for the WezTerm Lua modules. `default.nix` calls their
# `setup` functions from `extraConfig`, so a syntax error anywhere aborts
# the whole configuration and the terminal comes up on its built-in
# defaults, losing `default_prog`, `PATH`, and every keybinding.
pkgs.runCommand "lua-parse-check"
  {
    nativeBuildInputs = [ pkgs.lua5_4 ];
  }
  ''
    src=${../modules}
    found=0
    fail=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      found=$((found + 1))
      if ! luac -p "$f"; then
        echo "FAIL: $f does not parse" >&2
        fail=1
      fi
    done < <(find "$src" -name '*.lua' | sort)

    # Same reasoning as the zsh check: `found -eq 0` never fires once
    # the scan root spans several Lua homes. Verified: deleting
    # wezterm/lua left 22 files and the check still passed while
    # reporting success. Each home must contribute.
    require_nonempty() {
      if [ "$(find "$1" -name '*.lua' | wc -l)" -eq 0 ]; then
        echo "FAIL: $1 contributed no .lua files." >&2
        echo "It moved or was renamed, and this check stopped covering it." >&2
        fail=1
      fi
    }
    require_nonempty "$src/home/programs/wezterm/lua"
    require_nonempty "$src/darwin/home/hammerspoon"
    require_nonempty "$src/darwin/home/sketchybar/lua"

    if [ "$found" -eq 0 ]; then
      echo "FAIL: no .lua files found under modules/." >&2
      exit 1
    fi
    if [ "$fail" -ne 0 ]; then
      echo "Fix the module; a parse error drops WezTerm to its defaults." >&2
      exit 1
    fi
    echo "OK: $found lua files parse" | tee "$out"
  ''
