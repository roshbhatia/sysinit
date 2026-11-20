{ pkgs }:
let
  inherit (pkgs) lib;
  module = import ../modules/home/programs/pueue {
    inherit lib pkgs;
    config = {
      sysinit.queue.enable = true;
      xdg.stateHome = "/tmp/queue-test-state";
    };
  };
  files = module.config.content.xdg.configFile;
  bridge = pkgs.writeText "queue-bridge.zsh" files."carapace/bridge/zsh/.zshrc".text;
  spec = pkgs.writeText "pueue.yaml" files."carapace/specs/pueue.yaml".text;
  tqSpec = pkgs.writeText "tq.yaml" files."carapace/specs/tq.yaml".text;
in
import ./lib.nix { inherit pkgs; } {
  name = "tq-test";
  script = "tq.nu";
  arguments = [
    bridge
    spec
    tqSpec
    (lib.getExe (builtins.head module.config.content.home.packages))
  ];
  inputs = [
    pkgs.pueue
    pkgs.taskwarrior-cli
    pkgs.seshy
    pkgs.bash
    pkgs.zsh
    pkgs.carapace
  ];
}
