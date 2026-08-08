{
  pkgs,
  lib,
  system,
  ...
}:
let
  checks = import ./. {
    inherit pkgs lib system;
  };

  otherChecks = removeAttrs checks [ "check-bodies-shellcheck" ];

  bodies = lib.mapAttrsToList (name: drv: {
    inherit name;
    body = drv.drvAttrs.buildCommand;
  }) otherChecks;
in
pkgs.runCommand "check-bodies-shellcheck-check" { nativeBuildInputs = [ pkgs.shellcheck ]; } (
  ''
    fail=0
    checked=0
  ''
  + lib.concatMapStrings (b: ''
    checked=$((checked + 1))
    body_file="$TMPDIR/check-body-$checked.sh"
    printf '%s' ${lib.escapeShellArg b.body} > "$body_file"
    if ! shellcheck -s bash -e SC2154,SC1091 "$body_file"; then
      echo "  ^ in the body of check '${b.name}'" >&2
      fail=1
    fi
  '') bodies
  + ''
    if [ "$checked" -eq 0 ]; then
      echo "FAIL: no check bodies were linted, so this gate covers nothing." >&2
      echo "No check other than this gate exposed drvAttrs.buildCommand." >&2
      exit 1
    fi
    [ "$fail" -eq 0 ] || {
      echo "Fix the finding, or add a targeted 'shellcheck disable' with a reason." >&2
      exit 1
    }
    echo "OK: $checked check bodies pass shellcheck" | tee "$out"
  ''
)
