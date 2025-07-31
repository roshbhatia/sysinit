{
  lib,
  values,
  utils,
  ...
}:

let
  aiderPackages = [
    "aider-chat@latest"
  ];
in
{
  home.activation.aiderPackages = utils.sysinit.mkPackageManagerActivation "uv" aiderPackages;
}
