{ pkgs, ... }:
let
  racer = pkgs.writeShellScript "racing-nix-env" ''
    set -euo pipefail
    exec ${pkgs.nushell}/bin/nu --no-config-file ${./fixtures/racing-nix-env.nu} "$@"
  '';
in
(import ./lib.nix { inherit pkgs; }) {
  name = "system-generation-prune";
  script = "system-generation-prune.nu";
  arguments = [
    ../modules/darwin/prune-system-generations.sh
    racer
    pkgs.hello
    pkgs.jq
    pkgs.coreutils
    pkgs.bash
  ];
  inputs = [
    pkgs.bash
    pkgs.nix
  ];
}
