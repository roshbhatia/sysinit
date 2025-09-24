{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  curlBashPackages = [
    "https://cursor.com/install"
  ]
  ++ values.curlBash.additionalPackages;
in
{
  home.activation = {
    curlBashPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.packages.mkPackageManagerScript config "curlBash" curlBashPackages
    );
  };
}
