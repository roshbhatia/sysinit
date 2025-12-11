{
  values,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./configurations
    ./configurations/hardware.nix
  ];

  system.stateVersion = "24.11";

  users.users.${values.user.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${values.user.username}";
    group = values.user.username;
    shell = pkgs.zsh;
  };

  users.groups.${values.user.username} = { };

  networking.hostName = lib.mkDefault "nixos";
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
