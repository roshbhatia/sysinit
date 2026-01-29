{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = values.cargo.additionalPackages or [ ];
in
{
  home.activation.cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "cargo" packages config
  );
}
