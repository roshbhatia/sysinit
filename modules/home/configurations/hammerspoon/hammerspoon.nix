{
  lib,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  xdg.configFile."hammerspoon/init.lua" = {
    source = ./init.lua;
    force = true;
  };

  home.activation.modifyHammerspoonConfigPath = activation.mkActivationScript {
    description = "Modify Hammerspoon config path";
    requiredExecutables = [ "defaults" ];
    script = ''
      log_command "defaults write org.hammerspoon.Hammerspoon MJConfigFile '~/.config/hammerspoon/init.lua'" "Setting Hammerspoon config path"
    '';
  };
}
