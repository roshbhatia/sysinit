{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  batTheme = themes.getAppTheme "bat" values.theme.colorscheme values.theme.variant;
in
{
  xdg.configFile."bat/config".text = ''
    --theme="${batTheme}"
  '';

  xdg.configFile."bat/themes/${batTheme}.tmTheme".source = ./${batTheme}.tmTheme;

  home.activation.buildBatCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v bat >/dev/null 2>&1; then
      echo "Building bat cache..."
      bat cache --build || echo "Warning: Failed to build bat cache"
      echo "Completed bat cache build"
    else
      echo "Warning: bat not available, skipping cache build"
    fi
  '';
}

