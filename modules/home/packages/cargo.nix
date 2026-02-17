{
  config,
  lib,
  utils,
  ...
}:

let

  packages = config.sysinit.cargo.additionalPackages;
in
lib.mkIf (packages != [ ]) {
  home.activation.cargoPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "cargo" packages config
  );
}
