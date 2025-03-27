{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

let
  # Function to resolve a possibly relative path to an absolute path
  resolvePath = path:
    let
      flakeRoot = if inputs ? sysinit 
                 then inputs.sysinit
                 else inputs.self;
      resolvedPath = if lib.strings.hasPrefix "/" path
        then path
        else toString (flakeRoot + "/${path}");
    in
    builtins.trace "Resolving ${path} to ${resolvedPath}" resolvedPath;

  # Get wallpaper path from userConfig or use default
  wallpaperPath = resolvePath (
    if userConfig ? wallpaper && userConfig.wallpaper ? path 
    then userConfig.wallpaper.path
    else "wall/mvp2.jpeg"
  );

  # Get files to install from userConfig or use empty list
  filesToInstall = if userConfig ? install
                  then userConfig.install
                  else [];

  # Function to install a file with verification
  installFile = { source, destination }:
    let
      resolvedSource = resolvePath source;
      targetPath = "${homeDirectory}/${destination}";
      verifyScript = ''
        echo "Verifying ${targetPath}..."
        if [ -L "${targetPath}" ]; then
          echo "✓ Symlink exists: ${targetPath}"
          if [ -f "${targetPath}" ]; then
            echo "✓ Target file exists and is accessible"
            if [ -s "${targetPath}" ]; then
              echo "✓ File has content: $(ls -l ${targetPath})"
              echo "First few lines of content:"
              head -n 3 "${targetPath}" || true
            else
              echo "✗ Warning: File is empty: ${targetPath}"
            fi
          else
            echo "✗ Error: Target file does not exist or is not accessible"
          fi
        else
          echo "✗ Error: Symlink does not exist: ${targetPath}"
        fi
      '';
    in
    {
      target = destination;
      source = resolvedSource;
      force = true;
      onChange = verifyScript;
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
  allFiles = homeManagerFiles // { 
    ".wallpaper" = { 
      source = wallpaperPath; 
      force = true;
      onChange = ''
        echo "Verifying wallpaper..."
        if [ -L "${homeDirectory}/.wallpaper" ] && [ -f "${homeDirectory}/.wallpaper" ]; then
          echo "✓ Wallpaper installed successfully"
          ls -l "${homeDirectory}/.wallpaper"
        else
          echo "✗ Wallpaper installation failed"
        fi
      '';
    }; 
  };

in
{
  # Install all files including wallpaper
  home.file = allFiles;
}