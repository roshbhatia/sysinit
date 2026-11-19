{ pkgs }:
import ./lib.nix { inherit pkgs; } {
  name = "task-command-contracts";
  script = "task-commands.nu";
  arguments = [
    pkgs.go-task.version
    pkgs.taskwarrior-cli
  ];
  inputs = [
    pkgs.go-task
    pkgs.taskwarrior-cli
    pkgs.zsh
  ];
}
