{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

{
  home.file = let
    # Function to resolve a possibly relative path to an absolute path
    resolvePath = path:
      let
        flakeRoot = if inputs ? sysinit 
                   then inputs.sysinit
                   else inputs.self;
      in
      if lib.strings.hasPrefix "/" path
      then path
      else toString (flakeRoot + "/${path}");

    # Get wallpaper path
    wallpaperPath = resolvePath (
      if userConfig ? wallpaper && userConfig.wallpaper ? path 
      then userConfig.wallpaper.path
      else "wall/mvp2.jpeg"
    );

    # Get files to install
    filesToInstall = if userConfig ? install
                    then userConfig.install
                    else [];
                    
    # Convert install configs to home-manager file format
    homeManagerFiles = builtins.listToAttrs 
      (map 
        (fileConfig: {
          name = fileConfig.destination;
          value = {
            source = resolvePath fileConfig.source;
            target = fileConfig.destination;
            force = true;
          };
        }) 
        filesToInstall);

  in
    # Merge with wallpaper config
    homeManagerFiles // { 
      ".wallpaper" = { 
        source = wallpaperPath; 
        force = true;
      }; 
    };

  # Disable backup files
  home.activation = {
    removeExistingLinks = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      find "${homeDirectory}" -maxdepth 1 -type l -name ".*" -delete
    '';
  };

  # Additional home-manager settings
  programs.home-manager = {
    enable = true;
    backupFileExtension = null;  # Disable backup files
  };
}