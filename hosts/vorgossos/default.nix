{
  authorizedKeys,
  config,
  k0s-nix,
  lib,
  pkgs,
  ...
}:

let
  storageReady = "${pkgs.util-linux}/bin/findmnt --mountpoint /storage/services --types zfs";
  bootstrap = pkgs.writeScriptBin "vorgossos-bootstrap" ''
    #!${lib.getExe pkgs.nushell} --no-config-file
    ${builtins.readFile ./bootstrap.nu}
  '';
in
{
  imports = [
    k0s-nix.nixosModules.default
    ./lan-aliases.nix
    ./storage.nix
    ./terminal.nix
  ];
  nixpkgs.overlays = [ k0s-nix.overlays.default ];

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "usb_storage"
      "uas"
      "sd_mod"
      "nvme"
    ];
    kernelModules = [ "kvm-intel" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/vorgossos-root";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/VORG-EFI";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  networking = {
    hostName = "vorgossos";
    hostId = "7f14dd83";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
      interfaces.enp2s0 = {
        allowedTCPPorts = [ 6443 ];
        allowedUDPPorts = [ 8472 ];
      };
      checkReversePath = "loose";
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.accept_local" = 1;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_user_watches" = 1048576;
    "kernel.hung_task_timeout_secs" = 300;
    "kernel.hung_task_panic" = 1;
    "kernel.panic" = 10;
    "kernel.panic_on_oops" = 1;
  };
  users.users.rshnbhatia = {
    isNormalUser = true;
    uid = 1000;
    group = "rshnbhatia";
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "kvm"
    ];
    openssh.authorizedKeys.keys = authorizedKeys;
  };
  users.groups.rshnbhatia.gid = 1000;

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      settings.publish = {
        disable-publishing = false;
        publish-addresses = true;
        disable-user-service-publishing = false;
      };
    };
    smartd.enable = true;
    journald.settings.Journal = {
      Storage = "persistent";
      SystemMaxUse = "2G";
    };
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
    k0s = {
      enable = true;
      role = "single";
      package = pkgs.k0s_1_36;
      extraArgs = ''--kubelet-extra-args="--max-pods=128 --resolv-conf=/etc/k0s/kubelet-resolv.conf"'';
      spec = {
        api = {
          address = "192.168.50.37";
          sans = [
            "vorgossos"
            "192.168.50.37"
          ];
        };
        storage.type = "etcd";
        network = {
          provider = "custom";
          kubeProxy.disabled = true;
        };
        telemetry.enabled = false;
      };
    };
  };

  systemd = {
    services = {
      k0s = {
        after = [
          "zfs-import-storage.service"
          "zfs-mount.service"
        ];
        unitConfig = {
          RequiresMountsFor = "/storage/services";
          ConditionPathExists = [
            "|/var/lib/k0s/pki/ca.crt"
            "|/var/lib/k0s/allow-fresh-cluster"
          ];
        };
        serviceConfig.ExecStartPre = storageReady;
      };
      samba-smbd = {
        after = [
          "zfs-import-storage.service"
          "zfs-mount.service"
        ];
        serviceConfig.ExecStartPre = storageReady;
      };
    };
    settings.Manager = {
      RuntimeWatchdogSec = "60s";
      RebootWatchdogSec = "10min";
    };
  };

  environment = {
    etc = {
      "k0s/kubelet-resolv.conf".text = ''
        nameserver 100.100.100.100
        nameserver fd7a:115c:a1e0::53
        nameserver 94.140.14.14
        nameserver 94.140.15.15
        nameserver 192.168.50.1
      '';
      "k0s/containerd.d/kubevirt-devices.toml".text = ''
        version = 3
        [plugins."io.containerd.cri.v1.runtime"]
          device_ownership_from_security_context = true
      '';
    };

    systemPackages = [
      bootstrap
      config.services.k0s.package
    ]
    ++ (with pkgs; [
      git
      k9s
      kubecolor
      kubectl
      kubernetes-helm
    ]);
  };

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "26.05";
}
