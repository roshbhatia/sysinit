{ config, lib, pkgs, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
  };

  xdg.configFile."aerospace/aerospace-help" = {
    source = ./aerospace-help.sh;
  };

  xdg.configFile."aerospace/smart-resize" = {
    source = ./smart-resize.sh;
  };

  xdg.configFile."aerospace/update-display-cache" = {
    source = ./update-display-cache.sh;
  };
  
  # Register aerospace display cache update in activation script
  home.activation.aerospaceCron = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      # Create cron directory if needed
      mkdir -p $HOME/.cron
      
      # Create aerospace cron file
      echo "*/5 * * * * $HOME/.config/aerospace/update-display-cache" > $HOME/.cron/aerospace-display-cache
      
      # Apply crontab if file exists
      if [ -f $HOME/.cron/aerospace-display-cache ]; then
        echo "📋 Installing aerospace display cache cron job..."
        crontab $HOME/.cron/aerospace-display-cache
        
        # Run update-display-cache once to ensure we have fresh display data
        $HOME/.config/aerospace/update-display-cache
        
        # Verify crontab installation
        if crontab -l | grep -q "update-display-cache"; then
          echo "✅ Aerospace cron job installed successfully"
        else
          echo "❌ Failed to install aerospace cron job"
        fi
      fi
    '';
  };
}