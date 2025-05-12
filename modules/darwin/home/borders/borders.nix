{ config, lib, pkgs, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  xdg.configFile."borders/bordersrc" = {
    source = ./bordersrc;
    force = true;
  };

  home.activation.startBordersService = activationUtils.mkActivationScript {
    description = "Start borders service";
    requiredExecutables = [ "brew" ];
    script = ''
      log_command "brew services start borders" "Starting borders service"
    '';
  };
}
