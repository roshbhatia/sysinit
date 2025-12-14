{
  lib,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  semanticColors = themes.getSemanticColors values.theme.colorscheme values.theme.variant;
in
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        font = "${values.theme.font.monospace}:size=11";
        dpi-aware = "yes";
        pad = "12x12";
      };

      scrollback = {
        lines = 10000;
      };

      cursor = {
        style = "beam";
        blink = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      colors = {
        foreground = lib.removePrefix "#" semanticColors.foreground.primary;
        background = lib.removePrefix "#" semanticColors.background.primary;

        regular0 = lib.removePrefix "#" (palette.black or "000000");
        regular1 = lib.removePrefix "#" (palette.red or semanticColors.semantic.error);
        regular2 = lib.removePrefix "#" (palette.green or semanticColors.semantic.success);
        regular3 = lib.removePrefix "#" (palette.yellow or semanticColors.semantic.warning);
        regular4 = lib.removePrefix "#" (palette.blue or semanticColors.accent.primary);
        regular5 = lib.removePrefix "#" (
          palette.magenta or palette.pink or semanticColors.accent.secondary
        );
        regular6 = lib.removePrefix "#" (palette.cyan or palette.teal or semanticColors.semantic.info);
        regular7 = lib.removePrefix "#" (palette.white or semanticColors.foreground.primary);

        bright0 = lib.removePrefix "#" (palette.brightBlack or palette.surface1 or "555555");
        bright1 = lib.removePrefix "#" (palette.brightRed or palette.red or semanticColors.semantic.error);
        bright2 = lib.removePrefix "#" (
          palette.brightGreen or palette.green or semanticColors.semantic.success
        );
        bright3 = lib.removePrefix "#" (
          palette.brightYellow or palette.yellow or semanticColors.semantic.warning
        );
        bright4 = lib.removePrefix "#" (
          palette.brightBlue or palette.blue or semanticColors.accent.primary
        );
        bright5 = lib.removePrefix "#" (
          palette.brightMagenta or palette.pink or semanticColors.accent.secondary
        );
        bright6 = lib.removePrefix "#" (palette.brightCyan or palette.teal or semanticColors.semantic.info);
        bright7 = lib.removePrefix "#" (
          palette.brightWhite or palette.text or semanticColors.foreground.primary
        );
      };
    };
  };
}
