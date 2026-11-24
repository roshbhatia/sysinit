{ pkgs }:
import ../lib/nushell.nix { inherit pkgs; } {
  name = "github-runner-guard";
  script = ./github-runner-guard.nu;
  arguments = [ ../../modules/nixos/github-runner-guard.sh ];
  inputs = [ pkgs.bash ];
}
