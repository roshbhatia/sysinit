{ pkgs, ... }:

let
  storageReady = "${pkgs.util-linux}/bin/findmnt --mountpoint /storage/services --types zfs";
  storageUnits = [
    "zfs-import-storage.service"
    "zfs-mount.service"
  ];
in
{
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      extraPools = [ "storage" ];
      forceImportRoot = false;
    };
    extraModprobeConfig = "options zfs zfs_arc_max=8589934592";
  };

  networking.hostId = "7f14dd83";

  systemd.services = {
    k0s = {
      after = storageUnits;
      unitConfig.RequiresMountsFor = "/storage/services";
      serviceConfig.ExecStartPre = storageReady;
    };
    samba-smbd = {
      after = storageUnits;
      serviceConfig.ExecStartPre = storageReady;
    };
  };

  services = {
    smartd.enable = true;
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="block", ENV{ID_VENDOR_ID}=="152d", ENV{ID_MODEL_ID}=="0578", ATTR{queue/max_sectors_kb}="240", ATTR{queue/nr_requests}="64", ATTR{queue/read_ahead_kb}="128"
      ACTION=="add|change", SUBSYSTEM=="scsi_device", ATTRS{idVendor}=="152d", ATTRS{idProduct}=="0578", ATTR{queue_depth}="4"
    '';
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "map to guest" = "Bad User";
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:encoding" = "native";
          "fruit:metadata" = "stream";
          "fruit:zero_file_id" = "yes";
          "fruit:nfs_aces" = "no";
        };
        storage = {
          path = "/storage";
          browseable = "yes";
          "guest ok" = "yes";
          "read only" = "no";
          "force user" = "rshnbhatia";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
  };
}
