{
  lib,
  overlay,
  pkgs,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };

  colimaConfig = {
    cpu = 6;
    disk = 50;
    memory = 8;
    arch = "host";
    runtime = "docker";
    kubernetes = {
      enabled = false;
    };
    autoActivate = true;
    network = {
      dnsHosts = {
        "host.docker.internal" = "host.lima.internal";
      };
    };
    mounts = [
      {
        location = "/usr/local/share/ca-certificates/";
        writeable = true;
      }
    ];
    vmType = "vz";
    rosetta = true;
    nestedVirtualization = true;
    mountType = "sshfs";
    cpuType = "host";
  };

  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML { } colimaConfig);
in
{
  xdg.configFile."colima/_templates/colima.yaml" = {
    source = colimaYaml;
    force = true;
  };

  home.file.".local/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };
}
