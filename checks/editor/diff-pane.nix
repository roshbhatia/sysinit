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
    pkgs.neovim-unwrapped
  ];
  arguments = [
    ../../modules/home/programs/llm/runtime/diff
    ../fixtures/review-tools.nu
    ../../modules/home/programs/utils/dev/ty.nu
  ];
}
