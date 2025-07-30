{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
  themes = import ../../../lib/themes { inherit lib; };
  batTheme = themes.getAppTheme "bat" values.theme.colorscheme values.theme.variant;
in
{
  xdg.configFile."bat/config".text = ''
    --theme="${batTheme}"
  '';

  xdg.configFile."bat/themes/${batTheme}.tmTheme".source = ./${batTheme}.tmTheme;

  home.activation.buildBatCache = activation.mkActivationScript {
    description = "Build bat cache";
    requiredExecutables = [ "bat" ];
    script = ''
      log_command "bat cache --build" "Building bat cache"
    '';
  };
}

