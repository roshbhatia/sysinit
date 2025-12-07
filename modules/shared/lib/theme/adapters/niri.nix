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
        success = semanticColors.semantic.success;
        warning = semanticColors.semantic.warning;
        error = semanticColors.semantic.error;
        info = semanticColors.semantic.info;
      };

      # Convert hex color to rgba format for niri
      rgbaColor =
        color: alpha:
        let
          # Remove # if present
          cleanColor =
            if lib.hasPrefix "#" color then lib.substring 1 (lib.stringLength color - 1) color else color;
          # Convert alpha float (0-1) to decimal (0.0-1.0)
          alphaDecimal = alpha;
        in
        "rgba(0x${cleanColor}${
          lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (alphaDecimal * 255)))
        })";

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
