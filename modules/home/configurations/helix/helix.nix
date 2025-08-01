{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  helixTheme = themes.getAppTheme "helix" values.theme.colorscheme values.theme.variant;
in
{
  programs.helix = {
    enable = true;
    settings = {
      theme = helixTheme;

      editor = {
        line-number = "relative";

        cursor-shape = {
          insert = "bar";
          select = "underline";
        };

        file-picker = {
          hidden = false;
        };
      };
    };
  };
}
