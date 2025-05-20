{
  lib,
  pkgs,
  homeDirectory,
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
      address = false;
      dns = [ ];
      dnsHosts = {
        "host.docker.internal" = "host.lima.internal";
      };
      hostAddresses = false;
    };
    forwardAgent = false;
    docker = { };
    vmType = "vz";
    rosetta = true;
    nestedVirtualization = true;
    mountType = "sshfs";
    mountInotify = false;
    cpuType = "host";
    provision = [ ];
    sshConfig = true;
    sshPort = 0;
    mounts = [ ];
    diskImage = "";
  };

  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML { } colimaConfig);
in
{
  xdg.configFile."colima/default/colima.yaml" = {
    source = colimaYaml;
    force = true;
  };

  launchd.agents.colima = {
    config = {
      ProgramArguments = [
        "${pkgs.colima}/bin/colima"
        "start"
      ];
      EnvironmentVariables = {
        HOME = homeDirectory;
        XDG_CONFIG_HOME = "${homeDirectory}/.config";
      };
      RunAtLoad = true;
      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };
      ProcessType = "Interactive";
      StandardOutPath = "/var/log/colima.log";
      StandardErrorPath = "/var/log/colima.error.log";
    };
  };

}
