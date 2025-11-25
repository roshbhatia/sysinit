{
  config,
  pkgs,
  lib,
  values,
  utils,
  ...
}:
{
  imports = [
    ./configurations
    ./packages
    ../lib/nixos-modules/validation.nix
  ];

  # Enable Nix flakes
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    package = pkgs.nixFlakes;

    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set timezone
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # System-wide environment variables
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
