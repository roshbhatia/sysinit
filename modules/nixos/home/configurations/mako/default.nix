{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;
in
{
  services.mako = {
    enable = true;

    settings = {
      font = "${values.theme.font.monospace} 11";
      background-color = semanticColors.background.primary;
      text-color = semanticColors.foreground.primary;
      border-color = semanticColors.accent.primary;
      border-radius = 8;
      border-size = 2;
      padding = "12";
      margin = "12";
      width = 350;
      max-visible = 5;
      default-timeout = 5000;

      "urgency=low" = {
        border-color = semanticColors.foreground.muted;
      };

      "urgency=high" = {
        border-color = semanticColors.semantic.error;
        default-timeout = 0;
      };

      "urgency=critical" = {
        border-color = semanticColors.semantic.error;
        default-timeout = 0;
      };
    };
  };
}
