{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  npmPackages = [ ] ++ values.npm.additionalPackages;
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''\${HOME}/.local/share/.npm-packages
      strict-ssl = false
    '';
  };

  home.activation.npmPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "npm" npmPackages
  );
}
