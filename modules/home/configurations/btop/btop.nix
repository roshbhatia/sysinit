{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  btopTheme = themes.getAppTheme "btop" values.theme.colorscheme values.theme.variant;
in
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "${values.theme.colorscheme}-${values.theme.variant}";
      vim_keys = true;
      force_tty = true;
      theme_background = false;
      shown_boxes = "cpu proc";
    };
    themes = {
      "${values.theme.colorscheme}-${values.theme.variant}" = btopTheme;
    };
  };
}
