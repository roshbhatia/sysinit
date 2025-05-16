{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.nushell = {
    enable = true;

    # Use the consolidated config file for both config and environment settings
    configFile.source = ./config.nu;
  };
}

