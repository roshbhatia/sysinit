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

  sunshine-apps-gen = pkgs.writeScriptBin "sunshine-apps-gen" ''
    #!${pkgs.python3}/bin/python3
    """Regenerate ~/.config/sunshine/apps.json from installed games.

    Sources:
      - Steam: steamapps/appmanifest_*.acf (skips runtimes/tooling)
      - Heroic Epic: legendaryConfig/legendary/installed.json
      - Heroic GOG: gog_store/installed.json + store_cache titles/art
      - Wine apps: Ubisoft Connect / EA app prefixes under ~/Games/prefixes

    Cover art is converted/downloaded to PNG (Sunshine only renders PNG).
    Rerun after installing or removing games, then restart sunshine.
    """
    import getpass
    import json
    import re
    import subprocess
    import urllib.request
    from pathlib import Path

    MAGICK = "${pkgs.imagemagick}/bin/magick"

    HOME = Path.home()
    STEAMAPPS = HOME / ".local/share/Steam/steamapps"
    LIBCACHE = HOME / ".local/share/Steam/appcache/librarycache"
    HEROIC = HOME / ".config/heroic"
    COVERS = HOME / ".config/sunshine/covers"
    APPS_JSON = HOME / ".config/sunshine/apps.json"

    SKIP = re.compile(r"Proton|Steam Linux Runtime|Steamworks|EasyAntiCheat")

    RES_PREP = {"do": "sunshine-res set", "undo": "sunshine-res restore"}
    KILL_PREP = {"do": "", "undo": "pkill -f gamescope; pkill -f steam; true"}
    KILL_PREP_HEROIC = {"do": "", "undo": "pkill -f gamescope; pkill -f heroic; true"}
    KILL_PREP_WINE = {"do": "", "undo": "pkill -f gamescope; pkill -f umu; true"}


    def png_from_jpg(src, appid):
        COVERS.mkdir(parents=True, exist_ok=True)
        dst = COVERS / (appid + ".png")
        if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
            subprocess.run([MAGICK, str(src), str(dst)], check=True)
        return str(dst)


    def png_from_url(url, key):
        if not url:
            return None
        COVERS.mkdir(parents=True, exist_ok=True)
        dst = COVERS / (key + ".png")
        if dst.exists():
            return str(dst)
        try:
            raw = COVERS / (key + ".raw")
            urllib.request.urlretrieve(url, raw)
            subprocess.run([MAGICK, str(raw), str(dst)], check=True)
            raw.unlink(missing_ok=True)
            return str(dst)
        except Exception:
            return None


    def steam_games():
        out = []
        for acf in sorted(STEAMAPPS.glob("appmanifest_*.acf")):
            text = acf.read_text(errors="replace")
            appid = re.search(r'"appid"\s+"(\d+)"', text)
            name = re.search(r'"name"\s+"([^"]+)"', text)
            if not appid or not name or SKIP.search(name.group(1)):
                continue
            appid, name = appid.group(1), name.group(1)
            entry = {
                "name": name,
                "cmd": "steam-run-game " + appid,
                "prep-cmd": [RES_PREP, KILL_PREP],
            }
            art = LIBCACHE / appid / "library_600x900.jpg"
            if art.exists():
                entry["image-path"] = png_from_jpg(art, appid)
            out.append(entry)
        return out


    def heroic_games():
        out = []
        installed = HEROIC / "legendaryConfig/legendary/installed.json"
        lib_cache = HEROIC / "store_cache/legendary_library.json"
        art_by_app = {}
        if lib_cache.exists():
            lib = json.loads(lib_cache.read_text())
            for g in lib.get("library", []):
                art_by_app[g.get("app_name")] = g.get("art_cover") or g.get("art_square")
        if installed.exists():
            for app_name, meta in json.loads(installed.read_text()).items():
                if meta.get("is_dlc"):
                    continue
                title = meta.get("title") or app_name
                entry = {
                    "name": title,
                    "cmd": "heroic-run-game legendary " + app_name,
                    "prep-cmd": [RES_PREP, KILL_PREP_HEROIC],
                }
                art = png_from_url(art_by_app.get(app_name), "epic-" + app_name)
                if art:
                    entry["image-path"] = art
                out.append(entry)
        gog_installed = HEROIC / "gog_store/installed.json"
        gog_lib = HEROIC / "store_cache/gog_library.json"
        title_by_app, art_by_gog = {}, {}
        if gog_lib.exists():
            lib = json.loads(gog_lib.read_text())
            for g in lib.get("games", []):
                title_by_app[g.get("app_name")] = g.get("title")
                art_by_gog[g.get("app_name")] = g.get("art_cover") or g.get("art_square")
        if gog_installed.exists():
            for g in json.loads(gog_installed.read_text()).get("installed", []):
                app_name = g.get("appName")
                title = title_by_app.get(app_name) or app_name
                entry = {
                    "name": title,
                    "cmd": "heroic-run-game gog " + app_name,
                    "prep-cmd": [RES_PREP, KILL_PREP_HEROIC],
                }
                art = png_from_url(art_by_gog.get(app_name), "gog-" + app_name)
                if art:
                    entry["image-path"] = art
                out.append(entry)
        return out


    def extra_apps():
        """User-curated entries (EA/Ubisoft games, one-offs) merged verbatim.

        ~/.config/sunshine/extra-apps.json: {"apps": [{name, cmd, image-path?}]}
        Entries get the standard prep-cmds unless they carry their own.
        """
        path = APPS_JSON.parent / "extra-apps.json"
        if not path.exists():
            return []
        out = []
        for entry in json.loads(path.read_text()).get("apps", []):
            entry.setdefault("prep-cmd", [RES_PREP, KILL_PREP_WINE])
            out.append(entry)
        return out


    games = steam_games() + heroic_games() + extra_apps()

    user = getpass.getuser()
    apps = {
        "env": {
            "PATH": "/etc/profiles/per-user/" + user + "/bin:/run/current-system/sw/bin",
            "WAYLAND_DISPLAY": "wayland-1",
            "XDG_RUNTIME_DIR": "/run/user/1000",
            "DISPLAY": ":0",
        },
        "apps": [
            {"name": "Desktop", "prep-cmd": [RES_PREP], "image-path": "desktop.png"},
            {
                "name": "Steam Big Picture",
                "cmd": "steam-bigpicture",
                "prep-cmd": [RES_PREP, KILL_PREP],
                "image-path": "steam.png",
            },
        ]
        + sorted(games, key=lambda g: g["name"].lower()),
    }

    APPS_JSON.write_text(json.dumps(apps, indent=2) + "\n")
    print("wrote " + str(APPS_JSON) + " with " + str(len(games)) + " entries:")
    for g in sorted(games, key=lambda g: g["name"].lower()):
        print("  " + g["name"])
  '';
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
