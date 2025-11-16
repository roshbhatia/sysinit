{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  createNeovimConfig =
    themeData: config: overrides:
    let
      transparency =
        if hasAttr "transparency" config then
          config.transparency
        else
          throw "Missing transparency configuration in neovim config";

      pluginInfo =
        if hasAttr "neovim" themeData.appAdapters then
          themeData.appAdapters.neovim
        else
          {
            plugin = "${themeData.meta.id}/${themeData.meta.id}.nvim";
            name = themeData.meta.id;
            setup = themeData.meta.id;
            colorscheme = variant: "${themeData.meta.id}-${variant}";
          };

      baseConfig = {
        inherit (pluginInfo) plugin;
        inherit (pluginInfo) name;
        inherit (pluginInfo) setup;
        colorscheme =
          if isFunction pluginInfo.colorscheme then
            pluginInfo.colorscheme config.variant
          else
            pluginInfo.colorscheme;

        config = {
          transparent =
            if hasAttr "enable" transparency then
              transparency.enable
            else
              throw "Missing 'enable' field in transparency configuration";
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

  generateNeovimJSON =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;

      pluginInfo =
        if hasAttr "neovim" themeData.appAdapters then
          themeData.appAdapters.neovim
        else
          {
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

      # Derive background from appearance for Neovim's background setting
      background = if hasAttr "appearance" config then config.appearance else null;
    in
    {
      inherit colorscheme;
      inherit (config) variant;
      appearance = if hasAttr "appearance" config then config.appearance else null;
      inherit background;
      transparency =
        if hasAttr "transparency" config then
          config.transparency
        else
          throw "Missing transparency configuration in neovim config";
      theme_name = themeData.meta.name + " " + (utils.capitalizeFirst config.variant);

      plugins.${colorscheme} = {
        inherit (pluginInfo) plugin;
        inherit (pluginInfo) name;
        inherit (pluginInfo) setup;
        inherit colorscheme;
      };

      inherit palette;
      colors = semanticColors;
      ansi = utils.generateAnsiMappings semanticColors;
    };
}
