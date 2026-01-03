{ lib, ... }:

with lib;

let
  types = import ./core/types.nix { inherit lib; };
  constants = import ./core/constants.nix { inherit lib; };
  utils = import ./core/utils.nix { inherit lib; };
  themeNames = import ./adapters/theme-names.nix { inherit lib; };

  catppuccin = import ./palettes/catppuccin.nix { inherit lib; };
  kanagawa = import ./palettes/kanagawa.nix { inherit lib; };
  kanso = import ./palettes/kanso.nix { inherit lib; };
  rosePine = import ./palettes/rose-pine.nix { inherit lib; };
  gruvbox = import ./palettes/gruvbox.nix { inherit lib; };
  solarized = import ./palettes/solarized.nix { inherit lib; };
  nord = import ./palettes/nord.nix { inherit lib; };
  everforest = import ./palettes/everforest.nix { inherit lib; };
  blackMetal = import ./palettes/black-metal.nix { inherit lib; };

  adapterBase = import ./core/adapter-base.nix { inherit lib utils; };
  weztermAdapter = import ./adapters/wezterm.nix { inherit lib utils adapterBase; };
  neovimAdapter = import ./adapters/neovim.nix { inherit lib utils adapterBase; };
  firefoxAdapter = import ./adapters/firefox.nix { inherit lib utils adapterBase; };
  base16Schemes = import ./adapters/base16-schemes.nix { inherit lib; };

  themes = {
    inherit catppuccin;
    inherit kanagawa;
    inherit kanso;
    rose-pine = rosePine;
    inherit gruvbox;
    inherit solarized;
    inherit nord;
    inherit everforest;
    black-metal = blackMetal;
  };

  getTheme =
    themeId:
    if hasAttr themeId themes then
      themes.${themeId}
    else
      throw "Theme '${themeId}' not found. Available themes: ${concatStringsSep ", " (attrNames themes)}";

  deriveVariantFromAppearance =
    colorscheme: appearance: currentVariant:
    let
      theme = getTheme colorscheme;
      effectiveAppearance = appearance;
      mapping =
        if effectiveAppearance != null then
          theme.meta.appearanceMapping.${effectiveAppearance} or null
        else
          null;
      variantMatchesAppearance =
        if effectiveAppearance == null then
          true
        else if elem currentVariant theme.meta.variants then
          if isList mapping then
            elem currentVariant mapping
          else if mapping != null then
            currentVariant == mapping
          else
            false
        else
          false;
    in
    if effectiveAppearance == null then
      currentVariant
    else if variantMatchesAppearance then
      currentVariant
    else if mapping == null then
      throw "Cannot derive variant: colorscheme '${colorscheme}' does not support appearance mode '${effectiveAppearance}'"
    else if isList mapping then
      head mapping
    else
      mapping;

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
      appThemeFunctions = {
        wezterm = themeNames.getWeztermTheme;
        neovim = _cs: _v: (themeNames.getNeovimConfig _cs _v).colorscheme;
        atuin = themeNames.getAtuinTheme;
      };
    in
    if hasAttr app appThemeFunctions then
      appThemeFunctions.${app} colorscheme variant
    else
      "${colorscheme}-${variant}";

  createAppConfig =
    app: themeConfig: overrides:
    let
      validatedConfig = themeConfig;
      theme = getTheme validatedConfig.colorscheme;
      palette = getThemePalette validatedConfig.colorscheme validatedConfig.variant;
      semanticColors = getSemanticColors validatedConfig.colorscheme validatedConfig.variant;

      appConfig =
        if app == "wezterm" then
          weztermAdapter.createWeztermConfig theme validatedConfig overrides
        else if app == "neovim" then
          neovimAdapter.createNeovimConfig theme validatedConfig overrides
        else if app == "firefox" then
          firefoxAdapter.createFirefoxConfig theme validatedConfig overrides
        else
          {
            theme = getAppTheme app validatedConfig.colorscheme validatedConfig.variant;
            inherit palette semanticColors;
            config = validatedConfig;
          };

    in
    {
      inherit (theme) meta;
      inherit palette;
      inherit semanticColors;
      config = validatedConfig;
      colorscheme = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit (validatedConfig) variant;
      transparency =
        if hasAttr "transparency" validatedConfig then
          validatedConfig.transparency
        else
          throw "Missing transparency configuration in theme config";
    }
    // appConfig;

  generateAppJSON =
    app: themeConfig:
    let
      validatedConfig = themeConfig;
      theme = getTheme validatedConfig.colorscheme;
      palette = getThemePalette validatedConfig.colorscheme validatedConfig.variant;
      semanticColors = getSemanticColors validatedConfig.colorscheme validatedConfig.variant;
      appTheme = getAppTheme app validatedConfig.colorscheme validatedConfig.variant;
      ansi = utils.generateAnsiMappings semanticColors;
    in
    if app == "wezterm" then
      weztermAdapter.generateWeztermJSON theme validatedConfig
    else if app == "neovim" then
      neovimAdapter.generateNeovimJSON theme validatedConfig
    else if app == "firefox" then
      firefoxAdapter.generateFirefoxJSON theme validatedConfig
    else
      {
        inherit (validatedConfig) colorscheme;
        inherit (validatedConfig) variant;
        font = if hasAttr "font" validatedConfig then validatedConfig.font else null;
        inherit (validatedConfig) transparency;
        inherit
          palette
          semanticColors
          appTheme
          ansi
          ;
      };

  mkThemedConfig =
    values: app: extraConfig:
    let
      validatedTheme = values.theme;
      appTheme = getAppTheme app validatedTheme.colorscheme validatedTheme.variant;
    in
    extraConfig
    // {
      inherit appTheme;
      themes = {
        inherit
          getTheme
          getThemePalette
          getSemanticColors
          getUnifiedColors
          getAppTheme
          createAppConfig
          generateAppJSON
          ;
      };

      themeConfig = {
        inherit (validatedTheme) colorscheme;
        inherit (validatedTheme) variant;
        inherit (validatedTheme) transparency;
      };
    };

  deployThemeFiles =
    values:
    {
      themeDir,
      targetPath,
      fileExtension ? null,
    }:
    let
      currentTheme = "${values.theme.colorscheme}-${values.theme.variant}";
      themeFileName = if fileExtension != null then "${currentTheme}.${fileExtension}" else currentTheme;
      themeFile = "${themeDir}/${themeFileName}";
    in
    optionalAttrs (pathExists themeFile) {
      "${targetPath}/${themeFileName}" = {
        source = themeFile;
        force = true;
      };
    };

  mkThemeFileConfigs =
    _values: configs:
    let
      mkThemeConfig =
        { condition, files }:
        mkIf condition (listToAttrs (map (file: nameValuePair file.name file.value) files));
    in
    mkMerge (map mkThemeConfig configs);

  mkThemeConditional =
    values: colorscheme: config:
    mkIf (values.theme.colorscheme == colorscheme) config;

  mkAllThemeFiles =
    values:
    {
      themeDir,
      targetPath,
      themes,
    }:
    let

      availableThemes = filter (theme: pathExists "${themeDir}/${theme}") themes;
      currentTheme = "${values.theme.colorscheme}-${values.theme.variant}";
    in
    if elem "${currentTheme}.toml" availableThemes then
      {
        "${targetPath}/${currentTheme}.toml" = {
          source = "${themeDir}/${currentTheme}.toml";
          force = true;
        };
      }
    else if elem "${currentTheme}.tmTheme" availableThemes then
      {
        "${targetPath}/${currentTheme}.tmTheme" = {
          source = "${themeDir}/${currentTheme}.tmTheme";
          force = true;
        };
      }
    else if elem "${currentTheme}.yaml" availableThemes then
      {
        "${targetPath}/${currentTheme}.yaml" = {
          source = "${themeDir}/${currentTheme}.yaml";
          force = true;
        };
      }
    else
      { };

  getSafePalette = palette: utils.validatePalette palette;
  getUnifiedColors = palette: utils.createSemanticMapping palette;
  mergeThemeConfig = utils.mergeThemeConfigs;

  listAvailableThemes = map (theme: {
    inherit (theme.meta) id;
    inherit (theme.meta) name;
    inherit (theme.meta) variants;
    inherit (theme.meta) supports;
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
    deriveVariantFromAppearance
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

  inherit
    mkThemedConfig
    deployThemeFiles
    mkThemeFileConfigs
    mkThemeConditional
    mkAllThemeFiles
    ;

  adapters = {
    wezterm = weztermAdapter;
    neovim = neovimAdapter;
    firefox = firefoxAdapter;
  };

  inherit base16Schemes;
}
