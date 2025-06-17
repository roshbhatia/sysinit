{
  lib,
  overlay,
  pkgs,
  ...
}:

let
  additionalInsecureRegistries = (overlay.docker.insecureRegistries or [ ]);

  dockerConfig = {
    "insecure-registries" = additionalInsecureRegistries;
    credsStore = "osxkeychain";
    currentContext = "colima";
    hosts = [
      "unix:///Users/${overlay.user.username}/.config/colima/default/docker.sock"
    ];
  };

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
    docker = dockerConfig;
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
  dockerJson = pkgs.writeText "docker.json" (lib.generators.toJSON { } dockerConfig);
  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML { } colimaConfig);
in
{
  xdg.configFile."docker/config.json" = {
    source = dockerJson;
    force = true;
  };

  # Colima has issues respecting XDG, and hacky brew service edits don't persist.
  home.file.".colima/_templates/colima.yaml" = {
    source = colimaYaml;
    force = true;
  };

  xdg.configFile."zsh/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };
}

