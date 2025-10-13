{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  vetPackages = [
    "https://cursor.com/install"
  ]
  ++ values.vet.additionalPackages;
in
{
  home.activation = {
    vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.packages.mkPackageManagerScript config "vet" vetPackages
    );
  };
}
