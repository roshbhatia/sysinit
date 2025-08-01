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
    "aider-chat@latest"
    "litellm"
    "litellm[proxy]"
  ]
  ++ (values.uvx.additionalPackages or [ ]);
in
{
  home.activation.uvxPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    utils.sysinit.mkPackageManagerScript config "uv" uvxPackages
  );
}
