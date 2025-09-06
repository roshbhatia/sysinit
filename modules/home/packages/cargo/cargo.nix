{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  cargoPackages = [ ] ++ (values.cargo.additionalPackages or [ ]);
in
{
  home.activation = {
    cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.sysinit.mkPackageManagerScript config "cargo" cargoPackages
    );
  };
}
