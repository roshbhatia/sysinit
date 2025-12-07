{
  config,
  lib,
  values,
  ...
}:
with lib;
let
  cfg = config.programs.btop;
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  btopTheme = themes.getAppTheme "btop" validatedTheme.colorscheme validatedTheme.variant;
in
{
  config = mkIf cfg.enable {
    programs.btop = {
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
  };
}
