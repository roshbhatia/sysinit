{ lib, pkgs, ... }:

let
  publisher = pkgs.writeText "vorgossos-mdns-aliases.nu" (builtins.readFile ./lan-aliases.nu);
in
{
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
