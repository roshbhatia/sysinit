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
  programs.wofi = {
    enable = true;

    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 24;
      gtk_dark = values.theme.appearance == "dark";
      layers = "overlay";
    };

    style = ''
      * {
        font-family: "${values.theme.font.monospace}", monospace;
        font-size: 14px;
      }

      window {
        background-color: ${semanticColors.background.primary};
        border: 2px solid ${semanticColors.accent.primary};
        border-radius: 12px;
      }

      #input {
        margin: 12px;
        padding: 12px;
        border: none;
        border-radius: 8px;
        background-color: ${semanticColors.background.secondary};
        color: ${semanticColors.foreground.primary};
      }

      #input:focus {
        border: 2px solid ${semanticColors.accent.primary};
      }

      #inner-box {
        margin: 0 12px 12px 12px;
      }

      #outer-box {
        margin: 0;
        padding: 0;
      }

      #scroll {
        margin: 0;
      }

      #entry {
        padding: 8px 12px;
        border-radius: 8px;
      }

      #entry:selected {
        background-color: ${semanticColors.accent.primary};
        color: ${semanticColors.background.primary};
      }

      #text {
        color: ${semanticColors.foreground.primary};
      }

      #entry:selected #text {
        color: ${semanticColors.background.primary};
      }
    '';
  };
}
