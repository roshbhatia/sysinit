{ config, lib, pkgs, ... }:

{
  programs.nushell = {
    enable = true;
    
    configFile.source = ./config.nu;
    envFile.source = ./env.nu;

    extraConfig = ''
      # Load devenv hook if it exists
      if ($env | columns | any { |it| $it == "DEVENV_NIX_SHELL" }) {
        print "Already in a devenv.nix.shell environment"
      }
    '';
  };

  # Create devenv.pre.nu file for direnv-like functionality
  xdg.configFile = {
    "nushell/devenv.pre.nu".source = ./devenv.pre.nu;
  };
}