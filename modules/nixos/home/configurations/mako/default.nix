{
  lib,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;

in
{
  # Disable Stylix's mako theming - using custom theme colors
  stylix.targets.mako.enable = false;

  services.mako = {
    enable = true;
    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = semanticColors.background.primary;
      text-color = semanticColors.foreground.primary;
      border-color = semanticColors.accent.primary;
      border-size = 2;
      border-radius = 10;
      padding = "15";
      margin = "10";
      width = 350;
      height = 100;
      default-timeout = 5000;
      layer = "overlay";

      "[urgency=low]" = {
        border-color = semanticColors.foreground.muted;
      };

      "[urgency=high]" = {
        border-color = semanticColors.semantic.error;
        default-timeout = 0;
      };
    };
  };
}
