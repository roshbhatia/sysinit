{
  lib,
  values,
  utils,
  ...
}:

let
  yarnPackages = [
    "mcp-hub@latest"
  ]
  ++ (values.yarn.additionalPackages or [ ]);
in
{
  home.activation.yarnPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript "yarn" yarnPackages
  );
}
