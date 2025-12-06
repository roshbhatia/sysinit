{
  lib,
  utils,
  ...
}:

with lib;

{
  /*
    Create Wezterm theme configuration.

    Uses the adapter base pattern:
    1. Define color mapping (semantic → wezterm config keys)
    2. Define config builder function
    3. Use adapterBase.createAdapter for common logic
  */
  createWeztermConfig =
    themeData: config: overrides:
    let
      transparency = config.transparency or (throw "Missing transparency configuration");

      themeName =
        if hasAttr "wezterm" themeData.appAdapters then
          if hasAttr config.variant themeData.appAdapters.wezterm then
            themeData.appAdapters.wezterm.${config.variant}
          else
            throw "Wezterm theme variant '${config.variant}' not found for theme '${themeData.meta.id}'"
        else
          "${themeData.meta.id}-${config.variant}";

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

      transparencyConfig =
        if (hasAttr "enable" transparency && transparency.enable) then
          {
            window_background_opacity =
              if hasAttr "opacity" transparency then
                transparency.opacity
              else
                throw "Missing opacity in transparency configuration";
            macos_window_background_blur =
              if hasAttr "blur" transparency then
                transparency.blur
              else
                throw "Missing blur in transparency configuration";
            window_decorations = "RESIZE";
          }
        else
          { };

      baseConfig = configBuilder (utils.createSemanticMapping (themeData.palettes.${config.variant})) { };
    in
    utils.mergeThemeConfigs baseConfig (transparencyConfig // overrides);

  /*
    Generate Wezterm JSON export.

    Exports theme configuration suitable for Wezterm setup scripts.
  */
  generateWeztermJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;

      themeName =
        if hasAttr "wezterm" themeData.appAdapters then
          if hasAttr config.variant themeData.appAdapters.wezterm then
            themeData.appAdapters.wezterm.${config.variant}
          else
            throw "Wezterm theme variant '${config.variant}' not found for theme '${themeData.meta.id}'"
        else
          "${themeData.meta.id}-${config.variant}";
    in
    {
      colorscheme = themeData.meta.id;
      inherit (config) variant;
      appearance = if hasAttr "appearance" config then config.appearance else null;
      font = if hasAttr "font" config then config.font else null;
      transparency = config.transparency or (throw "Missing transparency configuration");
      theme_name = themeName;
      palette = palette // {
        bg_primary = semanticColors.background.primary;
        bg_secondary = semanticColors.background.secondary;
        bg_tertiary = semanticColors.background.tertiary;
        bg_overlay = semanticColors.background.overlay;

        fg_primary = semanticColors.foreground.primary;
        fg_secondary = semanticColors.foreground.secondary;
        fg_muted = semanticColors.foreground.muted;
        fg_subtle = semanticColors.foreground.subtle;
        inherit (semanticColors.accent) primary secondary dim;
        inherit (semanticColors.semantic)
          success
          warning
          error
          info
          ;
      };
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
