{
  config,
  pkgs,
  lib,
  values,
  ...
}:
let
  colimaConfig = ./configs/colima.yaml;

  colimaStartScript = pkgs.writeShellScriptBin "colima-start" ''
    #!/usr/bin/env bash
    set -e

    if ! colima status >/dev/null 2>&1; then
      echo "Colima is not running, starting it..."
      colima start --config "/etc/colima/config.yaml"
      
      # Set up Docker context for Colima
      echo "Setting up Docker context for Colima..."
      docker context create colima --docker "host=unix://${config.users.users.${values.user.username}.home}/.config/colima/default/docker.sock" 2>/dev/null || true
      docker context use colima
    else
      echo "Colima is already running"
      # Ensure we're using the colima context
      docker context use colima 2>/dev/null || true
    fi
  '';
in
{
  config = lib.mkIf values.darwin.colima.enable {
    environment.systemPackages = [
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
