{ lib, ... }:

with lib;

let
  # Import core modules
  types = import ./core/types.nix { inherit lib; };
  constants = import ./core/constants.nix { inherit lib; };
  utils = import ./core/utils.nix { inherit lib; };

  # Import theme palettes
  catppuccin = import ./palettes/catppuccin.nix { inherit lib; };
  kanagawa = import ./palettes/kanagawa.nix { inherit lib; };
  rosePine = import ./palettes/rose-pine.nix { inherit lib; };
  gruvbox = import ./palettes/gruvbox.nix { inherit lib; };
  solarized = import ./palettes/solarized.nix { inherit lib; };
  nord = import ./palettes/nord.nix { inherit lib; };

  # Import adapters
  weztermAdapter = import ./adapters/wezterm.nix { inherit lib; };
  neovimAdapter = import ./adapters/neovim.nix { inherit lib; };

  # Import presets
  transparencyPreset = import ./presets/transparency.nix { inherit lib; };

  # Available themes registry
  themes = {
    catppuccin = catppuccin;
    kanagawa = kanagawa;
    rose-pine = rosePine;
    gruvbox = gruvbox;
    solarized = solarized;
    nord = nord;
  };

  # Get theme by ID
  getTheme =
    themeId:
    if hasAttr themeId themes then
      themes.${themeId}
    else
      throw "Theme '${themeId}' not found. Available themes: ${concatStringsSep ", " (attrNames themes)}";

  # Validate theme configuration
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

  # Get theme palette with validation
  getThemePalette =
    colorscheme: variant:
    let
      theme = getTheme colorscheme;
      config = validateThemeConfig { inherit colorscheme variant; };
    in
    if hasAttr variant theme.palettes then
      theme.palettes.${variant}
    else
      throw "Palette for variant '${variant}' not found in theme '${colorscheme}'";

  # Get semantic colors for theme
  getSemanticColors =
    colorscheme: variant:
    let
      theme = getTheme colorscheme;
      palette = getThemePalette colorscheme variant;
    in
    theme.semanticMapping palette;

  # Get app-specific theme configuration
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

  # Create complete theme configuration for an app
  createAppConfig =
    app: themeConfig: overrides:
    let
      validatedConfig = validateThemeConfig themeConfig;
      theme = getTheme validatedConfig.colorscheme;
      palette = getThemePalette validatedConfig.colorscheme validatedConfig.variant;
      semanticColors = getSemanticColors validatedConfig.colorscheme validatedConfig.variant;

      # Apply transparency presets
      finalConfig = fold (
        preset: config: transparencyPreset.createAppTransparency app preset { }
      ) validatedConfig (validatedConfig.presets or [ ]);

      # App-specific configuration generation
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
    appConfig
    // {
      meta = theme.meta;
      palette = palette;
      semanticColors = semanticColors;
      config = finalConfig;
    };

  # Generate JSON configuration for apps that need it
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

  # Legacy compatibility functions (for gradual migration)
  getSafePalette = palette: utils.validatePalette palette;
  getUnifiedColors = semanticColors: semanticColors;
  mergeThemeConfig = utils.mergeThemeConfigs;

  # Theme registry functions
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

  # Enhanced theme utilities
  withThemeOverrides =
    baseConfig: app: overrides:
    createAppConfig app baseConfig overrides;

  # ANSI mappings (legacy compatibility)
  ansiMappings = mapAttrs (
    themeId: theme:
    mapAttrs (
      variant: palette: utils.generateAnsiMappings (theme.semanticMapping palette)
    ) theme.palettes
  ) themes;

in
{
  # Core functions
  inherit
    getTheme
    getThemePalette
    getSemanticColors
    getAppTheme
    createAppConfig
    generateAppJSON
    validateThemeConfig
    ;

  # Utility functions
  inherit
    utils
    constants
    types
    ;

  # Theme registry
  inherit themes listAvailableThemes getThemeInfo;

  # Legacy compatibility
  inherit
    getSafePalette
    getUnifiedColors
    mergeThemeConfig
    withThemeOverrides
    ansiMappings
    ;

  # Adapters
  adapters = {
    wezterm = weztermAdapter;
    neovim = neovimAdapter;
  };

  # Presets
  presets = {
    transparency = transparencyPreset;
  };
}
