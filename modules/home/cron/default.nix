{ config, lib, pkgs, ... }:

{
  config.home.file.".cron/aerospace-display-cache" = {
    text = ''
      */5 * * * * ${config.xdg.configHome}/aerospace/update-display-cache
    '';
    onChange = ''
      if [ -f ~/.cron/aerospace-display-cache ]; then
        crontab ~/.cron/aerospace-display-cache
      fi
    '';
  };
}