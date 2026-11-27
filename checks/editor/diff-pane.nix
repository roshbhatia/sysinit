{ pkgs }:
let
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
in
nuCheck {
  name = "diff-pane";
  script = ./diff-pane.nu;
  inputs = [
    pkgs.flock
    pkgs.git
  ];
  arguments = [
    ../../features
    ../fixtures/review-tools.nu
    ../../features/wezterm/ty.nu
  ];
}
