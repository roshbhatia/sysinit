{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  vetPackages = [
    "https://cursor.com/install"
    "https://opencode.ai/install"
    "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh XP_VERSION=v1.17.0"
  ]
  ++ values.vet.additionalPackages;
in
{
  home.activation = {
    vetPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.packages.mkPackageManagerScript config "vet" vetPackages
    );
  };
}
