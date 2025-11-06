{ lib, ... }:

with lib;

let
  types = import ./core/types.nix { inherit lib; };
  constants = import ./core/constants.nix { inherit lib; };
  utils = import ./core/utils.nix { inherit lib; };
  validators = import ../validation { inherit lib; };

  catppuccin = import ./palettes/catppuccin.nix { inherit lib; };
  kanagawa = import ./palettes/kanagawa.nix { inherit lib; };
  rosePine = import ./palettes/rose-pine.nix { inherit lib; };
  gruvbox = import ./palettes/gruvbox.nix { inherit lib; };
  solarized = import ./palettes/solarized.nix { inherit lib; };
  nord = import ./palettes/nord.nix { inherit lib; };

  weztermAdapter = import ./adapters/wezterm.nix { inherit lib; };
  neovimAdapter = import ./adapters/neovim.nix { inherit lib; };
  firefoxAdapter = import ./adapters/firefox.nix { inherit lib; };

  transparencyPreset = import ./presets/transparency.nix { inherit lib; };

  themes = {
    inherit catppuccin;
    inherit kanagawa;
    rose-pine = rosePine;
    inherit gruvbox;
    inherit solarized;
    inherit nord;
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
      # If appearance is null, use the currentVariant as-is (backward compat)
      effectiveAppearance = if appearance == null then null else appearance;
      mapping =
        if effectiveAppearance != null then
          theme.meta.appearanceMapping.${effectiveAppearance} or null
        else
          null;

      # Check if current variant matches the requested appearance
      variantMatchesAppearance =
        if effectiveAppearance == null then
          true # No appearance specified, use current variant
        else if elem currentVariant theme.meta.variants then
          # Check if this variant supports the requested appearance
          # by seeing if the appearance maps to this or compatible variant
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
      # No appearance specified, use current variant (backward compat mode)
      currentVariant
    else if variantMatchesAppearance then
      # Current variant is compatible with appearance, use it
      currentVariant
    else if mapping == null then
      # Appearance specified but palette doesn't support it
      throw
        "Cannot derive variant: colorscheme '${colorscheme}' does not support appearance mode '${effectiveAppearance}'"
    else if isList mapping then
      # Use first variant from mapping
      head mapping
    else
      # Use the mapped variant
      mapping;

  validateThemeConfig =
    config:
    let
      theme = getTheme config.colorscheme;
      validVariants = theme.meta.variants;

      # Derive effective variant from appearance
      # If appearance is specified, check if current variant is compatible
      # If not compatible or not valid, derive from appearance mapping
      effectiveVariant = deriveVariantFromAppearance config.colorscheme (
        if hasAttr "appearance" config then config.appearance else null
      ) (config.variant or null);

      # Validate appearance mode if present and non-null
      appearanceCheck =
        if hasAttr "appearance" config && config.appearance != null then
          validators.validateAppearanceMode config.appearance
        else
          null;

      # Validate font config if present
      fontChecks = if hasAttr "font" config then validators.validateFont config.font else [ ];

      # Validate palette supports appearance mode if present and non-null
      paletteAppearanceCheck =
        if hasAttr "appearance" config && config.appearance != null then
          validators.validatePaletteAppearance config.colorscheme config.appearance
        else
          null;

      # Collect all validation failures
      validationFailures =
        (optional (appearanceCheck != null && !appearanceCheck.assertion) appearanceCheck.message)
        ++ (map (check: check.message) (filter (check: !check.assertion) fontChecks))
        ++ (optional (
          paletteAppearanceCheck != null && !paletteAppearanceCheck.assertion
        ) paletteAppearanceCheck.message);

      # Variant check using derived effective variant
      variantFailure =
        if !elem effectiveVariant validVariants then
          "Variant '${effectiveVariant}' not available for theme '${config.colorscheme}'. Available variants: ${concatStringsSep ", " validVariants}"
        else
          null;

      allFailures = validationFailures ++ (optional (variantFailure != null) variantFailure);

      # Return config with effective variant injected
      finalConfig = config // {
        variant = effectiveVariant;
      };
    in
    if length allFailures > 0 then throw (concatStringsSep "\n\n" allFailures) else finalConfig;

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
      inherit (theme) appAdapters;
    in
    if hasAttr app appAdapters then
      let
        adapter = appAdapters.${app};
      in
      if isFunction adapter then
        adapter variant
      else if isAttrs adapter then
        if hasAttr variant adapter then adapter.${variant} else adapter
      else
        adapter
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
      ) validatedConfig validatedConfig.presets;

      appConfig =
        if app == "wezterm" then
          weztermAdapter.createWeztermConfig theme finalConfig overrides
        else if app == "neovim" then
          neovimAdapter.createNeovimConfig theme finalConfig overrides
        else if app == "firefox" then
          firefoxAdapter.createFirefoxConfig theme finalConfig overrides
        else
          {
            theme = getAppTheme app validatedConfig.colorscheme validatedConfig.variant;
            inherit palette semanticColors;
            config = finalConfig;
          };

    in
    {
      inherit (theme) meta;
      inherit palette;
      inherit semanticColors;
      config = finalConfig;
      colorscheme = "${validatedConfig.colorscheme}-${validatedConfig.variant}";
      inherit (validatedConfig) variant;
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
      # Validate theme config to derive variant from appearance
      validatedTheme = validateThemeConfig values.theme;
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
          validateThemeConfig
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
    validateThemeConfig
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

  presets = {
    transparency = transparencyPreset;
  };
}
