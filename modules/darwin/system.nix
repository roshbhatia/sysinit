{ pkgs, lib, ... }: {
  # System configuration
  system = {
    # System defaults
    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "Always";
        # Fast key repeat rate
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
      };
      dock = {
        autohide = true;
        orientation = "bottom";
      };
      finder = {
        AppleShowAllExtensions = true;
        QuitMenuItem = true;
        ShowPathbar = true;
      };
    };
  };

  # Nix configuration
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    substituters = ["https://cache.nixos.org/"];
  };

  # Used for backwards compatibility
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Auto upgrade nix package and the daemon service
  services.nix-daemon.enable = true;
}
