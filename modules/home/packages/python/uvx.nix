{
  lib,
  values,
  utils,
  ...
}:

let
  uvxPackages = [
    "hererocks"
        "aider-chat@latest"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (utils.sysinit.mkPackageManagerScript "uv" uvxPackages);
}
