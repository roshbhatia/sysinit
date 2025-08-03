{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{

  createNeovimConfig =
    themeData: config: overrides:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = utils.createSemanticMapping palette;
      transparency = config.transparency or { };

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
        plugin = pluginInfo.plugin;
        name = pluginInfo.name;
        setup = pluginInfo.setup;
        colorscheme =
          if isFunction pluginInfo.colorscheme then
            pluginInfo.colorscheme config.variant
          else
            pluginInfo.colorscheme;

        config = {
          transparent = transparency.enable or false;
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
      neovimConfig = createNeovimConfig themeData config { };
    in
    {
      colorscheme = themeData.meta.id;
      variant = config.variant;
      transparency = config.transparency or { };

      plugins.${themeData.meta.id} = {
        plugin = neovimConfig.plugin;
        name = neovimConfig.name;
        setup = neovimConfig.setup;
        colorscheme = neovimConfig.colorscheme;
      };

      palette = palette;
      colors = semanticColors;
      ansi = utils.generateAnsiMappings semanticColors;
    };

  createHighlightOverrides =
    themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      isTransparent = config.transparency.enable or false;

      baseOverrides = {
        Normal = {
          bg = if isTransparent then "none" else semanticColors.background.primary;
          fg = semanticColors.foreground.primary;
        };
        NormalNC = {
          bg = if isTransparent then "none" else semanticColors.background.primary;
        };
        SignColumn = {
          bg = if isTransparent then "none" else semanticColors.background.primary;
        };
        CursorLine = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };
        Visual = {
          bg = semanticColors.accent.dim;
          fg = semanticColors.foreground.primary;
          style = {
            bold = true;
          };
        };
        Search = {
          bg = semanticColors.semantic.warning;
          fg = semanticColors.background.primary;
          style = {
            bold = true;
          };
        };
        IncSearch = {
          bg = semanticColors.semantic.error;
          fg = semanticColors.background.primary;
          style = {
            bold = true;
          };
        };

        NormalFloat = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };
        FloatBorder = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };
        FloatTitle = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          style = {
            bold = true;
          };
        };

        Pmenu = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.primary;
        };
        PmenuSel = {
          bg = semanticColors.accent.dim;
          fg = semanticColors.accent.primary;
          style = {
            bold = true;
          };
        };
        PmenuBorder = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };

        StatusLine = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.primary;
        };
        StatusLineNC = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.muted;
        };

        WinSeparator = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.primary;
          style = {
            bold = true;
          };
        };

        DiagnosticError = {
          fg = semanticColors.semantic.error;
          style = {
            bold = true;
          };
        };
        DiagnosticWarn = {
          fg = semanticColors.semantic.warning;
          style = {
            bold = true;
          };
        };
        DiagnosticInfo = {
          fg = semanticColors.semantic.info;
          style = {
            bold = true;
          };
        };
        DiagnosticHint = {
          fg = semanticColors.syntax.operator;
          style = {
            bold = true;
          };
        };

        GitSignsAdd = {
          fg = semanticColors.semantic.success;
          style = {
            bold = true;
          };
        };
        GitSignsChange = {
          fg = semanticColors.semantic.warning;
          style = {
            bold = true;
          };
        };
        GitSignsDelete = {
          fg = semanticColors.semantic.error;
          style = {
            bold = true;
          };
        };
      };

    in
    {
      appTheme = baseOverrides;
    };
}
