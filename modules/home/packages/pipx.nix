{
  config,
  lib,
  utils,
  ...
}:

let

  packages = config.sysinit.pipx.additionalPackages;
in
{
  home.activation.pipxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "pipx" packages config
  );
}
