# Base configuration for all macOS (Darwin) hosts
{ pkgs, config, ... }:

{
  # Common macOS system packages
  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    # Common packages for all macOS hosts
    home.packages = with pkgs; [
      curl
      wget
      unzip
      zip
      htop
      ripgrep
      fd
      bat
      eza
      gh
    ];

    programs.home-manager.enable = true;
  };
}
