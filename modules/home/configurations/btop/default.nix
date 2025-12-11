{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = values.theme;
  btopTheme = themes.getAppTheme "btop" validatedTheme.colorscheme validatedTheme.variant;
in
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "${validatedTheme.colorscheme}-${validatedTheme.variant}";
      vim_keys = true;
      force_tty = true;
      theme_background = false;
      shown_boxes = "cpu proc";
    };
    themes = {
      "${validatedTheme.colorscheme}-${validatedTheme.variant}" = btopTheme;
    };
  };
}
