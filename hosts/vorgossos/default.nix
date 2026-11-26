{ authorizedKeys, pkgs, ... }:

{
  imports = [
    ./backups.nix
    ./cluster.nix
    ./hardware.nix
    ./lan-aliases.nix
    ./storage.nix
    ./terminal.nix
  ];

  networking = {
    hostName = "vorgossos";
    useDHCP = false;
    interfaces.enp2s0.useDHCP = true;
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
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
  };

  environment.systemPackages = [ pkgs.git ];

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
