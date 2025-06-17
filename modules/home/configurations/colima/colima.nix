{
  lib,
  overlay,
  pkgs,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };

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
  # Docker CLI doesn't respect XDG_CONFIG_HOME, so we need to set it manually.
  home.file.".docker/config.json" = {
    source = dockerJson;
    force = true;
  };

  xdg.configFile."colima/_templates/colima.yaml" = {
    source = colimaYaml;
    force = true;
  };

  home.file.".local/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };

  home.activation.linkDockerSock = activation.mkActivationScript {
    description = "Link docker socket";
    requiredExecutables = [ "ln" ];
    script = ''
      log_command "sudo ln -sf $XDG_CONFIG_HOME/.colima/default/docker.sock /var/run/docker.sock" "Linking docker socket";
    '';
  };
}

