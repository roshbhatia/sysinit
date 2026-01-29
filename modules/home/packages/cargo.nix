{
  config,
  lib,
  values,
  utils,
  ...
}:

let

  packages = values.cargo.additionalPackages or [ ];
in
lib.mkIf (packages != [ ]) {
  home.activation.cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "cargo" packages config
  );
}
