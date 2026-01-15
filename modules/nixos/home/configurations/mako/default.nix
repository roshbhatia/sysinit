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
  services.mako = {
    enable = true;
    font = "${values.theme.font.monospace} 11";
    backgroundColor = semanticColors.background.primary;
    textColor = semanticColors.foreground.primary;
    borderColor = semanticColors.accent.primary;
    borderSize = 2;
    borderRadius = 10;
    padding = "15";
    margin = "10";
    width = 350;
    height = 100;
    defaultTimeout = 5000;
    layer = "overlay";

    extraConfig = ''
      [urgency=low]
      border-color=${semanticColors.foreground.muted}

      [urgency=normal]
      border-color=${semanticColors.accent.primary}

      [urgency=high]
      border-color=${semanticColors.semantic.error}
      default-timeout=0
    '';
  };
}
