{
  config,
  lib,
  pkgs,
  values,
  utils,
  ...
}:

let
  cargoPackages = [
    "tree-sitter-cli"
  ]
  ++ (values.cargo.additionalPackages or [ ]);
in
{
  home.activation = {
    cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      utils.sysinit.mkPackageManagerScript config "cargo" cargoPackages
    );
  };
}
