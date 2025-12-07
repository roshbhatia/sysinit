{
  lib,
  ...
}:

{
  createHyprlandTheme =
    theme: validatedConfig:
    let
      palette = theme.palettes.${validatedConfig.variant};
      semanticColors = theme.semanticMapping palette;

      hyprlandColors = {
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

      # Convert hex color to rgba format (hyprland expects rrggbbaa format)
      # This function takes a hex color and optional alpha value
      rgbaColor =
        color: alpha:
        let
          # Remove # if present
          cleanColor =
            if lib.hasPrefix "#" color then lib.substring 1 (lib.stringLength color - 1) color else color;
          # Convert alpha float (0-1) to hex byte (00-ff)
          alphaHex =
            let
              alphaByte = builtins.floor (alpha * 255);
              hexByte = lib.toHexString alphaByte;
            in
            lib.fixedWidthString 2 "0" hexByte;
        in
        "${cleanColor}${alphaHex}";

      # Format color for hyprland (add ee for full opacity if not specified)
      formatHyprlandColor = color: "${color}ee";
    in
    {
      hyprlandColors = hyprlandColors // {
        # Pre-formatted for hyprland's col. format (rgba with alpha)
        activeBorderFormatted = formatHyprlandColor hyprlandColors.activeBorder;
        inactiveBorderFormatted = formatHyprlandColor hyprlandColors.inactiveBorder;
        shadowColorFormatted = formatHyprlandColor hyprlandColors.shadowColor;
      };

      # Return raw hex colors for use in Nix expressions
      inherit hyprlandColors;
    };
}
