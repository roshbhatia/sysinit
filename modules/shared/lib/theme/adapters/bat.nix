{
  lib,
}:

with lib;

{
  /*
    Create Bat theme configuration.

    Bat is a cat clone with syntax highlighting. This adapter generates theme
    configurations dynamically from semantic colors, mapping them to bat's
    color requirements.

    Bat supports TextMate (.tmTheme) format, but we can also generate simpler
    configs that reference theme names known to bat's internal themes.
  */

  createBatTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      # Determine which bat theme to use
      # Try to map our theme to bat's built-in themes
      batThemeName =
        if hasAttr "bat" theme.appAdapters then
          if isFunction theme.appAdapters.bat then
            theme.appAdapters.bat validatedConfig.variant
          else if isAttrs theme.appAdapters.bat then
            if hasAttr validatedConfig.variant theme.appAdapters.bat then
              theme.appAdapters.bat.${validatedConfig.variant}
            else
              "${validatedConfig.colorscheme}-${validatedConfig.variant}"
          else
            theme.appAdapters.bat
        else
          "${validatedConfig.colorscheme}-${validatedConfig.variant}";

      # Bat colors mapping
      batColors = {
        background = semanticColors.background.primary;
        foreground = semanticColors.foreground.primary;

        # Syntax highlighting colors
        keyword = semanticColors.syntax.keyword;
        operator = semanticColors.syntax.operator;
        string = semanticColors.syntax.string;
        comment = semanticColors.foreground.muted;
        number = semanticColors.semantic.warning;

        # UI colors
        line_number = semanticColors.foreground.muted;
        cursor_line_background = semanticColors.background.secondary;
      };

      # Generate a simple bat config format (uses theme name + semantic colors as fallback)
      generateBatConfig = themeId: ''
        # Bat theme configuration for ${themeId}
        # Generated from theme system semantic colors
        [theme]
        colorscheme = "${batThemeName}"
        background = "${batColors.background}"
        foreground = "${batColors.foreground}"

        [syntax]
        keyword = "${batColors.keyword}"
        operator = "${batColors.operator}"
        string = "${batColors.string}"
        comment = "${batColors.comment}"
        number = "${batColors.number}"

        [ui]
        line_number = "${batColors.line_number}"
        cursor_line_background = "${batColors.cursor_line_background}"
      '';
    in
    {
      batThemeName = batThemeName;
      batConfig = generateBatConfig "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit batColors;
    };
}
