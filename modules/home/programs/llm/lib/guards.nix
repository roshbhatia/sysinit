{ lib }:
let
  allowlist = import ./allowlist.nix { inherit lib; };
in
rec {

  rulesFile =
    pkgs: pkgs.sysinit.writeJSON "destructive-deny-rules.json" allowlist.destructiveDenyRules;

  mkGateHookScript =
    {
      pkgs,
      name,
      harness,
      event,
      format ? "claude",
    }:
    pkgs.sysinit.writeShellApplication {
      inherit name;
      text = ''
        ${lib.optionalString (harness == "claude") ''
          export GATE_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/gate/native-output.yaml"
        ''}
        exec ${lib.getExe pkgs.gate-cli} hook --harness ${harness} --event ${event} --format ${format} "$@"
      '';
    };

  mkGateHook =
    {
      pkgs,
      harness,
      event,
      format ? "claude",
    }:
    lib.getExe (mkGateHookScript {
      inherit
        pkgs
        harness
        event
        format
        ;
      name = "gate-hook-${harness}-${lib.toLower event}";
    });
}
