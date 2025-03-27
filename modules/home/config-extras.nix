{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

let
  # Function to resolve a possibly relative path to an absolute path
  resolvePath = path:
    if lib.strings.hasPrefix "/" path
    then path
    else if inputs ? ${baseNameOf path} 
    then "${inputs.${baseNameOf path}}/${path}"
    else "${inputs.self}/${path}";

  # Get wallpaper path from userConfig or use default
  wallpaperPath = resolvePath (
    if userConfig ? wallpaper && userConfig.wallpaper ? path 
    then userConfig.wallpaper.path
    else "./wall/mvp2.jpg"
  );
                 
  # Get files to install from userConfig or use empty list
  filesToInstall = if userConfig ? install
                  then userConfig.install
                  else [];
                  
  # Function to install a file
  installFile = { source, destination }:
    {
      target = destination;
      source = resolvePath source;
      force = true;
    };
    
  # Map the install configurations to home-manager file objects
  homeManagerFiles = builtins.listToAttrs 
    (map 
      (fileConfig: {
        name = fileConfig.destination;
        value = installFile fileConfig;
      }) 
      filesToInstall);
      
  # Add wallpaper to the file map
  allFiles = homeManagerFiles // { ".wallpaper" = { source = wallpaperPath; force = true; }; };
in
{
  # Install all files including wallpaper
  home.file = allFiles;
}