{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  vetPackages = values.vet.additionalPackages or [ ];
in
{
  home.activation = {
    vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.packages.mkPackageActivationScript "vet" vetPackages config
    );
  };
}
