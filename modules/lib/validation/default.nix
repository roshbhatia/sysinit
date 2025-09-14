{ lib }:

with lib;

let
  themes = import ../theme { inherit lib; };
in
{
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

  validateEmail = email: {
    assertion = builtins.match ".*@.*\\..*" email != null;
    message = "Invalid email address: '${email}'";
  };

  validateHostname = hostname: {
    assertion = builtins.match "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9]?" hostname != null;
    message = "Invalid hostname: '${hostname}'. Must be valid DNS hostname.";
  };

  validatePackageList =
    packages: packageType:
    map (pkg: {
      assertion = isString pkg && pkg != "";
      message = "Invalid ${packageType} package: '${toString pkg}' must be a non-empty string";
    }) packages;

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
      (validateEmail values.git.userEmail)
      {
        assertion = values.git.userName != "";
        message = "git.userName cannot be empty";
      }
      {
        assertion = values.git.githubUser != "";
        message = "git.githubUser cannot be empty";
      }
    ]
    ++ optionals (values.git ? personalEmail && values.git.personalEmail != null) [
      (validateEmail values.git.personalEmail)
    ]
    ++ optionals (values.git ? workEmail && values.git.workEmail != null) [
      (validateEmail values.git.workEmail)
    ];

  validateThemeConfig =
    values:
    validateTheme values.theme.colorscheme values.theme.variant
    ++ [
      {
        assertion = values.theme.transparency.opacity >= 0.0 && values.theme.transparency.opacity <= 1.0;
        message = "theme.transparency.opacity must be between 0.0 and 1.0, got: ${toString values.theme.transparency.opacity}";
      }
      {
        assertion = values.theme.transparency.blur >= 0 && values.theme.transparency.blur <= 100;
        message = "theme.transparency.blur must be between 0 and 100, got: ${toString values.theme.transparency.blur}";
      }
    ];

  validateYarnPackages = values: validatePackageList values.yarn.additionalPackages "yarn";

  validateAllConfigs =
    values:
    flatten [
      (validateUserConfig values)
      (validateGitConfig values)
      (validateThemeConfig values)
      (validateYarnPackages values)
    ];

  generateValidationWarnings = values: [
    (mkIf (
      values.theme.colorscheme == "solarized" && values.theme.variant == "light"
    ) "Light theme variants may have reduced readability in some applications")

    (mkIf (length values.yarn.additionalPackages > 10)
      "Large number of yarn packages (${toString (length values.yarn.additionalPackages)}) may slow system startup"
    )

    (mkIf (
      values.theme.transparency.opacity < 0.5
    ) "Very low opacity (${toString values.theme.transparency.opacity}) may affect readability")
  ];
}
