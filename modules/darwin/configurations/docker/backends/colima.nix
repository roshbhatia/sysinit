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
  isColimaBackend = backend == "colima";
  
  colimaConfig = ../configs/colima.yaml;

  colimaStartScript = pkgs.writeShellScriptBin "colima-start" ''
    #!/usr/bin/env bash
    set -e

    if ! colima status >/dev/null 2>&1; then
      echo "Colima is not running, starting it..."
      colima start --config "/etc/colima/config.yaml"

      echo "Setting up Docker context for Colima..."
      docker context create colima --docker "host=unix://${
        config.users.users.${values.user.username}.home
      }/.config/colima/default/docker.sock" 2>/dev/null || true
      docker context use colima
    else
      echo "Colima is already running"
      docker context use colima 2>/dev/null || true
    fi
  '';
in
{
  config = mkIf (dockerEnabled && isColimaBackend) {
    environment.systemPackages = [
      pkgs.colima
      colimaStartScript
    ];

    environment.etc."colima/config.yaml".source = colimaConfig;

    launchd.user.agents = {
      colima = {
        serviceConfig = {
          ProgramArguments = [ "${colimaStartScript}/bin/colima-start" ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/colima.log";
          StandardErrorPath = "/tmp/colima.error.log";
          ProcessType = "Background";
          StartInterval = 60;
        };
      };
    };
  };
}
