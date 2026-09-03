{ pkgs, ... }:

let
  dropCaps = "setpriv --ambient-caps -all --inh-caps -all --";

  fullscreenLoop = ''
    SOCK=$(find /run/user/1000 -maxdepth 1 -name "sway-ipc.*.sock" 2>/dev/null | head -1)
    if [ -n "$SOCK" ]; then
      for _ in 1 2 3; do
        sleep 5
        SWAYSOCK=$SOCK swaymsg "[app_id=^gamescope$] fullscreen enable" >> "$LOG" 2>&1 || true
      done
    fi
  '';

  gamescopeCmd = ''gamescope -W "$W" -H "$H" -w "$W" -h "$H" --expose-wayland --force-windows-fullscreen -e --'';

  sunshine-res = pkgs.writeShellApplication {
    name = "sunshine-res";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      SOCK=$(find /run/user/1000 -maxdepth 1 -name "sway-ipc.*.sock" 2>/dev/null | head -1)
      [ -n "$SOCK" ] || exit 0
      if [ "''${1:-set}" = "restore" ]; then
        MODE="3840x2160@59.997Hz"
      else
        W=''${SUNSHINE_CLIENT_WIDTH:-1920}
        H=''${SUNSHINE_CLIENT_HEIGHT:-1080}
        case "''${W}x''${H}" in
          2560x1440) MODE="2560x1440@59.951Hz" ;;
          3840x2160) MODE="3840x2160@59.997Hz" ;;
          *) MODE="1920x1080@60Hz" ;;
        esac
      fi
      exec env SWAYSOCK="$SOCK" swaymsg output DP-1 mode "$MODE"
    '';
  };

  steam-bigpicture = pkgs.writeShellApplication {
    name = "steam-bigpicture";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      LOG=/tmp/steam-bigpicture.log
      echo "=== launch $(date) ===" > "$LOG"
      W=''${SUNSHINE_CLIENT_WIDTH:-1920}
      H=''${SUNSHINE_CLIENT_HEIGHT:-1080}
      ${dropCaps} ${gamescopeCmd} steam -gamepadui >> "$LOG" 2>&1 &
      GPID=$!
      ${fullscreenLoop}
      wait $GPID
    '';
  };

  steam-run-game = pkgs.writeShellApplication {
    name = "steam-run-game";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      APPID=$1
      LOG=/tmp/steam-run-game.log
      echo "=== launch appid=$APPID $(date) ===" > "$LOG"
      W=''${SUNSHINE_CLIENT_WIDTH:-1920}
      H=''${SUNSHINE_CLIENT_HEIGHT:-1080}
      ${dropCaps} ${gamescopeCmd} steam -gamepadui "steam://rungameid/$APPID" >> "$LOG" 2>&1 &
      GPID=$!
      ${fullscreenLoop}
      wait $GPID
    '';
  };

  heroic-run-game = pkgs.writeShellApplication {
    name = "heroic-run-game";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      RUNNER=$1
      APP=$2
      LOG=/tmp/heroic-run-game.log
      echo "=== launch $RUNNER/$APP $(date) ===" > "$LOG"
      W=''${SUNSHINE_CLIENT_WIDTH:-1920}
      H=''${SUNSHINE_CLIENT_HEIGHT:-1080}
      ${dropCaps} ${gamescopeCmd} heroic --no-gui "heroic://launch/$RUNNER/$APP" >> "$LOG" 2>&1 &
      GPID=$!
      ${fullscreenLoop}
      wait $GPID
    '';
  };

  steam-run-wineapp = pkgs.writeShellApplication {
    name = "steam-run-wineapp";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      PREFIX_NAME=$1
      EXE=$2
      LOG=/tmp/steam-run-wineapp.log
      echo "=== launch $PREFIX_NAME $(date) ===" > "$LOG"
      W=''${SUNSHINE_CLIENT_WIDTH:-1920}
      H=''${SUNSHINE_CLIENT_HEIGHT:-1080}
      export WINEPREFIX="$HOME/Games/prefixes/$PREFIX_NAME"
      export GAMEID="umu-$PREFIX_NAME"
      export PROTONPATH=GE-Proton
      case "$EXE" in
        /*) EXEPATH=$EXE ;;
        *) EXEPATH=$WINEPREFIX/$EXE ;;
      esac
      # shellcheck disable=SC2016
      ${dropCaps} ${gamescopeCmd} bash -c '
        umu-run "$1"
        base=$(basename "$1")
        sleep 5
        while pgrep -f "$base" > /dev/null; do sleep 3; done
      ' _ "$EXEPATH" >> "$LOG" 2>&1 &
      GPID=$!
      ${fullscreenLoop}
      wait $GPID
    '';
  };

  sunshine-apps-gen = pkgs.writeShellApplication {
    name = "sunshine-apps-gen";
    runtimeInputs = [
      pkgs.imagemagick
      pkgs.python3
    ];
    text = ''
      exec python3 ${./sunshine-apps-gen.py} "$@"
    '';
  };
in
{
  home.packages = [
    sunshine-res
    steam-bigpicture
    steam-run-game
    heroic-run-game
    steam-run-wineapp
    sunshine-apps-gen
  ];

  xdg.configFile."sunshine/sunshine.conf".text = ''
    capture = kms
    encoder = nvenc
  '';
}
