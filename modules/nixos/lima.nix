{
  lib,
  pkgs,
  modulesPath,
  values,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  fileSystems = {
    "/boot" = {
      device = lib.mkForce "/dev/vda1";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };
  };

  # Ensure directories exist before binding persistent nix store
  system.activationScripts.createNixDirs = lib.stringAfter [ "var" ] ''
    mkdir -p /nix-vm/store /nix-vm/var
    mkdir -p /nix/store /nix/var
  '';

  users.users.${values.user.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  users.groups.${values.user.username} = { };

  environment.systemPackages = with pkgs; [
    dconf
    dconf-editor
    wezterm
    zsh
  ];

  programs.zsh.enable = true;

  services = {
    lima.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  systemd.user.services.dconf = {
    description = "dconf database";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "ca.desrt.dconf";
      ExecStart = "${pkgs.dconf}/bin/dconf service";
      Restart = "on-failure";
    };
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "file:///nix-host/store"
      "https://cache.iog.io"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    trusted-substituters = [
      "file:///nix-host/store"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 10;
  };

  # Use persistent nix store for VM by symlinking directories
  # This allows nix store to survive VM instance recreation
  system.activationScripts.setupPersistentNix = lib.mkBefore ''
    mkdir -p /nix-vm/store /nix-vm/var
    
    # Only create symlinks if nix directories don't already exist
    if [ ! -L /nix ]; then
      mkdir -p /nix
    fi
    
    # Move default nix store to persistent location if it exists
    if [ -d /nix/store ] && [ ! -L /nix/store ]; then
      mv /nix/store /nix-vm/store/ 2>/dev/null || true
    fi
    if [ -d /nix/var ] && [ ! -L /nix/var ]; then
      mv /nix/var /nix-vm/var/ 2>/dev/null || true
    fi
    
    # Create symlinks
    ln -sfn /nix-vm/store /nix/store || true
    ln -sfn /nix-vm/var /nix/var || true
  '';

  system.stateVersion = lib.mkForce "25.11";
}
