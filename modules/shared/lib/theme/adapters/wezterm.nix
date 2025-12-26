{
  lib,
  utils,
  ...
}:

with lib;

let
  themeNames = import ./theme-names.nix { inherit lib; };
in

{
  createWeztermConfig =
    themeData: config: overrides:
    let
      transparency = config.transparency or (throw "Missing transparency configuration");

      themeName = themeNames.getWeztermTheme themeData.meta.id config.variant;

      configBuilder = semanticColors: _mapping: {
        color_scheme = themeName;

        colors = {
          foreground = semanticColors.foreground.primary;
          background = semanticColors.background.primary;
          cursor_bg = semanticColors.accent.primary;
          cursor_fg = semanticColors.background.primary;
          cursor_border = semanticColors.accent.primary;
          selection_fg = semanticColors.background.primary;
          selection_bg = semanticColors.accent.primary;
          scrollbar_thumb = semanticColors.background.overlay;
          split = semanticColors.background.overlay;

          ansi = [
            semanticColors.background.primary
            semanticColors.semantic.error
            semanticColors.semantic.success
            semanticColors.semantic.warning
            semanticColors.semantic.info
            semanticColors.syntax.keyword
            semanticColors.syntax.operator
            semanticColors.foreground.primary
          ];

          brights = [
            semanticColors.foreground.muted
            semanticColors.semantic.error
            semanticColors.semantic.success
            semanticColors.semantic.warning
            semanticColors.semantic.info
            semanticColors.syntax.keyword
            semanticColors.syntax.operator
            semanticColors.foreground.primary
          ];

          tab_bar = {
            background = semanticColors.background.primary;
            active_tab = {
              bg_color = semanticColors.accent.primary;
              fg_color = semanticColors.background.primary;
            };
            inactive_tab = {
              bg_color = semanticColors.background.secondary;
              fg_color = semanticColors.foreground.muted;
            };
            inactive_tab_hover = {
              bg_color = semanticColors.background.tertiary;
              fg_color = semanticColors.foreground.primary;
            };
            new_tab = {
              bg_color = semanticColors.background.secondary;
              fg_color = semanticColors.foreground.muted;
            };
            new_tab_hover = {
              bg_color = semanticColors.background.tertiary;
              fg_color = semanticColors.foreground.primary;
            };
          };
        };
      };

      transparencyConfig = {
        command_palette_bg_color = semanticColors.background.primary;
        macos_window_background_blur = if hasAttr "blur" transparency then transparency.blur else 0;
        window_background_opacity = if hasAttr "opacity" transparency then transparency.opacity else 1.0;
        window_decorations = "MACOS_FORCE_ENABLE_SHADOW|RESIZE";
      };

      baseConfig = configBuilder (utils.createSemanticMapping themeData.palettes.${config.variant}) { };
    in
    utils.mergeThemeConfigs baseConfig (transparencyConfig // overrides);

  generateWeztermJSON =
    themeData: config:
    let
      semanticColors = utils.createSemanticMapping themeData.palettes.${config.variant};
      themeName = themeNames.getWeztermTheme themeData.meta.id config.variant;
    in
    {
      inherit (config) variant;
      transparency = config.transparency or (throw "Missing transparency configuration");
      theme_name = themeName;
      inherit semanticColors;
    };
}
