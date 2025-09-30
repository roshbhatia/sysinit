{
  lib,
  pkgs,
  values,
  ...
}:

let
  colimaConfig = {
    cpu = values.colima.cpu;
    memory = values.colima.memory;
    disk = values.colima.disk;
    arch = values.colima.arch;
    runtime = values.colima.runtime;
    vmType = values.colima.vmType;
    rosetta = values.colima.rosetta;
    mountType = values.colima.mountType;
    mountInotify = values.colima.mountInotify;
    forwardAgent = values.colima.forwardAgent;
    network = {
      address = true;
    };
    docker = {
      insecure-registries = values.colima.docker.insecureRegistries;
      buildkit = values.colima.docker.buildkit;
      features = {
        buildkit = values.colima.docker.features.buildkit;
      };
    }
    // lib.optionalAttrs (values.colima.docker.registryMirrors != [ ]) {
      registry-mirrors = values.colima.docker.registryMirrors;
    };
    mounts = values.colima.mounts;
  };

  colimaYaml = pkgs.writeText "colima.yaml" (lib.generators.toYAML { } colimaConfig);
in
{
  xdg.configFile."colima/config.yaml" = {
    source = colimaYaml;
    force = true;
  };
}
