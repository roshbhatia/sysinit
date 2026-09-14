{
  lib,
  pkgs,
  values,
  hostname,
  ...
}:

{
  networking = {
    hostName = lib.mkDefault hostname;
    networkmanager.enable = true;

    firewall.allowedUDPPorts = [ 41641 ];
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  imports = [
    ../../shared/options/user.nix
    ../../shared/options/theme.nix
    ../../home/programs/git/options.nix

    ./stylix.nix
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      extra-substituters = [
        "https://roshbhatia.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://devenv.cachix.org"
        # This host runs sway. nixpkgs-wayland rebuilds the wayland tree.
        "https://nixpkgs-wayland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      fallback = true;
      max-jobs = "auto";
      cores = 0;
      connect-timeout = 10;

      # The 3600 default makes a switch within an hour of a cachix push rebuild
      # every path Nix already recorded as missing.
      narinfo-cache-negative-ttl = 60;
    };

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-old";
    };

    # `auto-optimise-store` hardlinks inside the store lock on every build. Run
    # the optimiser on a schedule instead.
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  users.users.${values.user.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "nixbld"
      "video"
      "audio"
      "docker"
      "libvirtd"
      "kvm"
    ];
    shell = pkgs.nushell;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    ];
  };

  users.groups.${values.user.username} = { };

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    wget
    git
    zsh
    vim
    playerctl
    trash-cli
    pciutils
    usbutils
  ];

  programs.zsh.enable = true;

  services = {
    openssh = {
      enable = true;
      startWhenNeeded = false;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
        # Nushell does not source the POSIX profile that normally prepends the
        # NixOS setuid wrappers. Supply the complete SSH command environment so
        # remote tools resolve the privileged sudo wrapper, not the store copy.
        SetEnv = "SHELL=/run/current-system/sw/bin/zsh PATH=/run/wrappers/bin:/etc/profiles/per-user/${values.user.username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };

    tailscale.enable = true;

    udisks2.enable = true;

    fwupd.enable = true;
  };

  virtualisation.libvirtd.enable = true;

  programs.virt-manager.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  security.sudo.wheelNeedsPassword = false;

  fonts.packages = with pkgs; [
    terminus_font
    nerd-fonts.terminess-ttf
    fixedsys-excelsior
    maple-mono.NF
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
  ];

  console = {
    font = "ter-v20n";
    packages = [ pkgs.terminus_font ];
    earlySetup = true;
  };

  system.stateVersion = lib.mkDefault "26.05";

  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
