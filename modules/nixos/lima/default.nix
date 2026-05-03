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
    # Lima VZ passes cidata as an iso9660 block device (label: cidata), not virtiofs.
    # Override the nixos-lima module which expects virtiofs.
    "/mnt/lima-cidata" = lib.mkForce {
      device = "/dev/disk/by-label/cidata";
      fsType = "iso9660";
      options = [ "ro" "relatime" "mode=0755" ];
    };
  };

  # Lima VZ uses opaque virtiofs tags — the guest agent handles all mount setup
  # by querying the Lima host agent. Override the nixos-lima module's service to
  # use the guestagent binary from cidata (no nixpkgs package needed).
  systemd.services.lima-guestagent = lib.mkForce {
    description = "Lima guest agent";
    after = [ "network.target" "mnt-lima\\x2dcidata.mount" ];
    requires = [ "mnt-lima\\x2dcidata.mount" ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "simple";
      Restart = "on-failure";
      RestartSec = "10s";
      # iso9660 doesn't preserve execute bits; copy to /run before exec.
      # Use .bin suffix to avoid collision with lima-guestagent's default --runtime-dir.
      ExecStartPre = "${pkgs.coreutils}/bin/install -m 755 /mnt/lima-cidata/lima-guestagent /run/lima-guestagent.bin";
      # --vsock-port: host agent connects via VSOCK (Apple VZ virtio-socket), not Unix socket
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec /run/lima-guestagent.bin daemon --runtime-dir /run/lima-guestagent --vsock-port $(grep ^LIMA_CIDATA_VSOCK_PORT /mnt/lima-cidata/lima.env | cut -d= -f2)'";
    };
  };

  # Lima host agent polls these files before activating mounts and port-forwards.
  # cloud-init normally writes them; we replicate that here for NixOS.
  systemd.services.lima-boot-done = {
    description = "Signal Lima boot completion";
    after = [ "mnt-lima\\x2dcidata.mount" ];
    requires = [ "mnt-lima\\x2dcidata.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'IID=$(grep ^LIMA_CIDATA_IID /mnt/lima-cidata/lima.env | cut -d= -f2) && echo $IID > /run/lima-boot-done && echo $IID > /run/lima-ssh-ready'";
    };
  };

  # Mount virtiofs shares using tags from cloud-init user-data.
  # Lima VZ assigns opaque random tags (lima-XXXXXXXXXXXXXXXX) at VM creation;
  # the authoritative mapping is the mounts: section in /mnt/lima-cidata/user-data.
  systemd.services.lima-virtiofs-mounts = {
    description = "Mount Lima virtiofs shares";
    after = [ "mnt-lima\\x2dcidata.mount" ];
    requires = [ "mnt-lima\\x2dcidata.mount" ];
    before = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "lima-virtiofs-mounts" ''
        set -eu
        MOUNT=${pkgs.util-linux}/bin/mount
        MKDIR=${pkgs.coreutils}/bin/mkdir
        TR=${pkgs.coreutils}/bin/tr
        SED=${pkgs.gnused}/bin/sed
        # Parse: - [lima-TAG, /MOUNTPOINT, virtiofs, "OPTIONS", "0", "0"]
        grep 'virtiofs' /mnt/lima-cidata/user-data | \
        $SED 's/- \[\([^,]*\), *\([^,]*\), *virtiofs, *"\([^"]*\)".*/\1|\2|\3/' | \
        while IFS='|' read -r tag mp opts; do
          tag="$(echo "$tag" | $TR -d ' ')"
          mp="$(echo "$mp" | $TR -d ' ')"
          opts="$(echo "$opts" | $TR -d ' ')"
          [ -n "$tag" ] || continue
          $MKDIR -p "$mp"
          $MOUNT -t virtiofs "$tag" "$mp" -o "$opts" || true
        done
      '';
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
  users.users.${values.user.username} = {
    home = "/home/${values.user.username}.linux";
    # Lima host key — nixos-rebuild overwrites /etc/ssh/authorized_keys.d/<user>
    # and would drop the Lima key added by cloud-init, so we include it here.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG63ZUOskeb22JGJW4bgMeWDjdXZvu0s2QKM0cdME1BP lima"
    ];
  };

  environment.systemPackages = with pkgs; [
    dconf
  ];

  # Headless VM — disable auto-theming entirely; autoEnable would detect any
  # GTK package in the closure and pull in gjs → libadwaita (which fails tests
  # without a display server)
  stylix.autoEnable = lib.mkForce false;

  # virt-manager (GTK3) and libvirtd are not useful inside a Lima VM;
  # disabling removes the libadwaita/GTK dependency chain from the closure
  programs.virt-manager.enable = lib.mkForce false;
  virtualisation.libvirtd.enable = lib.mkForce false;

  # Docker socket is forwarded from the host (colima); no daemon needed inside
  virtualisation.docker.enable = lib.mkForce false;

  # Headless build VM — disable test suites for packages with timing-sensitive
  # or display-dependent tests that fail under load (django serializer perf test
  # failed at 5.5x factor vs 2x threshold after 21h of parallel builds)
  nixpkgs.overlays = [
    (_: prev: {
      python313 = prev.python313.override {
        packageOverrides = _: pyPrev: {
          django = pyPrev.django.overridePythonAttrs (_: { doCheck = false; });
        };
      };
    })
  ];

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
