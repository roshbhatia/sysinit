{ pkgs, ... }:

{
  # Core Nix settings available everywhere
  # Minimal essential packages that should exist on every system

  home.packages = with pkgs; [
    # Network utilities
    curl
    wget

    # Basic file operations
    unzip
    zip

    # System monitoring
    htop
  ];

  programs.home-manager.enable = true;
}
