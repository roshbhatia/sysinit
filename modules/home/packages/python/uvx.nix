{
  config,
  lib,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "hererocks"
    "https://github.com/github/spec-kit.git"
    "vectorcode<1.0.0"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.packages.mkPackageManagerScript config "uv" uvxPackages
  );
}
