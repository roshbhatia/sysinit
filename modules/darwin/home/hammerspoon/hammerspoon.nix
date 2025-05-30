{
  lib,
  ...
}:

let
  activationUtils = import ../../../lib/activation/utils.nix { inherit lib; };
in
{
  xdg.configFile."hammerspoon/init.lua" = {
    source = ./init.lua;
    force = true;
  };

  home.activation.modifyHammerspoonConfigPath = activationUtils.mkActivationScript {
    description = "Modify Hammerspoon config path";
    requiredExecutables = [ "defaults" ];
    script = ''
      defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
    '';
  };
}

