{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = values.vet.additionalPackages or [ ];
in
{
  home.activation.vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "vet" packages config
  );
}
