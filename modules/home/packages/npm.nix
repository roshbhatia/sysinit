{
  config,
  lib,
  utils,
  ...
}:

let

  packages = [
    "@charmland/crush"
    "@fission-ai/openspec"
  ]
  ++ config.sysinit.npm.additionalPackages;
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
