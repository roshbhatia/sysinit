{
}:

{
  /*
    Create Atuin theme configuration.

    Atuin is a shell history management tool. This adapter generates theme
    configurations dynamically from semantic colors, producing TOML-formatted
    theme files that map semantic colors to Atuin's color names.
  */

  createAtuinTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      # Map semantic colors to Atuin color names
      atuinColors = {
        # Base colors
        base = semanticColors.foreground.primary;
        mantle = semanticColors.background.secondary;
        surface = semanticColors.background.tertiary;
        base_alt = semanticColors.background.overlay;

        # Status/semantic colors
        info = semanticColors.semantic.info;
        warning = semanticColors.semantic.warning;
        error = semanticColors.semantic.error;
        success = semanticColors.semantic.success;

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

      # Generate Atuin TOML theme
      generateAtuinToml = themeId: ''
        [theme]
        name = "${themeId}"

        [colors]
        # Base colors
        AlertInfo = "${atuinColors.info}"
        AlertWarn = "${atuinColors.warning}"
        AlertError = "${atuinColors.error}"
        Annotation = "${atuinColors.accent}"
        Base = "${atuinColors.text_primary}"
        Guidance = "${atuinColors.text_muted}"
        Important = "${atuinColors.accent}"
        Title = "${atuinColors.accent}"

        # Status colors
        Success = "${atuinColors.success}"
        Warning = "${atuinColors.warning}"
        Error = "${atuinColors.error}"
        Info = "${atuinColors.info}"

        # UI elements
        Accent = "${atuinColors.accent}"
        AccentSecondary = "${atuinColors.accent_secondary}"

        # Text variants
        TextPrimary = "${atuinColors.text_primary}"
        TextSecondary = "${atuinColors.text_secondary}"
        TextMuted = "${atuinColors.text_muted}"

        # Background
        Background = "${atuinColors.background}"
        BackgroundAlt = "${atuinColors.base_alt}"

        # Mantle (secondary background)
        Mantle = "${atuinColors.mantle}"
        Surface = "${atuinColors.surface}"
      '';
    in
    {
      atuinThemeName = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      atuinToml = generateAtuinToml "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit atuinColors;
    };
}
