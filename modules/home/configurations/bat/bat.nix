{
  lib,
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
      theme = batTheme;
    };
  };
}
