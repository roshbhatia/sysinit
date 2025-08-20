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
  ++ (values.krew.additionalPackages or [ ]);
in
{
  home.activation.krewPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "kubectl" krewPackages
  );
}
