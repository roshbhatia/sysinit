{ config, lib, pkgs, ... }:
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.

#                888d8b                      
#                888Y8P                      
#                888                         
# .d8888b .d88b. 88888888888b.d88b.  8888b.  
# d88P"   d88""88b888888888 "888 "88b    "88b 
# 888     888  888888888888  888  888.d888888 
# Y88b.   Y88..88P888888888  888  888888  888 
#  "Y8888P "Y88P" 888888888  888  888"Y888888

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
  # Colima configuration file
  home.file = {
    ".config/colima/default/colima.yaml".source = colimaYaml;
  };
}