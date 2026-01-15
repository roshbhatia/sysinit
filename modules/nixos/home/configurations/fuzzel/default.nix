{
  lib,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

  # Strip # from hex colors for fuzzel
  c = color: lib.removePrefix "#" color;

in
{
  # Disable Stylix's fuzzel theming - using custom theme colors
  stylix.targets.fuzzel.enable = false;

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${values.theme.font.monospace}:size=12";
        dpi-aware = "no";
        width = 35;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
        line-height = 22;
        layer = "overlay";
      };

      colors = {
        background = "${c semanticColors.background.primary}ee";
        text = "${c semanticColors.foreground.primary}ff";
        prompt = "${c semanticColors.accent.primary}ff";
        input = "${c semanticColors.foreground.primary}ff";
        match = "${c semanticColors.accent.primary}ff";
        selection = "${c semanticColors.background.secondary}ff";
        selection-text = "${c semanticColors.foreground.primary}ff";
        selection-match = "${c semanticColors.accent.primary}ff";
        border = "${c semanticColors.accent.primary}ff";
      };

      border = {
        width = 2;
        radius = 10;
      };
    };
  };
}
