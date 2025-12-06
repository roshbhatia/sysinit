{ values, pkgs, ... }:

{
  imports = [
    ./configurations
    ./configurations/hardware.nix
  ];

  system.stateVersion = "24.11";

  networking.hostName = values.user.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    wget
    curl
    git
  ];

  services.resolved.enable = true;
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
