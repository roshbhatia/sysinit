{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  yarnPackages = [ ] ++ (values.yarn.additionalPackages or [ ]);
in
{
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "yarn" yarnPackages
  );
}
