{ config, lib, pkgs, username, ... }:

let
  colimaConfig = {
    cpu = 2;
    disk = 100;
    memory = 2;
    arch = "host";
    runtime = "docker";
    hostname = null;
    kubernetes = {
      enabled = false;
      version = "v1.31.2+k3s1";
      k3sArgs = ["--disable=traefik"];
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
    vmType = "qemu";
    rosetta = false;
    nestedVirtualization = false;
    mountType = "sshfs";
    mountInotify = false;
    cpuType = "host";
    provision = [];
    sshConfig = true;
    sshPort = 0;
    mounts = [];
    diskImage = "";
    env = {};
  };

  # Generate YAML from the config using lib.generators.toYAML
  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML {} colimaConfig);
in
{
  home-manager.users.${username}.home.file = {
    ".config/colima/default/colima.yaml".source = colimaYaml;
  };

  # Add the Colima service configuration to activationScripts
  system.activationScripts.colima.text = ''
    # Set up Colima to respect XDG_CONFIG_HOME
    COLIMA_SERVICE="/opt/homebrew/Cellar/colima/*/homebrew.colima.service"
    if [ -f $COLIMA_SERVICE ]; then
      echo "Configuring Colima service to respect XDG_CONFIG_HOME..."
      sed -i.bak '/^Environment="PATH=/a\\Environment="XDG_CONFIG_HOME=~/.config"\n\\Environment="COLIMA_HOME=~/.config/colima/.colima"' $COLIMA_SERVICE
    fi
    
    # Create symlink for Colima Docker socket
    mkdir -p $HOME/.docker
    if [ -S $HOME/.config/colima/default/docker.sock ]; then
      ln -sf $HOME/.config/colima/default/docker.sock $HOME/.docker/docker.sock
    fi
  '';
}