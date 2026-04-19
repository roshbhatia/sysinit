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

  # Setup persistent nix store symlinks early in boot before any services start
  boot.postBootCommands = ''
    mkdir -p /nix-vm/store /nix-vm/var
    mkdir -p /nix
    ln -sfn /nix-vm/store /nix/store || true
    ln -sfn /nix-vm/var /nix/var || true
  '';

  # Lima-specific home directory mapping
  users.users.${values.user.username}.home = "/home/${values.user.username}.linux";

  environment.systemPackages = with pkgs; [
    dconf
    dconf-editor
    wezterm
  ];

  services.openssh.ports = [ 55555 ];

  # Auto-login on serial console so no login prompt appears
  services.getty.autologinUser = values.user.username;

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
    extra-substituters = [
      "file:///nix-host/store"
    ];
    trusted-substituters = [
      "file:///nix-host/store"
    ];
  };

  system.stateVersion = lib.mkForce "26.05";
}
