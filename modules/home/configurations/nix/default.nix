{
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nil
    nixfmt-rfc-style
    deadnix

    nix-output-monitor
  ];

  home.sessionVariables = {
    NIXPKGS_ALLOW_UNFREE = "1";
    NIX_CONFIG = "experimental-features = nix-command flakes";
  };
}

