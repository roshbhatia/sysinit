{
  config,
  lib,
  pkgs,
  ...
}:

let
  signedBin = "${
    config.users.users.${config.sysinit.user.username}.home
  }/${(import ../shared/codesign.nix).signedBinDir}";
  menus = pkgs.stdenv.mkDerivation {
    name = "menus";
    src = ./home/sketchybar/helpers/menus;
    buildPhase = "make";
    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/menus $out/bin/
    '';
  };

  monitor-reload-script = pkgs.sysinit.writeShellScript "sketchybar-monitor-reload" ''
    set -euo pipefail
    exec ${lib.getExe pkgs.python3} ${./sketchybar-health.py} \
      --sketchybar ${pkgs.sketchybar}/bin/sketchybar \
      --komorebic ${signedBin}/komorebic
  '';
in
{
  services.sketchybar = {
    enable = true;
    extraPackages = [
      pkgs.sbarlua
      pkgs.lua55Packages.cjson
      menus
    ];
  };

  launchd.user.agents.sketchybar-monitor-reload = {
    serviceConfig = {
      Label = "com.sketchybar-monitor-reload.default";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${monitor-reload-script}"
      ];
      RunAtLoad = true;
      StartInterval = 30;
      StandardOutPath = "/tmp/sketchybar-reload.log";
      StandardErrorPath = "/tmp/sketchybar-reload.error.log";
      EnvironmentVariables.PATH = "${
        lib.makeBinPath [
          pkgs.komorebi
          pkgs.sketchybar
          pkgs.coreutils
          pkgs.gnused
        ]
      }:/usr/bin:/bin";
    };
  };
}
