{ pkgs }:
let
  inherit (pkgs) lib;
  module = import ../../modules/home/programs/pueue {
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
  queueSpec = pkgs.writeText "task-queue.yaml" files."carapace/specs/task-queue.yaml".text;
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "tq-test";
  script = ./tq.nu;
  sources = [
    ../lib/carapace.nu
    ../lib/process.nu
  ];
  arguments = [
    bridge
    spec
    tqSpec
    queueSpec
    "${../../modules/home/programs/nushell}/tasks.nu"
  ];
  inputs = [
    pkgs.pueue
    pkgs.taskwarrior-cli
    pkgs.seshy
    pkgs.bash
    pkgs.zsh
    pkgs.carapace
    pkgs.task-queue
    pkgs.task-board
  ];
}
