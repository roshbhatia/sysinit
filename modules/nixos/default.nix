{
  config,
  values,
  pkgs,
  lib,
  hostname ? "nixos",
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

  # Sudo configuration
  security.sudo.enable = true;

  # Hostname - set from system configuration
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

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
