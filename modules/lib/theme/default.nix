{ lib, ... }:

with lib;

let
  types = import ./core/types.nix { inherit lib; };
  constants = import ./core/constants.nix { inherit lib; };
  utils = import ./core/utils.nix { inherit lib; };

  catppuccin = import ./palettes/catppuccin.nix { inherit lib; };
  kanagawa = import ./palettes/kanagawa.nix { inherit lib; };
  rosePine = import ./palettes/rose-pine.nix { inherit lib; };
  gruvbox = import ./palettes/gruvbox.nix { inherit lib; };
  solarized = import ./palettes/solarized.nix { inherit lib; };
  nord = import ./palettes/nord.nix { inherit lib; };

  weztermAdapter = import ./adapters/wezterm.nix { inherit lib; };
  neovimAdapter = import ./adapters/neovim.nix { inherit lib; };

  transparencyPreset = import ./presets/transparency.nix { inherit lib; };

  themes = {
    catppuccin = catppuccin;
    kanagawa = kanagawa;
    rose-pine = rosePine;
    gruvbox = gruvbox;
    solarized = solarized;
    nord = nord;
  };

  getTheme =
    themeId:
    if hasAttr themeId themes then
      themes.${themeId}
    else
      throw "Theme '${themeId}' not found. Available themes: ${concatStringsSep ", " (attrNames themes)}";

  validateThemeConfig =
    config:
    let
      theme = getTheme config.colorscheme;
      validVariants = theme.meta.variants;
    in
    if !elem config.variant validVariants then
      throw "Variant '${config.variant}' not available for theme '${config.colorscheme}'. Available variants: ${concatStringsSep ", " validVariants}"
    else
      config;

  getThemePalette =
    colorscheme: variant:
    let
      theme = getTheme colorscheme;
    in
    if hasAttr variant theme.palettes then
      theme.palettes.${variant}
    else
      throw "Palette for variant '${variant}' not found in theme '${colorscheme}'";

  getSemanticColors =
    colorscheme: variant:
    let
      theme = getTheme colorscheme;
      palette = getThemePalette colorscheme variant;
    in
    theme.semanticMapping palette;

  getAppTheme =
    app: colorscheme: variant:
    let
      theme = getTheme colorscheme;
      appAdapters = theme.appAdapters;
    in
    if hasAttr app appAdapters then
      let
        adapter = appAdapters.${app};
      in
      if isFunction adapter then
        adapter variant
      else if hasAttr variant adapter then
        adapter.${variant}
      else if isAttrs adapter then
        adapter
      else
        "${colorscheme}-${variant}"
    else
      "${colorscheme}-${variant}";

  createAppConfig =
    app: themeConfig: overrides:
    let
      validatedConfig = validateThemeConfig themeConfig;
      theme = getTheme validatedConfig.colorscheme;
      palette = getThemePalette validatedConfig.colorscheme validatedConfig.variant;
      semanticColors = getSemanticColors validatedConfig.colorscheme validatedConfig.variant;

      finalConfig = fold (
        preset: _config: transparencyPreset.createAppTransparency app preset { }
      ) validatedConfig (validatedConfig.presets);

      appConfig =
        if app == "wezterm" then
          weztermAdapter.createWeztermConfig theme finalConfig overrides
        else if app == "neovim" then
          neovimAdapter.createNeovimConfig theme finalConfig overrides
        else
          {
            theme = getAppTheme app validatedConfig.colorscheme validatedConfig.variant;
            inherit palette semanticColors;
            config = finalConfig;
          };

    in
    {
      meta = theme.meta;
      palette = palette;
      semanticColors = semanticColors;
      config = finalConfig;
      colorscheme = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      variant = validatedConfig.variant;
      transparency =
        if hasAttr "transparency" finalConfig then
          finalConfig.transparency
        else
          throw "Missing transparency configuration in theme config";
    }
    // appConfig;

  generateAppJSON =
    app: themeConfig:
    let
      validatedConfig = validateThemeConfig themeConfig;
      theme = getTheme validatedConfig.colorscheme;
    in
    if app == "wezterm" then
      weztermAdapter.generateWeztermJSON theme validatedConfig
    else if app == "neovim" then
      neovimAdapter.generateNeovimJSON theme validatedConfig
    else
      {
        colorscheme = validatedConfig.colorscheme;
        variant = validatedConfig.variant;
        palette = getThemePalette validatedConfig.colorscheme validatedConfig.variant;
        semanticColors = getSemanticColors validatedConfig.colorscheme validatedConfig.variant;
        appTheme = getAppTheme app validatedConfig.colorscheme validatedConfig.variant;
        ansi = utils.generateAnsiMappings semanticColors;
      };

  getSafePalette = palette: utils.validatePalette palette;
  getUnifiedColors = palette: utils.createSemanticMapping palette;
  mergeThemeConfig = utils.mergeThemeConfigs;


  listAvailableThemes = map (theme: {
    id = theme.meta.id;
    name = theme.meta.name;
    variants = theme.meta.variants;
    supports = theme.meta.supports;
  }) (attrValues themes);

  getThemeInfo =
    themeId:
    let
      theme = getTheme themeId;
    in
    theme.meta;

  withThemeOverrides =
    baseConfig: app: overrides:
    createAppConfig app baseConfig overrides;

  ansiMappings = mapAttrs (
    _themeId: theme:
    mapAttrs (
      _variant: palette: utils.generateAnsiMappings (theme.semanticMapping palette)
    ) theme.palettes
  ) themes;

in
{
  inherit
    getTheme
    getThemePalette
    getSemanticColors
    getAppTheme
    createAppConfig
    generateAppJSON
    validateThemeConfig
    ;

  inherit
    utils
    constants
    types
    ;

  inherit themes listAvailableThemes getThemeInfo;

  inherit
    getSafePalette
    getUnifiedColors
    mergeThemeConfig
    withThemeOverrides
    ansiMappings
    ;


  adapters = {
    wezterm = weztermAdapter;
    neovim = neovimAdapter;
  };

  presets = {
    transparency = transparencyPreset;
  };
}
