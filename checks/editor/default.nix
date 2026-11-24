{ pkgs, homeManagerLib }:
let
  inherit (pkgs) lib;
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
in
{
  editor-workbench = import ./editor-workbench.nix { inherit pkgs; };

  review-links = nuCheck {
    name = "review-links";
    script = ./review-links.nu;
    inputs = [
      pkgs.git
      pkgs.lua5_4
    ];
    arguments = [
      (lib.getExe (import ../../modules/home/programs/llm/runtime/diff/review-link.nix { inherit pkgs; }))
      ../../modules/home/programs/wezterm/links.lua
      ./review-links.lua
    ];
  };

  diff-pane = import ./diff-pane.nix { inherit pkgs; };

  editor-composition = import ./editor-composition.nix { inherit pkgs homeManagerLib; };

  editor-config = import ./editor-config.nix { inherit pkgs; };
}
