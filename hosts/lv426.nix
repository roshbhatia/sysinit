# lv426 - Primary macOS workstation
{ pkgs, config, ... }:

{
  # User configuration
  sysinit.user.username = "rbha18";

  # Homebrew casks
  homebrew.casks = [
    "betterdiscord-installer"
    "discord"
    "ghostty"
    "steam"
  ];

  # Theme
  stylix = {
    base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
    polarity = "dark";
  };

  # Home-manager
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      # macOS gets language runtimes system-wide
      ../modules/home/packages/language-runtimes.nix
    ];

    programs.home-manager.enable = true;
  };
}
