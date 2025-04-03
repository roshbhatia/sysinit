{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."aerospace/aerospace-help" = {
    source = ./aerospace-help.sh;
    executable = true;
  };

  xdg.configFile."aerospace/smart-resize" = {
    source = ./smart-resize.sh;
    executable = true;
  };

  xdg.configFile."aerospace/update-display-cache" = {
    source = ./update-display-cache.sh;
    executable = true;
  };
  
  # Create aerospace data directory in activation script
  home.activation.aerospaceSetup = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Create aerospace data directory
      mkdir -p "$HOME/.local/share/aerospace"
      chmod 755 "$HOME/.local/share/aerospace"
      
      # Ensure we have the directory for last resize state
      echo "🚀 Aerospace configuration is ready"
    '';
  };
}