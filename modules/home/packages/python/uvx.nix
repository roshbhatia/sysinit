{
  lib,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "hererocks"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = utils.sysinit.mkPackageManagerActivation "uv" uvxPackages;
}
