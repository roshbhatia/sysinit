{ lib, ... }:

with lib;

let
  types = import ./theme/core/types.nix { inherit lib; };
  constants = import ./theme/core/constants.nix { inherit lib; };
  utils = import ./theme/core/utils.nix { inherit lib; };
  themeNames = import ./theme/adapters/theme-names.nix { inherit lib; };
  metadata = import ./theme/metadata.nix { inherit lib; };

  adapterBase = import ./theme/core/adapter-base.nix { inherit lib utils; };
  weztermAdapter = import ./theme/adapters/wezterm.nix { inherit lib utils adapterBase; };
  neovimAdapter = import ./theme/adapters/neovim.nix { inherit lib utils adapterBase; };
  firefoxAdapter = import ./theme/adapters/firefox.nix { inherit lib utils adapterBase; };

  # Convert metadata to old theme format for compatibility
  themes = mapAttrs (id: meta: { inherit meta; }) metadata;

  getTheme =
    themeId:
    if hasAttr themeId metadata then
      metadata.${themeId}
    else
      throw "Theme '${themeId}' not found. Available themes: ${concatStringsSep ", " (attrNames metadata)}";

  deriveVariantFromAppearance =
    colorscheme: appearance: currentVariant:
    let
      theme = getTheme colorscheme;
      effectiveAppearance = appearance;
      mapping =
        if effectiveAppearance != null then
          theme.appearanceMapping.${effectiveAppearance} or null
        else
          null;
      variantMatchesAppearance =
        if effectiveAppearance == null then
          true
        else if elem currentVariant theme.variants then
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

  # Get base16 scheme path for stylix
  getBase16SchemePath =
    pkgs: colorscheme: variant:
    let
      mapping = import ./theme/base16-mapping.nix { inherit pkgs; };
    in
    if hasAttr colorscheme mapping then
      if hasAttr variant mapping.${colorscheme} then
        mapping.${colorscheme}.${variant}
      else
        throw "Variant '${variant}' not found for colorscheme '${colorscheme}'. Available variants: ${
          concatStringsSep ", " (attrNames mapping.${colorscheme})
        }"
    else
      throw "Colorscheme '${colorscheme}' not found in base16 mapping. Available: ${concatStringsSep ", " (attrNames mapping)}";

  getAppTheme =
    app: colorscheme: variant:
    let
      appThemeFunctions = {
        wezterm = themeNames.getWeztermTheme;
        neovim = _cs: _v: (themeNames.getNeovimMetadata _cs _v).colorscheme;
      };
    in
    if hasAttr app appThemeFunctions then
      appThemeFunctions.${app} colorscheme variant
    else
      "${colorscheme}-${variant}";

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
          getAppTheme
          getBase16SchemePath
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

  mergeThemeConfig = utils.mergeThemeConfigs;

  listAvailableThemes = map (meta: {
    inherit (meta)
      id
      name
      variants
      supports
      ;
  }) (attrValues metadata);

  getThemeInfo = getTheme;

  # Helper functions for generating application configuration files
  makeThemeJsonConfig =
    values: overrides:
    lib.recursiveUpdate {
      font = {
        inherit (values.theme.font) monospace symbols;
      };
      transparency = {
        inherit (values.theme.transparency) opacity blur;
      };
    } overrides;

  # Wrap a Nix value as JSON for use in xdg.configFile
  toJsonFile = builtins.toJSON;

in
{
  inherit
    getTheme
    getAppTheme
    getBase16SchemePath
    deriveVariantFromAppearance
    ;

  inherit
    utils
    constants
    types
    ;

  inherit metadata listAvailableThemes getThemeInfo;

  inherit
    mergeThemeConfig
    makeThemeJsonConfig
    toJsonFile
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
}
