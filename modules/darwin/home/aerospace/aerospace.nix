{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."aerospace/smart-resize" = {
    source = ./smart-resize.sh;
    executable = true;
  };

  xdg.configFile."aerospace/update-display-cache" = {
    source = ./update-display-cache.sh;
    executable = true;
  };
  
  home.activation.aerospaceSetup = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      echo "Setting permissions for Aerospace directories..."
      mkdir -p $HOME/.local/share/aerospace
      chmod 755 $HOME/.local/share/aerospace
    '';
  };
}