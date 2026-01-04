{
  config,
  values,
  utils,
  ...
}:

let
  npmPackages = values.npm.additionalPackages or [ ];
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''\${HOME}/.local/share/.npm-packages
      strict-ssl = false
    '';
  };

  home.activation.npmPackages = utils.packages.mkPackageActivation "npm" npmPackages config;
}
