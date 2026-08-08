{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  # The rules travel as data rather than as generated bash. The shell version
  # spliced each regex into an array literal, so a quote in a rule changed the
  # meaning of the script it was embedded in.
  rulesFile =
    pkgs: pkgs.writeText "destructive-deny-rules.json" (builtins.toJSON allowlist.destructiveDenyRules);

  mkGuard =
    subcommand:
    { pkgs, name }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.sysinit-agent ];
      bashOptions = [ ];
      text = ''
        exec sysinit-agent ${subcommand} --rules ${rulesFile pkgs} "$@"
      '';
    };
in
{
  mkBashGuard = mkGuard "bash-guard";

  # Not a wrapper around the bash guard: the exit-code form decides for itself.
  # The shell original forked the inner guard and read its stdout, so an inner
  # failure produced no output and the command was let through.
  mkExitCodeGuard = mkGuard "exit-code-guard";
}
