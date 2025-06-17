{
  lib,
  pkgs,
  ...
}:

let
  colimaConfig = {
    cpu = 6;
    disk = 50;
    memory = 8;
    arch = "host";
    runtime = "docker";
    hostname = "colima.local";
    kubernetes = {
      enabled = false;
    };
    autoActivate = true;
    network = {
      dnsHosts = {
        "host.docker.internal" = "host.lima.internal";
      };
    };
    vmType = "vz";
    rosetta = true;
    nestedVirtualization = true;
    mountType = "sshfs";
    cpuType = "host";
  };

  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML { } colimaConfig);
in
{
  xdg.configFile."colima/default/colima.yaml" = {
    source = colimaYaml;
    force = true;
  };

  xdg.configFile."zsh/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };
}
