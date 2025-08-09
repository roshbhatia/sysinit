{
  lib,
  pkgs,
  config,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  batTheme = themes.getAppTheme "bat" values.theme.colorscheme values.theme.variant;
in
{
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      pager = "less -FR";
    };
  };

  # Deploy custom bat theme and rebuild cache
  xdg.configFile."bat/config".text = ''
    --theme="${batTheme}"
    --style=numbers,changes,header
    --pager="less -FR"
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
