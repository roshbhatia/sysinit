_:

{
  createAtuinTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      atuinColors = {
        # Base colors
        base = semanticColors.foreground.primary;
        mantle = semanticColors.background.secondary;
        surface = semanticColors.background.tertiary;
        base_alt = semanticColors.background.overlay;

        # Status/semantic colors
        inherit (semanticColors.semantic) info;
        inherit (semanticColors.semantic) warning;
        inherit (semanticColors.semantic) error;
        inherit (semanticColors.semantic) success;

        # UI colors
        accent = semanticColors.accent.primary;
        accent_secondary = semanticColors.accent.secondary;

        # Text colors
        text_primary = semanticColors.foreground.primary;
        text_secondary = semanticColors.foreground.secondary;
        text_muted = semanticColors.foreground.muted;

        # Background shades
        background = semanticColors.background.primary;
      };

      generateAtuinToml = themeId: ''
        [theme]
        name = "${themeId}"

        [colors]
        AlertInfo = "${atuinColors.info}"
        AlertWarn = "${atuinColors.warning}"
        AlertError = "${atuinColors.error}"
        Annotation = "${atuinColors.text_secondary}"
        Base = "${atuinColors.text_primary}"
        Guidance = "${atuinColors.text_muted}"
        Important = "${atuinColors.accent}"
        Title = "${atuinColors.accent_secondary}"
      '';
    in
    {
      atuinThemeName = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      atuinToml = generateAtuinToml "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit atuinColors;
    };
}
