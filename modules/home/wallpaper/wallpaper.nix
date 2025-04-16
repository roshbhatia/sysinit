{ config, lib, pkgs, userConfig ? {}, inputs, ... }:

let
  # Function to resolve a possibly relative path to an absolute path with strict validation
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
      
  # Get wallpaper path with strict validation
  wallpaperPath = 
    if userConfig ? wallpaper && userConfig.wallpaper ? path then
      let 
        path = userConfig.wallpaper.path;
        # Verify wallpaper exists before attempting to use it
        _ = resolvePath path;
      in path
    else "wallpaper/images/mvp2.jpeg";
    
  # Get the fully resolved wallpaper path
  resolvedWallpaperPath = resolvePath wallpaperPath;
in
{
  home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Don't let this script fail the entire build
    set +e
    
    echo "🖼️ Setting wallpaper..."
    
    # Set wallpaper path variable explicitly in the main script
    WALLPAPER_PATH="${resolvedWallpaperPath}"
    echo "Using wallpaper: $WALLPAPER_PATH"
    
    if [ -f "$WALLPAPER_PATH" ]; then
      mkdir -p "$HOME/.config/wallpaper"
      ln -sf "$WALLPAPER_PATH" "$HOME/.wallpaper"
      
      cat > "$HOME/.config/wallpaper/set-wallpaper.sh" << 'EOF'
#!/bin/bash
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$HOME/.wallpaper"'"'
EOF
      chmod +x "$HOME/.config/wallpaper/set-wallpaper.sh"
      
      osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$WALLPAPER_PATH"'"'
      echo "✅ Wallpaper set successfully"
    else
      echo "⚠️  Wallpaper file not found at $WALLPAPER_PATH"
    fi
    
    exit 0
  '';
}
