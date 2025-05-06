{ config, lib, pkgs, ... }:

{
  programs.nushell = {
    enable = true;
    
    # Use the consolidated config file for both config and environment settings
    configFile.source = ./config.nu;
    
    # The env settings are now included in config.nu
    extraConfig = ''
      # We're now using a consolidated config file
    '';
  };
}