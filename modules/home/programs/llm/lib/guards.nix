{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  # The rules travel as data rather than as generated bash.
  rulesFile =
    pkgs: pkgs.writeText "destructive-deny-rules.json" (builtins.toJSON allowlist.destructiveDenyRules);

  # A compiled wrapper that only binds the rules file, rather than a shell script: this
  # runs on every Bash tool call, and a shell in front of it is a fork per call.
  mkGuard =
    subcommand:
    { pkgs, name }:
    pkgs.runCommand name
      {
        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
        meta.mainProgram = name;
      }
      ''
        mkdir -p "$out/bin"
        makeWrapper ${pkgs.utils}/bin/${subcommand} "$out/bin/${name}" \
          --add-flags "--rules ${rulesFile pkgs}"
      '';
in
{
  mkBashGuard = mkGuard "bash-guard";

  # Not a wrapper around the bash guard: the exit-code form decides for itself.
  mkExitCodeGuard = mkGuard "exit-code-guard";
}
