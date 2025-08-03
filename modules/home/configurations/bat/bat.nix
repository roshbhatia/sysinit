{
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  batTheme = themes.getAppTheme "bat" values.theme.colorscheme values.theme.variant;
in
{
  xdg.configFile."bat/config".text = ''
    --theme="${batTheme}"
  '';

  xdg.configFile."bat/themes/${batTheme}.tmTheme".source = ./themes/${batTheme}.tmTheme;

  home.activation.buildBatCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "${pkgs.bat}/bin/bat" ]; then
      echo "Building bat cache..."
      "${pkgs.bat}/bin/bat" cache --build || echo "Warning: Failed to build bat cache"
      echo "Completed bat cache build"
    else
      echo "Warning: bat not available at ${pkgs.bat}/bin/bat, skipping cache build"
    fi
  '';
}
