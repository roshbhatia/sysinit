{
  config,
  lib,
  utils,
  ...
}:

let

  packages = [
    "hererocks"
    "https://github.com/github/spec-kit.git"
  ]
  ++ config.sysinit.uvx.additionalPackages;
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "uv" packages config
  );
}
