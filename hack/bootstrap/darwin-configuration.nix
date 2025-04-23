{ pkgs, ... }:
{
  # Set Git commit hash for darwin-version.
  system.configurationRevision = null;

  # Used for backwards compatibility
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # IMPORTANT: Disable nix management for Determinate Nix compatibility
  nix.enable = false;
  
  # Fix for permission denied issues
  nix.settings = {
    trusted-users = [ "root" "__CURRENT_USER__" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # Packages to install
  environment.systemPackages = with pkgs; [
    git
    curl
    libgit2  # Add libgit2 to system packages
  ];
  
  # Enable Touch ID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;
}