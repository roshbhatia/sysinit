{
  config,
  lib,
  values,
  utils,
  pkgs,
  ...
}:

let

  packages = values.pipx.additionalPackages or [ ];
in
{
  home.activation.pipxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "pipx" packages config
  );
}
