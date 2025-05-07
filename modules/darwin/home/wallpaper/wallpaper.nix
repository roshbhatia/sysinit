{ config, lib, pkgs, userConfig ? {}, inputs, ... }:

let
  pathLib = import ../../lib/path.nix { inherit lib; };
  loggerLib = import ../../lib/logger.nix { inherit lib; };
  resolvePath = path:
    let
      flakeRoot = if inputs ? sysinit 
                 then inputs.sysinit
                 else inputs.self;
      resolvedPath = if lib.strings.hasPrefix "/" path
                    then path
                    else toString (flakeRoot + "/${path}");     
      pathExists = builtins.pathExists resolvedPath;
    in
      if pathExists
      then resolvedPath
      else throw "ERROR: Wallpaper file not found at ${resolvedPath}";
  wallpaperPath = 
    if userConfig ? wallpaper && userConfig.wallpaper ? path then
      let 
        path = userConfig.wallpaper.path;
        _ = resolvePath path;
      in path
    else ./images/bladerunner0.jpg;
  resolvedWallpaperPath = resolvePath wallpaperPath;
in
{
  home.activation.wallpaperLogger = loggerLib.mkLogger {
    name = "wallpaper";
    logDir = "/tmp/log";
    logPrefix = "wallpaper";
  }.home.activation.wallpaperLogger;

  home.activation.wallpaperPathExporter = pathLib.mkPathExporter {
    name = "wallpaper";
    additionalPaths = [];
  }.home.activation.wallpaperPathExporter;

  home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Setting wallpaper..."
    set +e
    WALLPAPER_PATH="${resolvedWallpaperPath}"
    echo "Using wallpaper: $WALLPAPER_PATH"
    if [ -f "$WALLPAPER_PATH" ]; then
      OSASCRIPT="/usr/bin/osascript"
      if [ -x "$OSASCRIPT" ]; then
        "$OSASCRIPT" -e 'tell application "Finder" to set desktop picture to POSIX file "'"$WALLPAPER_PATH"'"'
        echo "✅ Wallpaper set successfully"
      else
        echo "⚠️ osascript not found at $OSASCRIPT"
      fi
    else
      echo "⚠️  Wallpaper file not found at $WALLPAPER_PATH"
    fi
    exit 0
  '';
}
