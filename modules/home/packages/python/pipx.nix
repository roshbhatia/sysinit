{
  lib,
  values,
  utils,
  ...
}:

let
  pipxPackages = [ ] ++ (values.pipx.additionalPackages or [ ]);
in
{
  home.activation.pipxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript "pipx" pipxPackages
  );
}
