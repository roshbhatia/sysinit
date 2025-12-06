{ values, pkgs, ... }:

{
  imports = [
    ./configurations
    ./configurations/hardware.nix
  ];

  # Common NixOS settings across all hosts
  system.stateVersion = "24.11";

  # Hostname from centralized config
  networking.hostName = values.user.hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set timezone
  time.timeZone = "America/Chicago";

  # Localization
  i18n.defaultLocale = "en_US.UTF-8";

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  # Enable systemd-resolved
  services.resolved.enable = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
