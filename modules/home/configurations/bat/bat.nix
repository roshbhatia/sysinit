{
  lib,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  xdg.configFile."bat/config" = {
    source = ./config;
    force = true;
  };

  xdg.configFile."bat/themes/Catppuccin-Frappe.tmTheme" = {
    source = ./Catppuccin-Frappe.tmTheme;
    force = true;
  };

  home.activation.buildBatCache = activation.mkActivationScript {
    description = "Build bat cache";
    requiredExecutables = [ "bat" ];
    script = ''
      log_command "bat cache --build" "Building bat cache"
    '';
  };
}

