{
  lib,
  utils,
  ...
}:

with lib;

{
  /*
    Create Neovim theme configuration.

    Uses the adapter base pattern to reduce boilerplate:
    1. Define color mapping (semantic colors → neovim config keys)
    2. Define config builder function
    3. Use adapterBase.createAdapter for common logic
  */
  createNeovimConfig =
    themeData: config: overrides:
    let

      pluginInfo =
        themeData.appAdapters.neovim or {
          plugin = "${themeData.meta.id}/${themeData.meta.id}.nvim";
          name = themeData.meta.id;
          setup = themeData.meta.id;
          colorscheme = variant: "${themeData.meta.id}-${variant}";
        };

      colorscheme =
        if isFunction pluginInfo.colorscheme then
          pluginInfo.colorscheme config.variant
        else
          pluginInfo.colorscheme;

      baseConfig = {
        inherit (pluginInfo) plugin;
        inherit (pluginInfo) name;
        inherit (pluginInfo) setup;
        inherit colorscheme;

        config = {
          transparent = true;
          terminal_colors = true;
          styles = {
            comments = {
              italic = true;
            };
            keywords = {
              bold = true;
            };
            functions = {
              bold = true;
            };
            strings = {
              italic = true;
            };
            variables = { };
            numbers = {
              bold = true;
            };
            booleans = {
              bold = true;
              italic = true;
            };
            properties = {
              italic = true;
            };
            types = {
              bold = true;
            };
            operators = {
              bold = true;
            };
          };
        };
      };
    in
    utils.mergeThemeConfigs baseConfig overrides;

  /*
    Generate Neovim JSON export.

    Exports theme configuration suitable for Neovim setup scripts.
  */
  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;

      pluginInfo =
        themeData.appAdapters.neovim or {
          plugin = "${themeData.meta.id}/${themeData.meta.id}.nvim";
          name = themeData.meta.id;
          setup = themeData.meta.id;
          colorscheme = variant: "${themeData.meta.id}-${variant}";
        };

      colorscheme =
        if isFunction pluginInfo.colorscheme then
          pluginInfo.colorscheme config.variant
        else
          pluginInfo.colorscheme;

      background = config.appearance or null;
      transparency = config.transparency or { };

      exported = {
        inherit colorscheme;
        inherit (config) variant;
        appearance = config.appearance or null;
        inherit background;
        inherit transparency;
        theme_name = "${themeData.meta.name} ${utils.capitalizeFirst config.variant}";

        plugins.${colorscheme} = {
          inherit (pluginInfo) plugin;
          inherit (pluginInfo) name;
          inherit (pluginInfo) setup;
          inherit colorscheme;
          base_scheme = themeData.meta.id;
        };

        inherit palette;
        colors = semanticColors;
        ansi = utils.generateAnsiMappings semanticColors;
      };
    in
    builtins.toJSON exported;
}
