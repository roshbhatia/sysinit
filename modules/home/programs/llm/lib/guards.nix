{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  # The rules travel as data rather than as generated bash.
  rulesFile =
    pkgs: pkgs.writeText "destructive-deny-rules.json" (builtins.toJSON allowlist.destructiveDenyRules);

  mkGuard =
    subcommand:
    { pkgs, name }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.utils ];
      bashOptions = [ ];
      text = ''
        exec utils ${subcommand} --rules ${rulesFile pkgs} "$@"
      '';
    };
in
{
  mkBashGuard = mkGuard "bash-guard";

  # Not a wrapper around the bash guard: the exit-code form decides for itself.
  mkExitCodeGuard = mkGuard "exit-code-guard";
}
