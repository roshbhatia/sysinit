{ config, lib, pkgs, ... }:

{
  home.activation = {
    setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      WALLPAPER_PATH="$HOME/github/roshbhatia/sysinit/wall/mvp2.jpg"
      if command -v osascript &> /dev/null && [ -f "$WALLPAPER_PATH" ]; then
        $DRY_RUN_CMD osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$WALLPAPER_PATH\""
        $DRY_RUN_CMD echo "Wallpaper set successfully!"
      else
        echo "osascript not found or wallpaper file doesn't exist, unable to set wallpaper"
      fi
    '';
  };
}