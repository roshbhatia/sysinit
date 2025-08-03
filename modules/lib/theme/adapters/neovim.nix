{ lib, ... }:

with lib;

let
  utils = import ../core/utils.nix { inherit lib; };
in

{
  # Create Neovim theme configuration
  createNeovimConfig = themeData: config: overrides:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      transparency = config.transparency or {};

      # Get plugin information
      pluginInfo = if hasAttr "neovim" themeData.appAdapters then
        themeData.appAdapters.neovim
      else {
        plugin = "${themeData.meta.id}/${themeData.meta.id}.nvim";
        name = themeData.meta.id;
        setup = themeData.meta.id;
        colorscheme = variant: "${themeData.meta.id}-${variant}";
      };

      # Base configuration
      baseConfig = {
        plugin = pluginInfo.plugin;
        name = pluginInfo.name;
        setup = pluginInfo.setup;
        colorscheme = if isFunction pluginInfo.colorscheme then
          pluginInfo.colorscheme config.variant
        else
          pluginInfo.colorscheme;

        # Theme-specific configuration
        config = {
          transparent = transparency.enable or false;
          terminal_colors = true;
          styles = {
            comments = { "italic" };
            keywords = { "bold" };
            functions = { "bold" };
            strings = { "italic" };
            variables = {};
            numbers = { "bold" };
            booleans = { "bold" "italic" };
            properties = { "italic" };
            types = { "bold" };
            operators = { "bold" };
          };
        };
      };

    in
    utils.mergeThemeConfigs baseConfig overrides;

  # Generate JSON config for Neovim Lua integration
  generateNeovimJSON = themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      neovimConfig = createNeovimConfig themeData config {};
    in
    {
      colorscheme = themeData.meta.id;
      variant = config.variant;
      transparency = config.transparency or {};

      # Plugin configuration
      plugins.${themeData.meta.id} = {
        plugin = neovimConfig.plugin;
        name = neovimConfig.name;
        setup = neovimConfig.setup;
        colorscheme = neovimConfig.colorscheme;
      };

      # Color information
      palette = palette;
      colors = semanticColors;
      ansi = utils.generateAnsiMappings semanticColors;
    };

  # Create theme-specific highlight overrides
  createHighlightOverrides = themeData: config:
    let
      palette = themeData.palettes.${config.variant};
      semanticColors = themeData.semanticMapping palette;
      isTransparent = config.transparency.enable or false;

      # Base overrides that work for all themes
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
        CursorLine = { bg = if isTransparent then "none" else semanticColors.background.secondary; };
        Visual = {
          bg = semanticColors.accent.dim;
          fg = semanticColors.foreground.primary;
          style = { "bold" };
        };
        Search = {
          bg = semanticColors.semantic.warning;
          fg = semanticColors.background.primary;
          style = { "bold" };
        };
        IncSearch = {
          bg = semanticColors.semantic.error;
          fg = semanticColors.background.primary;
          style = { "bold" };
        };

        # Floating windows
        NormalFloat = { bg = if isTransparent then "none" else semanticColors.background.secondary; };
        FloatBorder = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };
        FloatTitle = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          style = { "bold" };
        };

        # Popup menus
        Pmenu = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.primary;
        };
        PmenuSel = {
          bg = semanticColors.accent.dim;
          fg = semanticColors.accent.primary;
          style = { "bold" };
        };
        PmenuBorder = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.secondary;
        };

        # Status line
        StatusLine = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.primary;
        };
        StatusLineNC = {
          bg = if isTransparent then "none" else semanticColors.background.secondary;
          fg = semanticColors.foreground.muted;
        };

        # Window separators
        WinSeparator = {
          fg = semanticColors.accent.primary;
          bg = if isTransparent then "none" else semanticColors.background.primary;
          style = { "bold" };
        };

        # Diagnostics
        DiagnosticError = { fg = semanticColors.semantic.error; style = { "bold" }; };
        DiagnosticWarn = { fg = semanticColors.semantic.warning; style = { "bold" }; };
        DiagnosticInfo = { fg = semanticColors.semantic.info; style = { "bold" }; };
        DiagnosticHint = { fg = semanticColors.syntax.operator; style = { "bold" }; };

        # Git signs
        GitSignsAdd = { fg = semanticColors.semantic.success; style = { "bold" }; };
        GitSignsChange = { fg = semanticColors.semantic.warning; style = { "bold" }; };
        GitSignsDelete = { fg = semanticColors.semantic.error; style = { "bold" }; };
      };

    in
    baseOverrides;
}
