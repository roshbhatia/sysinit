{
  config,
  lib,
  values,
  utils,
  ...
}:

{
  imports = [
    ./pipx.nix
    ./uvx.nix
  ];
}
