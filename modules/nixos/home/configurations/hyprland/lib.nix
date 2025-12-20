_:

{
  createHyprlandTheme =
    theme: themeConfig:
    let
      palette = theme.palettes.${themeConfig.variant};
      semanticColors = theme.semanticMapping palette;

      # Extract colors for hyprland (using semantic colors)
      hyprlandColors = {
        activeBorder = semanticColors.accent.primary;
        inactiveBorder = semanticColors.background.secondary;
        shadowColor = semanticColors.background.tertiary;
      };
    in
    {
      inherit hyprlandColors;
    };
}
