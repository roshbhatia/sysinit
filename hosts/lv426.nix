# lv426 - Primary macOS workstation
{ pkgs, ... }:

{
  # Homebrew casks (host-specific)
  homebrew.casks = [
    "betterdiscord-installer"
    "discord"
    "ghostty"
    "steam"
  ];

  # Theme override (optional - can be removed to use default from common.nix)
  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
    polarity = "dark";
  };
}
