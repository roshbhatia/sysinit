{
  config,
  lib,
  values,
  utils,
  pkgs,
  ...
}:

let

  packages = [
    "hererocks"
    "https://github.com/github/spec-kit.git"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageActivationScript "uv" packages config
  );
}
