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
  isRancherBackend = backend == "rancher-desktop";

  rancherStartScript = pkgs.writeShellScriptBin "rancher-desktop-start" ''
    #!/usr/bin/env bash
    set -euo pipefail

    APP_NAME="Rancher Desktop"
    SOCKET="${HOME}/.rd/docker.sock"

    # Start Rancher Desktop if not running (quiet, no UI bounce)
    if ! pgrep -f "Rancher Desktop" >/dev/null 2>&1; then
      echo "Starting ${APP_NAME}..."
      open -gja "${APP_NAME}" || true
    else
      echo "${APP_NAME} is already running"
    fi

    # Wait for Docker socket (requires Moby/dockerd engine enabled in Rancher Desktop)
    echo "Waiting for Docker socket at ${SOCKET} ..."
    for i in {1..120}; do
      if [ -S "${SOCKET}" ]; then
        break
      fi
      sleep 1
    done

    if [ ! -S "${SOCKET}" ]; then
      echo "Docker socket not found at ${SOCKET}."
      echo "Ensure Rancher Desktop is configured to use 'dockerd (moby)' as the container engine."
      exit 0
    fi

    echo "Setting up Docker context for Rancher Desktop..."
    docker context create rancher-desktop --docker "host=unix://${SOCKET}" 2>/dev/null || true
    docker context use rancher-desktop 2>/dev/null || true
  '';
in
{
  config = mkIf (dockerEnabled && isRancherBackend) {
    environment.systemPackages = [
      rancherStartScript
    ] ++ (lib.optional (pkgs ? rancher-desktop) pkgs.rancher-desktop);

    launchd.user.agents.rancher-desktop = {
      serviceConfig = {
        ProgramArguments = [ "${rancherStartScript}/bin/rancher-desktop-start" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/rancher-desktop.log";
        StandardErrorPath = "/tmp/rancher-desktop.error.log";
        ProcessType = "Background";
        StartInterval = 60;
      };
    };
  };
}
