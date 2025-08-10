{ lib }:

with lib;

rec {
  generateStylixConfig =
    _palette: semanticColors: themeConfig: fontConfig:
    let
      base16Scheme = {
        base00 = removePrefix "#" semanticColors.background.primary;
        base01 = removePrefix "#" semanticColors.background.secondary;
        base02 = removePrefix "#" semanticColors.background.tertiary;
        base03 = removePrefix "#" semanticColors.foreground.muted;
        base04 = removePrefix "#" semanticColors.foreground.secondary;
        base05 = removePrefix "#" semanticColors.foreground.primary;
        base06 = removePrefix "#" semanticColors.foreground.primary;
        base07 = removePrefix "#" semanticColors.foreground.primary;
        base08 = removePrefix "#" semanticColors.semantic.error;
        base09 = removePrefix "#" semanticColors.accent.secondary;
        base0A = removePrefix "#" semanticColors.semantic.warning;
        base0B = removePrefix "#" semanticColors.semantic.success;
        base0C = removePrefix "#" semanticColors.accent.tertiary;
        base0D = removePrefix "#" semanticColors.accent.primary;
        base0E = removePrefix "#" semanticColors.accent.quaternary;
        base0F = removePrefix "#" semanticColors.accent.secondary;
      };
    in
    {
      stylix = {
        enable = true;
        autoEnable = false;
        base16Scheme = base16Scheme;

        fonts = fontConfig;

        opacity = {
          terminal = if themeConfig.transparency.enable then themeConfig.transparency.opacity else 1.0;
        };
      };
    };

  generateBase16Scheme = _palette: semanticColors: {
    base00 = removePrefix "#" semanticColors.background.primary;
    base01 = removePrefix "#" semanticColors.background.secondary;
    base02 = removePrefix "#" semanticColors.background.tertiary;
    base03 = removePrefix "#" semanticColors.foreground.muted;
    base04 = removePrefix "#" semanticColors.foreground.secondary;
    base05 = removePrefix "#" semanticColors.foreground.primary;
    base06 = removePrefix "#" semanticColors.foreground.primary;
    base07 = removePrefix "#" semanticColors.foreground.primary;
    base08 = removePrefix "#" semanticColors.semantic.error;
    base09 = removePrefix "#" semanticColors.accent.secondary;
    base0A = removePrefix "#" semanticColors.semantic.warning;
    base0B = removePrefix "#" semanticColors.semantic.success;
    base0C = removePrefix "#" semanticColors.accent.tertiary;
    base0D = removePrefix "#" semanticColors.accent.primary;
    base0E = removePrefix "#" semanticColors.accent.quaternary;
    base0F = removePrefix "#" semanticColors.accent.secondary;
  };

  enableStylixTargets =
    targets:
    let
      targetConfig =
        target:
        if target == "firefox" then
          {
            enable = true;
            profileNames = [ "default" ];
          }
        else if target == "vscode" then
          {
            enable = true;
            profileNames = [ "default" ];
          }
        else
          {
            enable = true;
          };
    in
    {
      stylix.targets = genAttrs targets targetConfig;
    };
}
