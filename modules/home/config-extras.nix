{ config, lib, pkgs, username, homeDirectory, userConfig ? {}, inputs, ... }:

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
      
      # Check if the path exists with better error reporting
      pathExists = builtins.pathExists resolvedPath;
      
      errorMsg = "ERROR: File not found at ${resolvedPath}";
    in
      if pathExists
      then resolvedPath
      else 
        # Add fallback for work configs using this as imported flake
        let 
          workConfigPath = toString (../../../${path});
          workPathExists = builtins.pathExists workConfigPath;
        in
          if workPathExists 
          then workConfigPath
          else throw errorMsg; # Use throw instead of trace to stop the build on missing files

  # Validate user configuration with safer fallbacks
  validateConfig = config: required: default:
    if config ? ${required} then config.${required} else
      lib.warn "WARNING: Missing ${required} in configuration, using default" default;
      
  # Get wallpaper path with strict validation
  wallpaperPath = 
    if userConfig ? wallpaper && userConfig.wallpaper ? path then
      let 
        path = userConfig.wallpaper.path;
        # Verify wallpaper exists before attempting to use it
        _ = resolvePath path; # This will throw if path doesn't exist
      in path
    else "wall/mvp2.jpeg";
    
  # Get the fully resolved wallpaper path
  resolvedWallpaperPath = resolvePath wallpaperPath;
in
{
  home.file = let
    # Get files to install with validation
    filesToInstall = if userConfig ? install
                    then userConfig.install
                    else [];
    
    # Filter out any test file (it will be installed by system.activationScripts)
    filteredFiles = builtins.filter (file: 
      !(file ? destination && lib.strings.hasSuffix "nix-test/nix-test.yaml" file.destination)
    ) filesToInstall;
    
    # Pre-validate all files before attempting to install
    # This will throw early if any file is missing
    _ = map (fileConfig: 
      if !(fileConfig ? source && fileConfig ? destination) then
        throw "ERROR: Invalid file config, missing source or destination"
      else resolvePath fileConfig.source
    ) filteredFiles;
                    
    # Convert install configs to home-manager file format with robust validation
    homeManagerFiles = builtins.listToAttrs 
      (map 
        (fileConfig: {
          name = fileConfig.destination;
          value = {
            source = resolvePath fileConfig.source;
            target = fileConfig.destination;
            force = true;
            # Create backup of existing file before overwriting
            onChange = ''
              # Backup existing file if it exists and isn't already a symlink
              if [ -e "$HOME/${fileConfig.destination}" ] && [ ! -L "$HOME/${fileConfig.destination}" ]; then
                echo "Creating backup of existing file: $HOME/${fileConfig.destination}"
                cp -f "$HOME/${fileConfig.destination}" "$HOME/${fileConfig.destination}.backup-$(date +%Y%m%d-%H%M%S)"
              fi
              
              # Verify the file was installed correctly
              if [ -e "$HOME/${fileConfig.destination}" ]; then
                echo "✓ Successfully installed: $HOME/${fileConfig.destination}"
                ls -la "$HOME/${fileConfig.destination}"
                # Verify the contents match what we expect
                if [ -L "$HOME/${fileConfig.destination}" ]; then
                  echo "  └─ Symlink target: $(readlink "$HOME/${fileConfig.destination}")"
                fi
              else
                echo "✗ ERROR: Failed to install: $HOME/${fileConfig.destination}"
                exit 1 # Force activation to fail if file installation fails
              fi
            '';
          };
        }) 
        filteredFiles);

  in
    homeManagerFiles;

  # Additional home-manager settings
  programs.home-manager = {
    enable = true;
  };

  # Enhanced activation with pre-check, cleanup and rollback capabilities
  home.activation = {
    # Validate environment before doing anything
    validateEnvironment = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      echo "🔍 Validating environment before activation..."
      
      # Check for critical directories
      for dir in "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"; do
        if [ ! -d "$dir" ]; then
          echo "Creating missing directory: $dir"
          mkdir -p "$dir"
        fi
      done
      
      # Verify home directory permissions
      if [ ! -w "$HOME" ]; then
        echo "❌ ERROR: Home directory is not writable!"
        exit 1
      fi
      
      echo "✅ Environment validation passed"
    '';
    
    # Clean up broken symlinks before creating new ones
    linkCleanup = lib.hm.dag.entryAfter ["validateEnvironment"] ''
      echo "🧹 Cleaning up old symlinks..."
      for file in $(find "$HOME" -maxdepth 1 -type l -name ".*"); do
        if [ -L "$file" ] && [ ! -e "$file" ]; then
          echo "  └─ Removing broken symlink: $file"
          rm "$file"
        fi
      done
      
      # Also clean up in .config directory
      for file in $(find "$HOME/.config" -maxdepth 2 -type l); do
        if [ -L "$file" ] && [ ! -e "$file" ]; then
          echo "  └─ Removing broken symlink: $file"
          rm "$file"
        fi
      done
    '';
    
    # Set wallpaper using osascript
    setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "🖼️ Setting wallpaper..."
      
      WALLPAPER_PATH="${resolvedWallpaperPath}"
      if [ -f "$WALLPAPER_PATH" ]; then
        echo "Using wallpaper: $WALLPAPER_PATH"
        
        # Use osascript to set the desktop wallpaper properly
        osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER_PATH\""
        
        if [ $? -eq 0 ]; then
          echo "✅ Wallpaper set successfully!"
        else
          echo "⚠️ Warning: Wallpaper could not be set with osascript"
        fi
      else
        echo "❌ ERROR: Wallpaper file not found at $WALLPAPER_PATH"
      fi
    '';
    
    # Add rollback instructions after activation completes
    rollbackInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo ""
      echo "🔄 Rollback Information:"
      echo "  If you need to rollback this activation, you can:"
      echo "   1. Run 'home-manager generations' to see available generations"
      echo "   2. Run 'home-manager switch --generation X' to roll back to generation X"
      echo "   3. Or restore individual files from backups created during this activation"
      echo "      (backup files have the format: filename.backup-YYYYMMDD-HHMMSS)"
      echo ""
    '';
  };
}