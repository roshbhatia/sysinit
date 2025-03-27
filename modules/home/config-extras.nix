{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

{
  home.file = let
    # Function to resolve a possibly relative path to an absolute path with error checking
    resolvePath = path:
      let
        flakeRoot = if inputs ? sysinit 
                   then inputs.sysinit
                   else inputs.self;
        resolvedPath = if lib.strings.hasPrefix "/" path
                      then path
                      else toString (flakeRoot + "/${path}");
      in
        if builtins.pathExists resolvedPath
        then resolvedPath
        else builtins.trace "Warning: File not found at ${resolvedPath}" resolvedPath;

    # Get wallpaper path with validation
    wallpaperPath = resolvePath (
      if userConfig ? wallpaper && userConfig.wallpaper ? path 
      then userConfig.wallpaper.path
      else "wall/mvp2.jpeg"
    );

    # Get files to install
    filesToInstall = if userConfig ? install
                    then userConfig.install
                    else [];
                    
    # Convert install configs to home-manager file format with validation
    homeManagerFiles = builtins.listToAttrs 
      (map 
        (fileConfig: {
          name = fileConfig.destination;
          value = {
            source = resolvePath fileConfig.source;
            target = fileConfig.destination;
            force = true;
            onChange = ''
              if [ -e "$HOME/${fileConfig.destination}" ]; then
                echo "✓ Successfully installed: $HOME/${fileConfig.destination}"
                ls -la "$HOME/${fileConfig.destination}"
              else
                echo "✗ Failed to install: $HOME/${fileConfig.destination}"
              fi
            '';
          };
        }) 
        filesToInstall);

  in
    # Merge with wallpaper config
    homeManagerFiles // { 
      ".wallpaper" = { 
        source = wallpaperPath; 
        force = true;
        onChange = ''
          if [ -e "$HOME/.wallpaper" ]; then
            echo "✓ Wallpaper installed successfully"
            ls -la "$HOME/.wallpaper"
          else
            echo "✗ Wallpaper installation failed"
          fi
        '';
      }; 
    };

  # Additional home-manager settings
  programs.home-manager = {
    enable = true;
  };

  # Remove old symlinks before creating new ones
  home.activation = {
    linkCleanup = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      echo "Cleaning up old symlinks..."
      for file in $(find "$HOME" -maxdepth 1 -type l -name ".*"); do
        if [ -L "$file" ] && [ ! -e "$file" ]; then
          echo "Removing broken symlink: $file"
          rm "$file"
        fi
      done
    '';
  };
}