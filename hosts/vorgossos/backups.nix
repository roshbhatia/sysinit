{ lib, pkgs, ... }:

let
  backupMount = device: fsType: {
    inherit device fsType;
    options = [
      "nofail"
      "x-systemd.device-timeout=30"
    ];
  };
  backup = pkgs.writeText "vorgossos-backup.nu" (builtins.readFile ./backup.nu);
in
{
  environment.systemPackages = [ pkgs.restic ];
  fileSystems = {
    "/mnt/backup" = backupMount "/dev/disk/by-uuid/3ba26cd3-d050-4c45-9f64-c1f026bd28f2" "ext4";
    "/mnt/backup2" = backupMount "/dev/disk/by-uuid/57FDB52459632363" "ntfs3";
  };

  systemd = {
    services.restic-backup = {
      description = "Back up the Vorgossos ZFS datasets";
      after = [
        "zfs-mount.service"
        "mnt-backup.mount"
      ];
      wants = [ "mnt-backup.mount" ];
      path = [
        pkgs.restic
        pkgs.util-linux
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.nushell} --no-config-file ${backup}";
        TimeoutStartSec = "6h";
        IOSchedulingClass = "idle";
      };
    };

    timers.restic-backup = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:30:00";
        RandomizedDelaySec = "15min";
        Persistent = true;
      };
    };
  };

  services.sanoid = {
    enable = true;
    datasets.storage = {
      recursive = true;
      frequently = 0;
      hourly = 0;
      daily = 7;
      weekly = 2;
      monthly = 1;
      yearly = 0;
      autosnap = true;
      autoprune = true;
    };
  };
}
