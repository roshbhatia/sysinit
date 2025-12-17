{
  lib,
  ...
}:

{
  createNiriTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      niriColors = {
        activeBorder = semanticColors.accent.primary;
        inactiveBorder = semanticColors.foreground.muted;
        shadowColor = semanticColors.background.primary;
        background = semanticColors.background.primary;
        foreground = semanticColors.foreground.primary;
        accent = semanticColors.accent.primary;
        inherit (semanticColors.semantic) success;
        inherit (semanticColors.semantic) warning;
        inherit (semanticColors.semantic) error;
        inherit (semanticColors.semantic) info;
      };

      # Convert hex color to rgba format for niri

      # Format color for niri (return as-is for niri's format)
      formatNiriColor = color: color;
    in
    {
      niriColors = niriColors // {
        # Pre-formatted for niri's color format
        activeBorderFormatted = formatNiriColor niriColors.activeBorder;
        inactiveBorderFormatted = formatNiriColor niriColors.inactiveBorder;
        shadowColorFormatted = formatNiriColor niriColors.shadowColor;
      };
    };
}
