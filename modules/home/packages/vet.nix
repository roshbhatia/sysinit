{
  config,
  lib,
  utils,
  ...
}:

let

  packages = config.sysinit.vet.additionalPackages;
in
{
  home.activation.vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "vet" packages config
  );
}
