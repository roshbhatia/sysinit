{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

let
  # Function to resolve a possibly relative path to an absolute path
  resolvePath = path:
    let
      resolvedPath = if lib.strings.hasPrefix "/" path
        then path
        else if inputs ? sysinit  # When used as a dependency
        then toString (inputs.sysinit + "/${path}")
        else toString (inputs.self + "/${path}");  # When used directly
    in
    builtins.trace "Resolving ${path} to ${resolvedPath}" resolvedPath;

  # Get wallpaper path from userConfig or use default
  wallpaperPath = resolvePath (
    if userConfig ? wallpaper && userConfig.wallpaper ? path 
    then userConfig.wallpaper.path
    else "wall/pain.jpeg"
  );

  # Get files to install from userConfig or use empty list
  filesToInstall = if userConfig ? install
                  then builtins.trace "Installing files: ${toString (map (x: x.source) userConfig.install)}" userConfig.install
                  else [];

  # Function to install a file
  installFile = { source, destination }:
    let
      resolvedSource = resolvePath source;
      result = {
        target = destination;
        source = resolvedSource;
        force = true;
      };
    in
    builtins.trace "Installing ${source} (${resolvedSource}) to ${destination}" result;

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