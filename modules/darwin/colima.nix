{ config, lib, pkgs, ... }:
{
  # Add the Colima service configuration to activationScripts
  system.activationScripts.colima = {
    enable = true;
    text = ''
      # Set up Colima to respect XDG_CONFIG_HOME
      COLIMA_SERVICE="/opt/homebrew/Cellar/colima/*/homebrew.colima.service"
      if [ -f $COLIMA_SERVICE ]; then
        echo "Configuring Colima service to respect XDG_CONFIG_HOME..."
        sed -i.bak '/^Environment="PATH=/a\\Environment="XDG_CONFIG_HOME=~/.config"\n\\Environment="COLIMA_HOME=~/.config/colima/.colima"' $COLIMA_SERVICE
      fi
      
      # Create symlink for Colima Docker socket
      mkdir -p $HOME/.docker
      if [ -S $HOME/.config/colima/default/docker.sock ]; then
        ln -sf $HOME/.config/colima/default/docker.sock $HOME/.docker/docker.sock
      fi
    '';
  };
}