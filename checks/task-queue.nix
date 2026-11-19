{ pkgs }:
let
  module = import ../modules/home/programs/pueue {
    inherit pkgs;
    inherit (pkgs) lib;
    config = {
      sysinit.queue.enable = true;
      xdg.stateHome = "/tmp/queue-test-state";
    };
  };
  files = module.config.content.xdg.configFile;
  bridge = pkgs.writeText "queue-bridge.zsh" files."carapace/bridge/zsh/.zshrc".text;
  spec = pkgs.writeText "pueue.yaml" files."carapace/specs/pueue.yaml".text;
  queueSpec = pkgs.writeText "task-queue.yaml" files."carapace/specs/task-queue.yaml".text;
in
import ./lib.nix { inherit pkgs; } {
  name = "task-queue-test";
  script = "task-queue.nu";
  arguments = [
    bridge
    spec
    queueSpec
    "${pkgs.sysinit-gotools}/bin/task-queue"
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
