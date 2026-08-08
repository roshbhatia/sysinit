{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  sq = s: "'" + builtins.replaceStrings [ "'" ] [ "'\\''" ] s + "'";

  preamble = ''
    DENY_REGEXES=(
      ${lib.concatMapStringsSep "\n      " (r: sq r.regex) allowlist.destructiveDenyRules}
    )
    DENY_REASONS=(
      ${lib.concatMapStringsSep "\n      " (r: sq r.reason) allowlist.destructiveDenyRules}
    )
  '';
  mkBashGuard =
    { pkgs, name }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = preamble + "\n" + builtins.readFile ../runtime/bash-guard.sh;
    };
in
{
  inherit mkBashGuard;

  mkExitCodeGuard =
    { pkgs, name }:
    let
      inner = mkBashGuard {
        inherit pkgs;
        name = "${name}-inner";
      };
    in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.jq ];
      bashOptions = [ ];
      text = ''
        GUARD_EXE=${lib.getExe inner}
      ''
      + "\n"
      + builtins.readFile ../runtime/exit-code-guard.sh;
    };
}
