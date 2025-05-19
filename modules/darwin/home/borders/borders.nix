{
  lib,
  ...
}:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in
{
  xdg.configFile."borders/bordersrc" = {
    source = ./bordersrc;
    force = true;
  };

  home.activation.startBordersService = activationUtils.mkActivationScript {
    description = "Start borders service";
    requiredExecutables = [ "brew" ];
    script = ''
      brew services start borders
      log_command "brew services restart borders" "Starting borders service"
    '';
  };
}
