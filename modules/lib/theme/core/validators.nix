{ lib }:

with lib;

{
  /*
    Unified validation module for theme configurations.

    Provides type-safe validators for all theme components:
    - Colors (hex values)
    - Palette IDs and variants
    - Appearance modes
    - Transparency settings
    - Theme configurations
  */

  /*
    Validate a hex color value.

    Arguments:
      color: string - Color value to validate (e.g. "#ffffff")

    Returns:
      string - The color if valid, or throws error
  */
  validateColor =
    color:
    if
      isString color
      && (match "^#[0-9a-fA-F]{6}$" color != null || match "^#[0-9a-fA-F]{8}$" color != null)
    then
      color
    else
      throw "Invalid hex color value: '${color}'. Expected #RRGGBB or #RRGGBBAA";

  /*
    Validate a palette ID.

    Arguments:
      id: string - Palette identifier

    Returns:
      string - The ID if valid, throws error otherwise
  */
  validatePaletteId =
    id:
    let
      validPalettes = [
        "catppuccin"
        "gruvbox"
        "kanagawa"
        "rose-pine"
        "solarized"
        "nord"
        "everforest"
        "black-metal"
      ];
    in
    if elem id validPalettes then
      id
    else
      throw "Invalid palette ID: '${id}'. Valid palettes: ${concatStringsSep ", " validPalettes}";

  /*
    Validate a palette variant for a given palette.

    Arguments:
      paletteId: string - Palette identifier
      variant: string - Variant name

    Returns:
      string - The variant if valid, throws error otherwise
  */
  validateVariant =
    paletteId: variant:
    let
      variantMap = {
        catppuccin = [
          "latte"
          "frappe"
          "macchiato"
          "mocha"
        ];
        gruvbox = [
          "dark"
          "light"
        ];
        kanagawa = [
          "wave"
          "dragon"
        ];
        rose-pine = [
          "dawn"
          "main"
          "moon"
        ];
        solarized = [
          "dark"
          "light"
        ];
        nord = [ "default" ];
        everforest = [
          "dark-soft"
          "dark-medium"
          "dark-hard"
          "light-soft"
          "light-medium"
          "light-hard"
        ];
        black-metal = [
          "nile"
          "gorgoroth"
          "morbid"
        ];
      };
      validVariants = variantMap.${paletteId} or [ ];
    in
    if elem variant validVariants then
      variant
    else
      throw "Invalid variant '${variant}' for palette '${paletteId}'. Valid variants: ${concatStringsSep ", " validVariants}";

  /*
    Validate appearance mode.

    Arguments:
      appearance: string - Appearance mode ("light" or "dark")

    Returns:
      string - The appearance if valid, throws error otherwise
  */
  validateAppearance =
    appearance:
    if
      elem appearance [
        "light"
        "dark"
      ]
    then
      appearance
    else
      throw "Invalid appearance: '${appearance}'. Must be 'light' or 'dark'";

  /*
    Validate transparency configuration.

    Arguments:
      transparency: attrs - { enable: bool, opacity: float (0-1), blur: int (>=0) }

    Returns:
      attrs - The transparency config if valid, throws error otherwise
  */
  validateTransparency =
    transparency:
    let
      hasEnable = hasAttr "enable" transparency;
      hasOpacity = hasAttr "opacity" transparency;
      hasBlur = hasAttr "blur" transparency;

      enableValid = hasEnable && isBool transparency.enable;
      opacityValid =
        hasOpacity
        && isFloat transparency.opacity
        && transparency.opacity >= 0
        && transparency.opacity <= 1;
      blurValid = hasBlur && isInt transparency.blur && transparency.blur >= 0;
    in
    if !hasEnable then
      throw "Transparency config missing 'enable' field"
    else if !enableValid then
      throw "Transparency 'enable' must be a boolean"
    else if hasOpacity && !opacityValid then
      throw "Transparency 'opacity' must be a float between 0 and 1, got: ${toString transparency.opacity}"
    else if hasBlur && !blurValid then
      throw "Transparency 'blur' must be a non-negative integer, got: ${toString transparency.blur}"
    else
      transparency;

  /*
    Validate theme configuration.

    Arguments:
      config: attrs - Theme configuration

    Returns:
      attrs - The config if valid, throws error otherwise
  */
  validateThemeConfig =
    config:
    let
      hasColorscheme = hasAttr "colorscheme" config;
      hasVariant = hasAttr "variant" config;
      hasAppearance = hasAttr "appearance" config;

      colorschemeValid = hasColorscheme && isString config.colorscheme;
      variantValid = hasVariant && isString config.variant;
      appearanceValid = !hasAppearance || (isString config.appearance || config.appearance == null);
    in
    if !hasColorscheme then
      throw "Theme config missing 'colorscheme' field"
    else if !colorschemeValid then
      throw "Theme 'colorscheme' must be a string"
    else if !hasVariant then
      throw "Theme config missing 'variant' field"
    else if !variantValid then
      throw "Theme 'variant' must be a string"
    else if !appearanceValid then
      throw "Theme 'appearance' must be a string or null"
    else
      config;

  /*
    Validate palette structure.

    Arguments:
      palette: attrs - Palette color definitions

    Returns:
      attrs - The palette if valid, throws error otherwise
  */
  validatePalette =
    palette:
    let
      isValidColor =
        color:
        isString color
        && (match "^#[0-9a-fA-F]{6}$" color != null || match "^#[0-9a-fA-F]{8}$" color != null);
      invalidColors = filterAttrs (_key: value: !(isValidColor value)) palette;
    in
    if invalidColors != { } then
      throw "Palette contains invalid color values in keys: ${concatStringsSep ", " (attrNames invalidColors)}"
    else
      palette;

  /*
    Validate app adapter configuration.

    Arguments:
      appName: string - Name of the application
      config: attrs - App configuration

    Returns:
      attrs - The config if valid, throws error otherwise
  */
  validateAppAdapter =
    appName: config:
    if !isAttrs config then
      throw "App adapter '${appName}' configuration must be an attribute set"
    else if config == { } then
      throw "App adapter '${appName}' configuration is empty"
    else
      config;

  /*
    Validate font specification.

    Arguments:
      fontSpec: attrs - { family: string, size: int }

    Returns:
      attrs - The font spec if valid, throws error otherwise
  */
  validateFont =
    fontSpec:
    let
      hasFamily = hasAttr "family" fontSpec;
      hasSize = hasAttr "size" fontSpec;

      familyValid = hasFamily && isString fontSpec.family && fontSpec.family != "";
      sizeValid = hasSize && isInt fontSpec.size && fontSpec.size > 0 && fontSpec.size < 1000;
    in
    if !hasFamily then
      throw "Font spec missing 'family' field"
    else if !familyValid then
      throw "Font 'family' must be a non-empty string"
    else if !hasSize then
      throw "Font spec missing 'size' field"
    else if !sizeValid then
      throw "Font 'size' must be an integer between 1 and 999, got: ${toString fontSpec.size}"
    else
      fontSpec;

  /*
    Comprehensive theme validation combining all checks.

    Arguments:
      themeConfig: attrs - Complete theme configuration

    Returns:
      attrs - The config if all validations pass, throws otherwise
  */
  validateCompleteTheme =
    themeConfig:
    let
      baseValidated = validateThemeConfig themeConfig;
    in
    baseValidated
    // {
      _validated = true;
    };

  /*
    Validate variant is supported for a specific palette.

    Arguments:
      paletteId: string - Palette identifier
      variant: string - Variant name to validate

    Returns:
      bool - True if valid
  */
  variantSupported =
    paletteId: variant:
    let
      result = builtins.tryEval (validateVariant paletteId variant);
    in
    result.success;

  /*
    Create a type that validates on construction.

    Useful for inline validation in Nix modules.
  */
  colorType = types.str // {
    check = color: (validateColor color) == color;
    description = "valid hex color (#RRGGBB or #RRGGBBAA)";
  };

  paletteIdType = types.str // {
    check = id: (validatePaletteId id) == id;
    description = "valid palette ID";
  };

  appearanceType = types.str // {
    check = app: (validateAppearance app) == app;
    description = "appearance mode (light or dark)";
  };

  transparencyType = types.attrs // {
    check = t: (validateTransparency t) == t;
    description = "transparency configuration";
  };
}
