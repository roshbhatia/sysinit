{
  config,
  pkgs,
  lib,
  values,
  ...
}:
let
  inherit (lib) mkIf;

  dockerEnabled = values.darwin.docker.enable or false;
  backend = values.darwin.docker.backend or "colima";
  isPodmanBackend = backend == "podman";

  podmanStartScript = pkgs.writeShellScriptBin "podman-start" ''
    #!/usr/bin/env bash
    set -e

    if ! podman machine list | grep -q "podman-machine-default"; then
      echo "Initializing Podman machine..."
      podman machine init --cpus 6 --memory 12288 --disk-size 100 --rootful
    fi

    if ! podman machine inspect podman-machine-default | grep -q '"State": "running"'; then
      echo "Starting Podman machine..."
      podman machine start
    else
      echo "Podman machine is already running"
    fi

    echo "Setting up Docker-compatible socket..."
    docker context create podman --docker "host=unix://${
      config.users.users.${values.user.username}.home
    }/.local/share/containers/podman/machine/podman.sock" 2>/dev/null || true
    docker context use podman
  '';
in
{
  config = mkIf (dockerEnabled && isPodmanBackend) {
    environment.systemPackages = [
      podmanStartScript
    ];

    launchd.user.agents = {
      podman = {
        serviceConfig = {
          ProgramArguments = [ "${podmanStartScript}/bin/podman-start" ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/podman.log";
          StandardErrorPath = "/tmp/podman.error.log";
          ProcessType = "Background";
          StartInterval = 60;
        };
      };
    };
  };
}
