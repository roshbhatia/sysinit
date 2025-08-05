{ config, lib, pkgs, values, ... }:

let
  themes = import ../../../lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  colors = themes.getUnifiedColors palette;
  # Choose theme colors for borders
  activeColor = colors.accent.primary or "0xffdc8a78";
  inactiveColor = colors.background.overlay or "0xffbabbf1";
  bordersrc = ''
    style=round
    width=5.0
    hidpi=on
    active_color=${activeColor}
    inactive_color=${inactiveColor}
  '';
in {
  xdg.configFile."borders/bordersrc" = {
    text = bordersrc;
    force = true;
  };
}
