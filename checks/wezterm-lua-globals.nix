{
  pkgs,
  ...
}:
# Every global the wezterm lua tree reads, against the Lua standard library.
let
  allowed = [
    "_G"
    "error"
    "io"
    "ipairs"
    "load"
    "math"
    "os"
    "package"
    "pairs"
    "pcall"
    "require"
    "setmetatable"
    "string"
    "table"
    "tonumber"
    "tostring"
    "type"
  ];
in
pkgs.runCommand "wezterm-lua-globals-check"
  {
    nativeBuildInputs = [ pkgs.lua5_4 ];
    src = ../modules/home/programs/wezterm/lua;
    allowed = builtins.concatStringsSep "\n" allowed;
  }
  ''
    printf '%s\n' "$allowed" | sort > "$TMPDIR/allowed"

    find "$src" -name '*.lua' -print0 | while IFS= read -r -d ''' f; do
      luac -l -l "$f" \
        | grep -o '_ENV "[a-zA-Z_][a-zA-Z0-9_]*"' \
        | sed 's/_ENV "//; s/"$//'
    done | sort -u > "$TMPDIR/seen"

    if ! extra=$(comm -23 "$TMPDIR/seen" "$TMPDIR/allowed") || [ -n "$extra" ]; then
      echo "FAIL: the wezterm lua tree reads globals that Lua does not provide:" >&2
      printf '  %s\n' $extra >&2
      echo "" >&2
      echo "Each one is a local that was deleted, renamed, or misspelled." >&2
      echo "It compiles and evaluates to nil, so no parse check can see it." >&2
      exit 1
    fi

    echo "OK: every global read is a Lua builtin" | tee "$out"
  ''
