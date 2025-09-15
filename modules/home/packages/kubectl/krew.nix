{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  krewPackages = [
    "ctx"
  ]
  ++ values.krew.additionalPackages;
in
{
  home.activation.krewPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "kubectl" krewPackages
  );
}
