{ lib }:

with lib;

let
  themes = import ../theme { inherit lib; };

  validateHostname = hostname: {
    assertion = builtins.match "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9]?" hostname != null;
    message = "Invalid hostname: '${hostname}'. Must be valid DNS hostname.";
  };

  validateEmail = email: {
    assertion = builtins.match ".*@.*\\..*" email != null;
    message = "Invalid email address: '${email}'";
  };

  validatePackageList =
    packages: packageType:
    map (pkg: {
      assertion = isString pkg && pkg != "";
      message = "Invalid ${packageType} package: '${toString pkg}' must be a non-empty string";
    }) packages;

  validateAppearanceMode = appearance: {
    assertion = elem appearance [
      "light"
      "dark"
    ];
    message = "Invalid appearance mode: '${appearance}'. Must be 'light' or 'dark'.";
  };

  validateFont = fontConfig: [
    {
      assertion = isString fontConfig.monospace && fontConfig.monospace != "";
      message = "Font name cannot be empty: font.monospace must be a non-empty string";
    }
    {
      assertion = isString fontConfig.nerdfontFallback && fontConfig.nerdfontFallback != "";
      message = "Font name cannot be empty: font.nerdfontFallback must be a non-empty string";
    }
  ];

  validatePaletteAppearance =
    colorscheme: appearance:
    let
      palette = if hasAttr colorscheme themes.themes then themes.themes.${colorscheme} else null;
      hasAppearanceMapping = palette != null && hasAttr "appearanceMapping" palette.meta;
      appearanceMapping = if hasAppearanceMapping then palette.meta.appearanceMapping else { };
      supportsAppearance =
        hasAppearanceMapping
        && hasAttr appearance appearanceMapping
        && appearanceMapping.${appearance} != null;
      availableModes =
        if hasAppearanceMapping then
          (filter (mode: appearanceMapping.${mode} != null) (attrNames appearanceMapping))
        else
          [ ];
      supportedPalettes = filter (
        pName:
        let
          p = themes.themes.${pName};
        in
        hasAttr "appearanceMapping" p.meta
        && hasAttr appearance p.meta.appearanceMapping
        && p.meta.appearanceMapping.${appearance} != null
      ) (attrNames themes.themes);
    in
    {
      assertion = supportsAppearance;
      message = ''
        Theme validation failed: Palette '${colorscheme}' does not support appearance mode '${appearance}'.

        Available appearance modes for '${colorscheme}': ${concatStringsSep ", " availableModes}

        Palettes supporting '${appearance}' mode: ${concatStringsSep ", " supportedPalettes}

        Please either:
          1. Change appearance to one of: ${concatStringsSep ", " availableModes}, or
          2. Change colorscheme to a palette that supports '${appearance}' mode
      '';
    };
in
rec {
  inherit
    validateHostname
    validateEmail
    validatePackageList
    validateAppearanceMode
    validateFont
    validatePaletteAppearance
    ;

  validateTheme =
    colorscheme: variant:
    let
      availableColorschemes = attrNames themes.themes;
      availableVariants =
        if hasAttr colorscheme themes.themes then themes.themes.${colorscheme}.meta.variants else [ ];
    in
    [
      {
        assertion = hasAttr colorscheme themes.themes;
        message = ''
          Invalid colorscheme: '${colorscheme}'
          Available colorschemes: ${concatStringsSep ", " availableColorschemes}
        '';
      }
      {
        assertion = elem variant availableVariants;
        message = ''
          Invalid variant '${variant}' for colorscheme '${colorscheme}'
          Available variants: ${concatStringsSep ", " availableVariants}
        '';
      }
    ];

  validatePath = path: {
    assertion = isString path && path != "";
    message = "Path must be a non-empty string: '${toString path}'";
  };

  validateUserConfig = values: [
    {
      assertion = values.user.username != "";
      message = "user.username cannot be empty";
    }
    (validateHostname values.user.hostname)
  ];

  validateGitConfig =
    values:
    [
      (validateEmail values.git.email)
      {
        assertion = values.git.name != "";
        message = "git.name cannot be empty";
      }
      {
        assertion = values.git.username != "";
        message = "git.username cannot be empty";
      }
    ]
    ++ optionals (values.git ? personalEmail && values.git.personalEmail != null) [
      (validateEmail values.git.personalEmail)
    ]
    ++ optionals (values.git ? workEmail && values.git.workEmail != null) [
      (validateEmail values.git.workEmail)
    ];

  validateAllConfigs =
    values:
    flatten [
      (validateUserConfig values)
      (validateGitConfig values)
    ];
}
