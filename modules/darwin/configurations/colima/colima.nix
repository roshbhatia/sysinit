{
  pkgs,
  ...
}:
let
  colimaConfig = ./configs/colima.yaml;

  colimaStartScript = pkgs.writeShellScriptBin "colima-start" ''
    #!/usr/bin/env bash
    set -e

    if ! colima status >/dev/null 2>&1; then
      echo "Colima is not running, starting it..."
      colima start --config "${colimaConfig}"
    else
      echo "Colima is already running"
    fi
  '';
in
{
  environment.systemPackages = [
    colimaStartScript
  ];

  home.file.".config/colima/config.yaml".source = colimaConfig;

  launchd.agents.colima = {
    enable = true;
    config = {
      ProgramArguments = [ "${colimaStartScript}/bin/colima-start" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/colima.log";
      StandardErrorPath = "/tmp/colima.error.log";
      ProcessType = "Background";
      StartInterval = 60;
    };
  };
}
