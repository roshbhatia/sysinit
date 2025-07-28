{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;
    configFile.text = builtins.readFile ./config.nu;
    envFile.text = builtins.readFile ./env.nu;
  };

  # Deploy loglib.nu and scripts/ to ~/.config/nushell/
  xdg.configFile."nushell/loglib.nu".source = ./loglib.nu;
  xdg.configFile."nushell/scripts".source = ./scripts;
}
