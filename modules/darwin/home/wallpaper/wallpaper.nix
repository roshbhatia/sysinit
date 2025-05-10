{ config, lib, pkgs, userConfig ? {}, inputs, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
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
    else ./images/berserk1.jpg;
  resolvedWallpaperPath = resolvePath wallpaperPath;
in
{
  # Use our new activation framework to create a custom activation script
  home.activation.setWallpaper = activationUtils.mkActivationScript {
    description = "Setting macOS wallpaper";
    requiredExecutables = [ "/usr/bin/osascript" ];
    after = [ "setupActivationUtils" "writeBoundary" ];
    script = ''
      WALLPAPER_PATH="${resolvedWallpaperPath}"
      log_info "Using wallpaper: $WALLPAPER_PATH"
      
      if [ -f "$WALLPAPER_PATH" ]; then
        log_command "/usr/bin/osascript -e 'tell application \"Finder\" to set desktop picture to POSIX file \"$WALLPAPER_PATH\"'" "Setting desktop wallpaper"
        log_success "Wallpaper set successfully"
      else
        log_error "Wallpaper file not found at $WALLPAPER_PATH"
      fi
    '';
  };
}
