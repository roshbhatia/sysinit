# Base configuration for all macOS (Darwin) hosts
{ pkgs, config, ... }:

{
  # Common macOS system packages
  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      # macOS gets language runtimes system-wide
      ../../modules/home/packages/language-runtimes.nix
    ];

    # Duplicate packages removed - now in categorized package files:
    # - cli-tools.nix (curl, wget, unzip, zip, htop, ripgrep, fd, bat, eza, gh)
    # These are auto-imported via modules/home/packages/default.nix

    programs.home-manager.enable = true;
  };
}
