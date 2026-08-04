# Shellcheck every check's own build script.
#
# The repository lints `hack/`, `.githooks/`, `runtime/`, and `skills/` strictly,
# and never linted its largest body of shell: roughly 1,500 lines living inside Nix
# string blocks in the checks themselves. That is also where the defects have
# actually been: three assertions that could never fire were found there by
# accident during `reorganize-llm-module-layout`, plus a guard that failed open and
# a `perl` edit that emptied four paths.
#
# Rather than relocate those bodies into `.sh` files, which would rewrite every
# derivation and risk changing the tests while moving them, this reads each check's
# `drvAttrs.buildCommand` directly. That string is what bash actually runs, with
# every `${...}` already resolved to a store path, so it is the real artifact and
# not a copy of it.
#
# Deliberately excludes itself: linting its own body would need this check's
# derivation while defining it.
#
# Two rules are excluded, and only these two, because they are structurally wrong
# for a `runCommand` body rather than merely inconvenient:
#   SC2154  "referenced but not assigned" — stdenv sets `$out`, `$TMPDIR`, and the
#           derivation's own env vars before the script runs, so shellcheck cannot
#           see their assignment and every one is a false positive.
#   SC1091  "not following" — a sourced path is a store path that exists at build
#           time and not at lint time.
# Everything else is reported. A finding that is genuinely benign gets a targeted
# `shellcheck disable` with a reason at its site, not a rule added here.
{
  pkgs,
  lib,
  system,
  ...
}:
let
  checks = import ./. {
    inherit pkgs lib system;
    inputs = null;
  };

  lintable = lib.filterAttrs (
    name: drv: name != "check-bodies-shellcheck" && drv ? drvAttrs && drv.drvAttrs ? buildCommand
  ) checks;

  # Written with a shebang so the shellcheck invocation matches how the repository
  # lints every other script: `-s bash`, no per-file dialect guessing.
  bodyFile = name: drv: pkgs.writeText "check-body-${name}.sh" ("#!/usr/bin/env bash\n" + drv.drvAttrs.buildCommand);

  bodies = lib.mapAttrsToList (name: drv: {
    inherit name;
    file = bodyFile name drv;
  }) lintable;
in
pkgs.runCommand "check-bodies-shellcheck-check" { nativeBuildInputs = [ pkgs.shellcheck ]; } (
  ''
    fail=0
    checked=0
  ''
  + lib.concatMapStrings (b: ''
    checked=$((checked + 1))
    if ! shellcheck -s bash -e SC2154,SC1091 ${b.file}; then
      echo "  ^ in the body of check '${b.name}'" >&2
      fail=1
    fi
  '') bodies
  + ''
    if [ "$checked" -eq 0 ]; then
      echo "FAIL: no check bodies were linted, so this gate covers nothing." >&2
      echo "drvAttrs.buildCommand stopped resolving; the filter above went empty." >&2
      exit 1
    fi
    [ "$fail" -eq 0 ] || {
      echo "Fix the finding, or add a targeted 'shellcheck disable' with a reason." >&2
      exit 1
    }
    echo "OK: $checked check bodies pass shellcheck" | tee "$out"
  ''
)
