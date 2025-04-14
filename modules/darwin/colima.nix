{ config, lib, pkgs, ... }:
{
  system.activationScripts.colima = {
    enable = true;
    text = ''
      # Set up Colima to respect XDG_CONFIG_HOME and match Homebrew service configuration
      COLIMA_SERVICE="/opt/homebrew/Cellar/colima/*/homebrew.colima.service"
      if [ -f $COLIMA_SERVICE ]; then
        echo "Configuring Colima service..."
        sed -i.bak '
          /^Environment="PATH=/c\
          Environment="PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin"\
          Environment="XDG_CONFIG_HOME=~/.config"\
          Environment="COLIMA_HOME=~/.config/colima"\
          Environment="HOME=$HOME"
          ' $COLIMA_SERVICE

        # Update service working directory and logs
        sed -i.bak '
          /^WorkingDirectory=/c\
          WorkingDirectory=$HOME\
          StandardOutput=append:/opt/homebrew/var/log/colima.log\
          StandardError=append:/opt/homebrew/var/log/colima.log
          ' $COLIMA_SERVICE

        # Ensure service starts immediately and stays alive
        sed -i.bak '
          /^Type=/c\
          Type=simple\
          Restart=on-success
          ' $COLIMA_SERVICE
      fi
      
      # Create required directories
      sudo mkdir -p /opt/homebrew/var/log
      sudo touch /opt/homebrew/var/log/colima.log
      sudo chown $USER /opt/homebrew/var/log/colima.log
      
      # Set up XDG config directory and Docker socket
      mkdir -p $HOME/.config/colima/default
      ln -sf $HOME/.config/colima/default/docker.sock /var/run/docker.sock
    '';
  };
}