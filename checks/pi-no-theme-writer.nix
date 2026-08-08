{
  pkgs,
  lib,
  ...
}:
let
  piKeys = import ../modules/home/programs/llm/harnesses/pi/settings-keys.nix;
  vendored = lib.optionalString (builtins.elem "theme" piKeys.declared) "yes";
in
pkgs.runCommand "pi-no-theme-writer-check" { nativeBuildInputs = [ pkgs.ripgrep ]; } ''
  declared=${lib.escapeShellArg vendored}
  if [ -z "$declared" ]; then
    echo "OK: pi does not declare theme, so an extension may own it" | tee "$out"
    exit 0
  fi

  src=${pkgs.pi-coding-agent}/pi/examples/extensions
  fail=0
  for f in ${
    lib.concatStringsSep " " (
      map (n: lib.escapeShellArg n) (
        import ../modules/home/programs/llm/harnesses/pi/vendored-extensions.nix
      )
    )
  }; do
    p="$src/$f.ts"
    [ -f "$p" ] || continue
    if rg -q 'setTheme' "$p"; then
      echo "FAIL: vendored extension '$f' calls setTheme while pi.nix declares 'theme'." >&2
      echo "      Pi persists that write, and every declared key is enforced, so the two" >&2
      echo "      fight silently and the generated theme is active in zero sessions." >&2
      fail=1
    fi
  done

  [ "$fail" -eq 0 ] || exit 1
  echo "OK: no vendored pi extension writes the theme" | tee "$out"
''
