{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = [
    "@beads/bd"
  ]
  ++ (values.npm.additionalPackages or [ ]);
in
{
  home.file.".npmrc" = {
    text = ''
      prefix = ''${HOME}/.local/share/.npm-packages
      strict-ssl = false
    '';
  };

  home.activation.npmPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "npm" packages config
  );
}
