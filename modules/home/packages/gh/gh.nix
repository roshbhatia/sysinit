{
  lib,
  values,
  utils,
  ...
}:

let
  ghPackages = [ ] ++ (values.gh.additionalPackages or [ ]);
in
{
  home.activation.ghPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "gh" ghPackages);
}
