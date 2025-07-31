{
  lib,
  values,
  utils,
  ...
}:

let
  npmPackages = [
    "opencode-ai@latest"
  ]
  ++ (values.npm.additionalPackages or [ ]);
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''\${HOME}/.local/share/.npm-packages
      strict-ssl = false
    '';
  };

  home.activation.npmPackages = utils.sysinit.mkPackageManagerActivation "npm" npmPackages;
}
