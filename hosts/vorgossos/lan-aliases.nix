{ lib, pkgs, ... }:

let
  publisher = pkgs.writeText "vorgossos-mdns-aliases.nu" (builtins.readFile ./lan-aliases.nu);
in
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    settings.publish = {
      disable-publishing = false;
      publish-addresses = true;
      disable-user-service-publishing = false;
    };
  };

  systemd.services.mdns-aliases = {
    description = "Publish homelab Gateway routes over mDNS";
    after = [
      "avahi-daemon.service"
      "k0s.service"
    ];
    wants = [ "avahi-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    environment.KUBECONFIG = "/var/lib/k0s/pki/admin.conf";
    path = [
      pkgs.avahi
      pkgs.kubectl
    ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.nushell} --no-config-file ${publisher}";
      Restart = "always";
      RestartSec = "30s";
    };
  };
}
