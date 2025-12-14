{
  config,
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

  # Primary user configuration
  users.users.${values.user.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${values.user.username}";
    group = values.user.username;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ]
    ++ lib.optionals config.programs.gamemode.enable [ "gamemode" ];
    description = values.git.name;
  };

  users.groups.${values.user.username} = { };

  # Allow wheel group to use sudo
  security.sudo.wheelNeedsPassword = true;

  # Hostname - override per-host in hostConfigs
  networking.hostName = lib.mkDefault "nixos";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Base system packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    vim
    unzip
    file
    pciutils
    usbutils
  ];

  # DNS resolution
  services.resolved.enable = true;

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      trusted-users = [
        "root"
        "@wheel"
        values.user.username
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
