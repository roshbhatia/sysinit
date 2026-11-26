{
  config,
  k0s-nix,
  lib,
  pkgs,
  ...
}:

let
  bootstrap = pkgs.writeScriptBin "vorgossos-bootstrap" ''
    #!${lib.getExe pkgs.nushell} --no-config-file
    ${builtins.readFile ./bootstrap.nu}
  '';
in
{
  imports = [ k0s-nix.nixosModules.default ];
  nixpkgs.overlays = [ k0s-nix.overlays.default ];

  networking.firewall = {
    interfaces.enp2s0 = {
      allowedTCPPorts = [ 6443 ];
      allowedUDPPorts = [ 8472 ];
    };
    checkReversePath = "loose";
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.accept_local" = 1;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_user_watches" = 1048576;
  };

  services.k0s = {
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

  systemd.services.k0s.unitConfig.ConditionPathExists = [
    "|/var/lib/k0s/pki/ca.crt"
    "|/var/lib/k0s/allow-fresh-cluster"
  ];

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
      kubecolor
      kubectl
      kubernetes-helm
    ]);
  };
}
