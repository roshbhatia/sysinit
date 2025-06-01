{
  lib,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  xdg.configFile."borders/bordersrc" = {
    source = ./bordersrc.sh;
    force = true;
  };

  home.activation.startBordersService = activation.mkActivationScript {
    description = "Start borders service";
    requiredExecutables = [ "brew" ];
    script = ''
      brew services start borders
      log_command "brew services restart borders" "Starting borders service"
    '';
  };
}

