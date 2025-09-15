{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  cargoPackages = [ ] ++ values.cargo.additionalPackages;
in
{
  home.activation = {
    cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.packages.mkPackageManagerScript config "cargo" cargoPackages
    );
  };
}
