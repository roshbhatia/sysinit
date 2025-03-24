{ lib, pkgs, username, homeDirectory, config ? {}, ... }:

let
  # Get wallpaper path from config or use default
  wallpaperPath = if config ? wallpaper && config.wallpaper ? path 
                 then config.wallpaper.path
                 else "./wall/mvp2.jpg";
                 
  # Get files to install from config or use empty list
  filesToInstall = if config ? install
                  then config.install
                  else [];
                  
  # Function to install a file
  installFile = { source, destination }:
    {
      target = destination;
      source = source;
    };
    
  # Map the install configurations to home-manager file objects
  homeManagerFiles = builtins.listToAttrs 
    (map 
      (fileConfig: {
        name = fileConfig.destination;
        value = installFile fileConfig;
      }) 
      filesToInstall);
in
{
  # Set wallpaper if defined
  home.file.".wallpaper".source = wallpaperPath;
  
  # Install additional files
  home.file = homeManagerFiles;
}