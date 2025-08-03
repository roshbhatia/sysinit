{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  # Create Wezterm configuration from theme
  createWeztermConfig =
    themeData: config: overrides:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      transparency = config.transparency or { };

      # Get app-specific theme name
      themeName =
        if hasAttr "wezterm" themeData.appAdapters then
          themeData.appAdapters.wezterm.${config.variant} or "${themeData.meta.id}-${config.variant}"
        else
          "${themeData.meta.id}-${config.variant}";

      # Base configuration
      baseConfig = {
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
            semanticColors.background.primary # black
            semanticColors.semantic.error # red
            semanticColors.semantic.success # green
            semanticColors.semantic.warning # yellow
            semanticColors.semantic.info # blue
            semanticColors.syntax.keyword # magenta
            semanticColors.syntax.operator # cyan
            semanticColors.foreground.primary # white
          ];

          brights = [
            semanticColors.foreground.muted # bright black
            semanticColors.semantic.error # bright red
            semanticColors.semantic.success # bright green
            semanticColors.semantic.warning # bright yellow
            semanticColors.semantic.info # bright blue
            semanticColors.syntax.keyword # bright magenta
            semanticColors.syntax.operator # bright cyan
            semanticColors.foreground.primary # bright white
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

      # Add transparency settings if enabled
      transparencyConfig =
        if transparency.enable or false then
          {
            window_background_opacity = transparency.opacity or 0.85;
            macos_window_background_blur = transparency.blur or 80;
            window_decorations = "RESIZE";
          }
        else
          { };

    in
    utils.mergeThemeConfigs baseConfig (transparencyConfig // overrides);

  # Generate JSON config for Wezterm Lua integration
  generateWeztermJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      weztermConfig = createWeztermConfig themeData config { };
    in
    {
      colorscheme = themeData.meta.id;
      variant = config.variant;
      transparency = config.transparency or { };
      theme_name = weztermConfig.color_scheme;
      palette = palette // {
        # Add semantic aliases for Lua access
        inherit (semanticColors.background)
          primary
          secondary
          tertiary
          overlay
          ;
        inherit (semanticColors.foreground)
          primary
          secondary
          muted
          subtle
          ;
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
