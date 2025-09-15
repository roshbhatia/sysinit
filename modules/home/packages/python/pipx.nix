{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  pipxPackages = [ ] ++ values.pipx.additionalPackages;
in
{
  home.activation.pipxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "pipx" pipxPackages
  );
}
