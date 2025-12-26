{
  pkgs,
  ...
}:
let
  menus = pkgs.stdenv.mkDerivation {
    name = "menus";
    src = ../../../darwin/home/configurations/sketchybar/helpers/menus;

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp ./bin/menus $out/bin/
    '';
  };

  monitor-reload-script = pkgs.writeShellScript "sketchybar-monitor-reload" ''
    set -euo pipefail

    HOME="''${HOME:-/Users/$(whoami)}"
    CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
    PREV_HASH_FILE="$CACHE_DIR/monitor-hash"
    LOG_FILE="/tmp/sketchybar-reload.log"

    mkdir -p "$CACHE_DIR" 2>/dev/null || true

    if ! current_monitors=$(${pkgs.aerospace}/bin/aerospace list-monitors 2>/dev/null); then
        echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] ERROR: Failed to get monitor list" >> "$LOG_FILE"
        exit 1
    fi

    current_hash=$(echo "$current_monitors" | ${pkgs.coreutils}/bin/sort | ${pkgs.coreutils}/bin/tr -s '[:space:]' '\n' | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)

    if [ -f "$PREV_HASH_FILE" ]; then
        prev_hash=$(${pkgs.coreutils}/bin/cat "$PREV_HASH_FILE")
    else
        prev_hash=""
    fi

    if [ "$current_hash" != "$prev_hash" ]; then
        echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] Monitor configuration changed" >> "$LOG_FILE"
        echo "Previous hash: $prev_hash" >> "$LOG_FILE"
        echo "Current hash:  $current_hash" >> "$LOG_FILE"
        echo "Monitor list:" >> "$LOG_FILE"
        echo "$current_monitors" | ${pkgs.coreutils}/bin/sed 's/^/  /' >> "$LOG_FILE"

        if ${pkgs.sketchybar}/bin/sketchybar --reload 2>>"$LOG_FILE"; then
            echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] Sketchybar reload successful" >> "$LOG_FILE"
            echo "$current_hash" > "$PREV_HASH_FILE"
        else
            echo "[$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')] ERROR: Sketchybar reload failed" >> "$LOG_FILE"
            exit 1
        fi
    fi
  '';
in
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
  };

  launchd.user.agents.sketchybar-monitor-reload = {
    serviceConfig = {
      Label = "com.sketchybar-monitor-reload.default";
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${monitor-reload-script}"
      ];
      RunAtLoad = true;
      StartInterval = 5;
      StandardOutPath = "/tmp/sketchybar-reload.log";
      StandardErrorPath = "/tmp/sketchybar-reload.error.log";
      EnvironmentVariables = {
        PATH = "${
          pkgs.lib.makeBinPath [
            pkgs.aerospace
            pkgs.sketchybar
            pkgs.coreutils
          ]
        }:/usr/bin:/bin";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    sbarlua
    lua54Packages.cjson
    menus
  ];
}
