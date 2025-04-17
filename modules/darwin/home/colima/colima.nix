{ config, lib, pkgs, ... }:

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
      dns = [];
      dnsHosts = {
        "host.docker.internal" = "host.lima.internal";
      };
      hostAddresses = false;
    };
    forwardAgent = false;
    docker = {};
    vmType = "vz";
    rosetta = true;
    nestedVirtualization = true;
    mountType = "sshfs";
    mountInotify = false;
    cpuType = "host";
    provision = [];
    sshConfig = true;
    sshPort = 0;
    mounts = [];
    diskImage = "";
  };

  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML {} colimaConfig);
in
{
  xdg.configFile."colima/default/colima.yaml" = {
    source = colimaYaml;
  };

  home.activation.setupColima = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Set up Colima to respect XDG_CONFIG_HOME and match Homebrew service configuration
    COLIMA_SERVICE="/opt/homebrew/Cellar/colima/*/homebrew.colima.service"
    if [ -f $COLIMA_SERVICE ]; then
      echo "Configuring Colima service..."
      $DRY_RUN_CMD sed -i.bak '
        s|Environment=HOME=${HOME}|Environment=HOME=${HOME} Environment=XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}|
      ' $COLIMA_SERVICE
    fi
  '';
}