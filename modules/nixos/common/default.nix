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
    auto-optimise-store = true;
  };

  # Nix garbage collection — weekly, keep 7 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Standard user settings
  users.users.${values.user.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "nixbld"
      "video"
      "audio"
      "docker"
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
    playerctl # media key support
    trash-cli # safe rm alternative
    pciutils # lspci
    usbutils # lsusb
  ];

  programs.zsh.enable = true;

  # SSH — hardened
  services.openssh = {
    enable = true;
    startWhenNeeded = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # mDNS / network discovery (Sunshine auto-discovery, .local hostnames)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Tailscale VPN
  services.tailscale.enable = true;
  networking.firewall.allowedUDPPorts = [ 41641 ]; # Tailscale
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # USB auto-mount
  services.udisks2.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Swap (zram — compressed in-memory swap)
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Fonts — full coverage
  fonts.packages = with pkgs; [
    terminus_font
    nerd-fonts.terminess-ttf
    fixedsys-excelsior
    maple-mono.NF
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf # Microsoft metric-compatible
  ];

  # Console font (TTY + tuigreet)
  console = {
    font = "ter-v20n";
    packages = [ pkgs.terminus_font ];
    earlySetup = true;
  };

  system.stateVersion = lib.mkDefault "25.11";

  # Localisation
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
