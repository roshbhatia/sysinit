{
  lib,
  values,
  config,
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
      color_theme = "${config.sysinit.theme.colorscheme}-${config.sysinit.theme.variant}";
      vim_keys = true;
    };
    themes = {
      "${config.sysinit.theme.colorscheme}-${config.sysinit.theme.variant}" = btopTheme;
    };
  };
}
