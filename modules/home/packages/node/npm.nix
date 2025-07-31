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

  home.activation.npmPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "npm" npmPackages);
}
