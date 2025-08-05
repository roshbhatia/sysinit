{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;
  activeColor = lib.toLower (lib.removePrefix "#" (colors.accent.primary or "ffdc8a78"));
  inactiveColor = lib.toLower (lib.removePrefix "#" (colors.background.overlay or "ffbabbf1"));
  bordersrc = ''
    style=round
    width=5.0
    hidpi=on
    active_color=0x${activeColor}
    inactive_color=0x${inactiveColor}
  '';
in
{
  xdg.configFile."borders/bordersrc" = {
    text = bordersrc;
    force = true;
  };

  home.activation.bordersService = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! brew services restart borders; then
      brew services start borders
    fi
  '';
}

