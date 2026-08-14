{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };

  rulesFile =
    pkgs: pkgs.writeText "destructive-deny-rules.json" (builtins.toJSON allowlist.destructiveDenyRules);

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
        makeWrapper ${pkgs.sysinit-utils}/bin/${subcommand} "$out/bin/${name}" \
          --add-flags "--rules ${rulesFile pkgs}"
      '';
in
{
  mkBashGuard = mkGuard "bash-guard";

  mkExitCodeGuard = mkGuard "exit-code-guard";
}
