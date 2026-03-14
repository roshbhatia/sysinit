{
  lib,
  pkgs,
  values,
  hostname,
  ...
}:

{
  networking.hostName = lib.mkDefault hostname;
  networking.networkmanager.enable = true;

  imports = [
    # Shared module options at system level
    ../../shared/options/user.nix
    ../../shared/options/theme.nix
    ../../home/programs/git/options.nix

    ./stylix.nix
  ];

  # Nix configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://cache.iog.io"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 10;
  };

  # Standard user settings (without Lima-specific home)
  users.users.${values.user.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "nixbld"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    ];
  };

  users.groups.${values.user.username} = { };

  # Basic system packages
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    wget
    git
    zsh
    vim
  ];

  programs.zsh.enable = true;

  # Basic SSH settings
  services.openssh = {
    enable = true;
    startWhenNeeded = false;
  };

  # Tailscale VPN
  services.tailscale.enable = true;
  networking.firewall.allowedUDPPorts = [ 41641 ]; # Tailscale
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Fonts
  fonts.packages = with pkgs; [
    terminus_font
    nerd-fonts.terminess-ttf
    fixedsys-excelsior
    maple-mono.NF
  ];

  system.stateVersion = lib.mkDefault "25.11";

  # Localisation
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
